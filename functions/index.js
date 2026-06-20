/* eslint max-len: ["error", { "code": 200 }] */

/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const functions = require("firebase-functions/v1");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const {google} = require("googleapis");
const {SecretManagerServiceClient} = require("@google-cloud/secret-manager");
const {calculateOverlaps} = require("./overlap_calculator");

admin.initializeApp();
const db = admin.firestore();

exports.claimKioskGrant = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Caller must be signed in.");
  }

  const {code, deviceID} = data;
  if (!code) {
    throw new functions.https.HttpsError("invalid-argument", "code is required.");
  }

  const codeRef = db.collection("provisioning_codes").doc(code);
  const codeSnap = await codeRef.get();
  if (!codeSnap.exists) {
    throw new functions.https.HttpsError("not-found", "Invalid activation code.");
  }

  const handshake = codeSnap.data();
  const expiresAt = handshake.expiresAt.toDate ? handshake.expiresAt.toDate() : new Date(handshake.expiresAt);
  if (new Date() > expiresAt) {
    await codeRef.delete();
    throw new functions.https.HttpsError("deadline-exceeded", "Activation code expired.");
  }

  const {orgID, roomID, orgName, roomName} = handshake;
  await db.collection("orgs").doc(orgID)
      .collection("rooms").doc(roomID)
      .collection("kiosk-grants").doc(context.auth.uid)
      .set({
        deviceID: deviceID || null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

  await codeRef.delete();

  return {orgID, roomID, orgName, roomName};
});

exports.adminRevokeKioskGrant = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Caller must be signed in.");
  }

  const {orgID, roomID} = data;
  if (!orgID || !roomID) {
    throw new functions.https.HttpsError("invalid-argument", "orgID and roomID are required.");
  }

  const orgDoc = await db.collection("orgs").doc(orgID).get();
  if (!orgDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Org not found.");
  }
  const isOwner = orgDoc.data().ownerID === context.auth.uid;
  const adminDoc = await db.collection("orgs").doc(orgID)
      .collection("active-admins").doc(context.auth.uid).get();
  if (!isOwner && !adminDoc.exists) {
    throw new functions.https.HttpsError("permission-denied", "Must be an org admin.");
  }

  const grantsRef = db.collection("orgs").doc(orgID)
      .collection("rooms").doc(roomID)
      .collection("kiosk-grants");
  const grants = await grantsRef.get();
  const deletions = grants.docs.map((doc) => doc.ref.delete());
  await Promise.all(deletions);

  return {success: true};
});

exports.revokeKioskGrant = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Caller must be signed in.");
  }

  const {orgID, roomID} = data;
  if (!orgID || !roomID) {
    throw new functions.https.HttpsError("invalid-argument", "orgID and roomID are required.");
  }

  await db.collection("orgs").doc(orgID)
      .collection("rooms").doc(roomID)
      .collection("kiosk-grants").doc(context.auth.uid)
      .delete();

  return {success: true};
});

// --- Meet Provisioning ---

let _meetClient = null;

/**
 * Returns a cached, authenticated Google Meet API client using the
 * meet-provisioner service account key stored in Secret Manager.
 *
 * @return {Promise<object>} Authenticated Meet API v2 client.
 */
async function getMeetClient() {
  if (_meetClient) return _meetClient;

  const secretClient = new SecretManagerServiceClient();
  const projectId = process.env.GCLOUD_PROJECT || "roombooker-5e947";
  const secretName =
    `projects/${projectId}/secrets/meet-provisioner-key/versions/latest`;

  const [version] = await secretClient.accessSecretVersion({name: secretName});
  const keyJson = version.payload.data.toString("utf8");

  const auth = new google.auth.GoogleAuth({
    credentials: JSON.parse(keyJson),
    scopes: ["https://www.googleapis.com/auth/meetings.space.created"],
  });

  _meetClient = google.meet({version: "v2", auth});
  return _meetClient;
}

exports.onKioskBookingCreated = functions
    .runWith({timeoutSeconds: 15})
    .firestore.document("orgs/{orgID}/confirmed-requests/{bookingID}")
    .onCreate(async (snap, context) => {
      const data = snap.data();

      if (data.bookedVia !== "kiosk") return;

      const {orgID, bookingID} = context.params;
      const roomID = data.roomID;

      logger.log(`Kiosk booking ${bookingID} created — provisioning Meet space`);

      const detailsRef = db
          .collection("orgs").doc(orgID)
          .collection("request-details").doc(bookingID);

      // Idempotency: skip if URL already present
      const details = await detailsRef.get();
      if (details.exists && details.data().meetingUrl) {
        logger.log(`Booking ${bookingID} already has meetingUrl — skipping`);
        return;
      }

      try {
        const meet = await getMeetClient();
        const response = await meet.spaces.create({
          requestBody: {config: {accessType: "OPEN"}},
        });

        const meetingUri = response.data.meetingUri;
        await detailsRef.update({meetingUrl: meetingUri});
        logger.log(`Meet space provisioned for ${bookingID}: ${meetingUri}`);
      } catch (error) {
        logger.error(
            `Failed to provision Meet space for booking ${bookingID}:`,
            error,
        );

        // Signal the Kiosk with a transient error document
        const errorRef = db
            .collection("orgs").doc(orgID)
            .collection("rooms").doc(roomID)
            .collection("provisioning-errors").doc();

        await errorRef.set({
          bookingID,
          message: "Couldn't generate Meet link. Please try again.",
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Clean up the booking so the room returns to AVAILABLE
        await db
            .collection("orgs").doc(orgID)
            .collection("confirmed-requests").doc(bookingID)
            .delete();
        await detailsRef.delete();

        logger.log(`Cleaned up booking ${bookingID} after provisioning failure`);
      }
    });

exports.onNewPendingBooking = functions.firestore
    .document("orgs/{orgID}/pending-requests/{bookingID}")
    .onCreate(async (snap, context) => {
      const orgID = context.params.orgID;
      const bookingID = context.params.bookingID;
      logger.log(`Received new booking request (${bookingID})`);
      await notifyRequesterOfPeningBooking(orgID, bookingID, snap.data());
      await notifyOwnerOfPendingBooking(orgID, bookingID);
      logger.log(`Function finished for request ${bookingID}`);
    });

exports.onRequestApproved = functions.firestore
    .document("orgs/{orgID}/confirmed-requests/{bookingID}")
    .onCreate(async (snap, context) => {
      const orgID = context.params.orgID;
      const bookingID = context.params.bookingID;
      logger.log(`Received new request approval (${bookingID})`);
      await notifyRequesterOfBookingApproval(orgID, bookingID, snap.data());
      logger.log(`Function finished for approval of ${bookingID}`);
    });

exports.onRequestDenied = functions.firestore
    .document("orgs/{orgID}/denied-requests/{bookingID}")
    .onCreate(async (snap, context) => {
      const orgID = context.params.orgID;
      const bookingID = context.params.bookingID;
      logger.log(`Received new request denial (${bookingID})`);
      await notifyRequesterOfBookingDenial(orgID, bookingID, snap.data());
      logger.log(`Function finished for denial of ${bookingID}`);
    });

exports.onBookingUpdated = functions.firestore
    .document("orgs/{orgID}/confirmed-requests/{bookingID}")
    .onUpdate(async (change, context) => {
      const orgID = context.params.orgID;
      const bookingID = context.params.bookingID;
      const newValue = change.after.data(); // Data after the update
      const previousValue = change.before.data(); // Data before the update
      const details = await getRequestDetails(orgID, bookingID);
      if (isFromAdmin(details)) {
      // We don't want to spam the admins for actions they took themselves.
        return;
      }
      const updates = getUpdates(previousValue, newValue);
      if (updates.length > 0) {
        await sendEmail(
            details.email,
            "Booking Request Updated",
            `Your booking ${details.eventName} has been updated.

            ${updates.join("\n")}

            Please reach out to the office with any questions.

            God Bless,
            Church of the Resurrection Parish Office
            `);
      }
    });

exports.onBookingWrite = functions.firestore
    .document("orgs/{orgID}/confirmed-requests/{bookingID}")
    .onWrite(async (change, context) => {
      const orgID = context.params.orgID;
      const bookingID = context.params.bookingID;

      // If deleted, remove overlaps involving this booking
      if (!change.after.exists) {
        await removeOverlaps(orgID, bookingID);
        return;
      }

      const booking = change.after.data();
      booking.id = bookingID; // Ensure ID is present

      // Fetch all other confirmed bookings for the same room
      const snapshot = await db.collection("orgs").doc(orgID)
          .collection("confirmed-requests")
          .where("roomID", "==", booking.roomID)
          .get();

      const otherBookings = [];
      snapshot.forEach((doc) => {
        if (doc.id !== bookingID) {
          const data = doc.data();
          data.id = doc.id;
          otherBookings.push(data);
        }
      });

      const overlaps = calculateOverlaps(booking, bookingID, otherBookings);

      // Save overlaps
      // First, delete existing overlaps for this booking to avoid stale data
      await removeOverlaps(orgID, bookingID);

      const batch = db.batch();
      const overlapsRef = db.collection("orgs").doc(orgID).collection("overlaps");

      for (const overlap of overlaps) {
        const docRef = overlapsRef.doc();
        batch.set(docRef, overlap);

        const reverseOverlap = {
          bookingID1: overlap.bookingID2,
          bookingID2: overlap.bookingID1,
          startTime: overlap.startTime2,
          endTime: overlap.endTime2,
          startTime2: overlap.startTime,
          endTime2: overlap.endTime,
          roomID: overlap.roomID,
        };
        const reverseDocRef = overlapsRef.doc();
        batch.set(reverseDocRef, reverseOverlap);
      }

      await batch.commit();
    });

/**
 * Removes all overlaps involving the given booking ID.
 *
 * @param {string} orgID - The organization ID.
 * @param {string} bookingID - The booking ID to remove overlaps for.
 * @return {Promise<void>}
 */
async function removeOverlaps(orgID, bookingID) {
  const overlapsRef = db.collection("orgs").doc(orgID).collection("overlaps");
  const snapshot1 = await overlapsRef.where("bookingID1", "==", bookingID).get();
  const snapshot2 = await overlapsRef.where("bookingID2", "==", bookingID).get();

  const batch = db.batch();
  snapshot1.forEach((doc) => batch.delete(doc.ref));
  snapshot2.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
}

exports.onNewAdminRequest = functions.firestore
    .document("orgs/{orgID}/admin-requests/{requestID}")
    .onCreate(async (snap, context) => {
      const orgID = context.params.orgID;
      const requestID = context.params.requestID;
      const email = snap.data().email;
      const org = await getOrg(orgID);
      logger.log(`Got admin request from ${email} to join ${org.name} ${requestID}`);
      await sendEmail(
          email,
          "Admin Request Received",
          `Your request to join ${org.name} as an administrator has been received and will be reviewed shortly.`,
      );
      const targets = await getEmailTargets(orgID);
      const target = targets.adminRequestCreated;
      if (target != null && target != "") {
        await sendEmail(
            target,
            "Admin Request Received", `
            A new admin request is ready for review.
            `);
        logger.debug(`Sent email notification for ${requestID} to org owner ${target}`);
      }
      logger.log(`Function finished for admin request ${requestID}`);
    });

exports.onAdminRequestApproved = functions.firestore
    .document("orgs/{orgID}/active-admins/{requestID}")
    .onCreate(async (snap, context) => {
      const orgID = context.params.orgID;
      const requestID = context.params.requestID;
      const email = snap.data().email;
      const org = await getOrg(orgID);
      logger.log(`Got admin request approval for ${email} to join ${org.name} ${requestID}`);
      await sendEmail(
          email,
          "Admin Request Approved",
          `Your request to join ${org.name} as an administrator has been approved.`,
      );
      logger.log(`Function finished for admin request approval ${requestID}`);
    });

exports.onAdminRequestRevoked = functions.firestore
    .document("orgs/{orgID}/active-admins/{requestID}")
    .onDelete(async (snap, context) => {
      const orgID = context.params.orgID;
      const requestID = context.params.requestID;
      const email = snap.data().email;
      const org = await getOrg(orgID);
      logger.log(`Got admin removal for ${email} to leave ${org.name} ${requestID}`);
      await sendEmail(
          email,
          "Admin Access Revoked",
          `Your admin access for ${org.name} has been revoked.`,
      );
      logger.log(`Function finished for admin removal ${requestID}`);
    });

/**
 * Compares two versions of a booking request and generates a human-readable list of changes.
 * It checks for modifications in basic fields like start time, end time, and room name.
 * It also performs a deep comparison of the `recurranceOverrides` map to identify
 * added, removed, or modified single-event overrides and cancellations.
 *
 * @param {object} oldValue - The booking data object before the update.
 * @param {object} newValue - The booking data object after the update.
 * @return {string[]} An array of strings, with each string describing a specific change.
 *                    Returns an empty array if there are no differences.
 */
function getUpdates(oldValue, newValue) {
  const updates = [];
  if (oldValue.eventStartTime !== newValue.eventStartTime) {
    updates.push(`Event Start Time: ${oldValue.eventStartTime} -> ${newValue.eventStartTime}`);
  }
  if (oldValue.eventEndTime !== newValue.eventEndTime) {
    updates.push(`Event End Time: ${oldValue.eventEndTime} -> ${newValue.eventEndTime}`);
  }
  if (oldValue.roomName !== newValue.roomName) {
    updates.push(`Room Name: ${oldValue.roomName} -> ${newValue.roomName}`);
  }

  const oldOverrides = oldValue.recurranceOverrides || {};
  const newOverrides = newValue.recurranceOverrides || {};
  const allOverrideKeys = new Set([...Object.keys(oldOverrides), ...Object.keys(newOverrides)]);

  if (allOverrideKeys.size > 0) {
    const formatDate = (isoString) => new Date(isoString).toISOString().split("T")[0];

    for (const key of allOverrideKeys) {
      const oldEntry = oldOverrides[key];
      const newEntry = newOverrides[key];

      // Use stringify for a simple deep-compare. For Firestore objects, this is generally safe,
      // but a dedicated deep-equal function would be more robust against key-order changes.
      if (JSON.stringify(oldEntry) === JSON.stringify(newEntry)) {
        continue;
      }

      const dateStr = formatDate(key);

      if (oldEntry === undefined) { // An override or cancellation was added
        if (newEntry === null) {
          updates.push(`Cancelled occurrence on ${dateStr}`);
        } else {
          updates.push(`Added ocurrence on ${dateStr}:`);
          const details = [];
          if (newEntry.roomName) details.push(`  - Room Name: ${newEntry.roomName}`);
          if (newEntry.eventStartTime) details.push(`  - Event Start Time: ${newEntry.eventStartTime}`);
          if (newEntry.eventEndTime) details.push(`  - Event End Time: ${newEntry.eventEndTime}`);
          updates.push(...details);
        }
      } else if (newEntry === undefined) { // An override or cancellation was removed
        if (oldEntry === null) {
          updates.push(`Removed cancellation for ${dateStr}`);
        } else {
          updates.push(`Removed ocurrence on ${dateStr}`);
        }
      } else { // An override or cancellation was modified
        if (oldEntry === null) { // Was cancelled, now an override
          updates.push(`Updated occurrence on ${dateStr} (was cancelled):`);
          const details = [];
          if (newEntry.roomName) details.push(`  - Room Name: ${newEntry.roomName}`);
          if (newEntry.eventStartTime) details.push(`  - Event Start Time: ${newEntry.eventStartTime}`);
          if (newEntry.eventEndTime) details.push(`  - Event End Time: ${newEntry.eventEndTime}`);
          updates.push(...details);
        } else if (newEntry === null) { // Was an override, now cancelled
          updates.push(`Cancelled occurrence on ${dateStr} (was an override)`);
        } else { // Both are overrides, but different
          const overrideUpdates = getUpdates(oldEntry, newEntry);
          if (overrideUpdates.length > 0) {
            updates.push(`Updated ocurrence on ${dateStr}:`);
            overrideUpdates.forEach((u) => updates.push(`  - ${u}`));
          }
        }
      }
    }
  }
  return updates;
}

exports.getUpdates = getUpdates;


/**
 * Retrieves the organization data for a given organization ID.
 *
 * @param {string} orgID - The ID of the organization to retrieve.
 * @return {Promise<Object>} A promise that resolves to the organization data.
 */
async function getOrg(orgID) {
  const snap = await db.collection("orgs").doc(orgID).get();
  return snap.data();
}

/**
 * Sends an email by adding a document to the "mail" collection in the
 * database.
 *
 * @param {string} to - The recipient's email address.
 * @param {string} subject - The subject of the email.
 * @param {string} message - The body text of the email.
 * @return {Promise<void>} A promise that resolves when the email has been
 * added to the database.
 */
async function sendEmail(to, subject, message) {
  await db.collection("mail").add({
    to: to,
    message: {
      subject: subject,
      text: message,
    },
  });
  logger.debug(`Sent email to ${to}: ${message}`);
}

/**
 * Retrieves the email notification targets for a given organization.
 *
 * @param {string} orgID - The ID of the organization.
 * @return {Promise<Array<string>>} A promise that resolves to an array of email notification targets.
 */
async function getEmailTargets(orgID) {
  const snapshot = await db.collection("orgs").doc(orgID).get();
  const org = snapshot.data();
  return org.notificationSettings.notificationTargets;
}

/**
 * Checks if the provided details are from an admin.
 *
 * @param {Object} details - The details object to check.
 * @return {boolean} - Returns true if the name is "Org Admin", otherwise false.
 */
function isFromAdmin(details) {
  return details.name == "Org Admin";
}

/**
 * Fetches the request details for a given organization and booking ID.
 *
 * @param {string} orgID - The ID of the organization.
 * @param {string} bookingID - The ID of the booking.
 * @return {Promise<Object>} A promise that resolves to the request details data.
 * @throws Will throw an error if there is an issue fetching the details.
 */
async function getRequestDetails(orgID, bookingID) {
  try {
    const snapshot = await db
        .collection("orgs")
        .doc(orgID)
        .collection("request-details")
        .doc(bookingID)
        .get();
    return snapshot.data();
  } catch (error) {
    logger.error("Error fetching details for booking: " + bookingID);
    throw error;
  }
}

/**
 * Returns a string representation of a booking.
 *
 * @param {string} eventName
 * @param {object} data
 * @return {string}
 */
function bookingInfo(eventName, data) {
  return `
  Event: ${eventName}
  Room: ${data.roomName}
  Start Time: ${data.eventStartTime}
  End Time: ${data.eventEndTime}`;
}

exports.bookingInfo = bookingInfo;


/**
 * Sends an email notification to the org owner when a new request is received.
 *
 * @param {string} orgID - The ID of the organization.
 * @param {string} bookingID - The ID of the booking request.
 * @return {Promise<void>} - A promise that resolves when the email has been sent.
 */
async function notifyOwnerOfPendingBooking(orgID, bookingID) {
  try {
    const targets = await getEmailTargets(orgID);
    const target = targets.bookingCreated;
    if (target != null && target != "") {
      await sendEmail(
          target,
          "Booking Request Received", `
          A new booking request is ready for review at https://rooms.goforthtech.org/#/review/${orgID}
          `);
      logger.debug(`Sent email notification for ${bookingID} to org owner ${target}`);
    }
  } catch (error) {
    logger.error("Error reading target for orgID: " + orgID);
  }
}

/**
 * Sends an email notification to the requester when their booking request is received.
 *
 * @param {string} orgID - The ID of the organization.
 * @param {string} bookingID - The ID of the booking request.
 * @param {object} data - The booking document
 * @return {Promise<void>} - A promise that resolves when the email has been sent.
 */
async function notifyRequesterOfPeningBooking(orgID, bookingID, data) {
  try {
    const details = await getRequestDetails(orgID, bookingID);
    if (isFromAdmin(details)) {
      // We don't want to spam the admins for actions they took themselves.
      return;
    }
    await sendEmail(
        details.email,
        "Booking Request Received", `
        Dear ${details.name},

        Your request has been received and we will be in touch shortly.

        ${bookingInfo(details.eventName, data)}

        God Bless,
        Church of the Resurrection Parish Office
        `);
    logger.debug(`Sent email notification for ${bookingID} to requester ${details.email}`);
  } catch (error) {
    logger.error(`Error sending email for ${bookingID}: ${error}`);
  }
}

/**
 * Sends an email notification to the requester when their booking request is approved.
 *
 * @param {string} orgID - The ID of the organization.
 * @param {string} bookingID - The ID of the booking request.
 * @param {object} data - The booking document
 * @return {Promise<void>} - A promise that resolves when the email has been sent.
 */
async function notifyRequesterOfBookingApproval(orgID, bookingID, data) {
  try {
    const details = await getRequestDetails(orgID, bookingID);
    if (isFromAdmin(details)) {
      // We don't want to spam the admins for actions they took themselves.
      return;
    }
    await sendEmail(
        details.email,
        "Booking Request Approved", `
        Dear ${details.name},

        Your room booking request for has been Approved!

        ${bookingInfo(details.eventName, data)}

        God Bless,
        Church of the Resurrection Parish Office
        `);
    logger.debug(`Sent email notification for ${bookingID} to requester ${details.email}`);
  } catch (error) {
    logger.error(`Error sending email for ${bookingID}: ${error}`);
  }
}

/**
 * Sends an email notification to the requester when their booking request is denied.
 *
 * @param {string} orgID - The ID of the organization.
 * @param {string} bookingID - The ID of the booking request.
 * @param {object} data - The booking document
 * @return {Promise<void>} - A promise that resolves when the email has been sent.
 */
async function notifyRequesterOfBookingDenial(orgID, bookingID, data) {
  try {
    const details = await getRequestDetails(orgID, bookingID);
    if (isFromAdmin(details)) {
      // We don't want to spam the admins for actions they took themselves.
      return;
    }
    await sendEmail(
        details.email,
        "Booking Request Denied", `
        Dear ${details.name},

        Unfortunately your room booking request has been denied.

        ${bookingInfo(details.eventName, data)}

        God Bless,
        Church of the Resurrection Parish Office
        `);
    logger.debug(`Sent email notification for ${bookingID} to requester ${details.email}`);
  } catch (error) {
    logger.error(`Error sending email for ${bookingID}: ${error}`);
  }
}
