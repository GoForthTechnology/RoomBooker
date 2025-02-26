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

admin.initializeApp();
const db = admin.firestore();

exports.onNewPendingBooking = functions.firestore
    .document("orgs/{orgID}/pending-requests/{bookingID}")
    .onCreate(async (snap, context) => {
      const orgID = context.params.orgID;
      const bookingID = context.params.bookingID;
      logger.log(`Received new booking request (${bookingID})`);
      await notifyRequesterOfPeningBooking(orgID, bookingID);
      await notifyOwnerOfPendingBooking(orgID, bookingID);
      logger.log(`Function finished for request ${bookingID}`);
    });

exports.onRequestApproved = functions.firestore
    .document("orgs/{orgID}/confirmed-requests/{bookingID}")
    .onCreate(async (snap, context) => {
      const orgID = context.params.orgID;
      const bookingID = context.params.bookingID;
      logger.log(`Received new request approval (${bookingID})`);
      await notifyRequesterOfBookingApproval(orgID, bookingID);
      logger.log(`Function finished for approval of ${bookingID}`);
    });

exports.onRequestDenied = functions.firestore
    .document("orgs/{orgID}/denied-requests/{bookingID}")
    .onCreate(async (snap, context) => {
      const orgID = context.params.orgID;
      const bookingID = context.params.bookingID;
      logger.log(`Received new request denial (${bookingID})`);
      await notifyRequesterOfBookingDenial(orgID, bookingID);
      logger.log(`Function finished for denial of ${bookingID}`);
    });

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
          A new booking request is ready for review.
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
 * @return {Promise<void>} - A promise that resolves when the email has been sent.
 */
async function notifyRequesterOfPeningBooking(orgID, bookingID) {
  try {
    const details = await getRequestDetails(orgID, bookingID);
    await sendEmail(
        details.email,
        "Booking Request Received", `
        Dear ${details.name},

        Thank you for your request for ${details.eventName} has been received and we will be in touch shortly.

        Best,
        RoomBooker
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
 * @return {Promise<void>} - A promise that resolves when the email has been sent.
 */
async function notifyRequesterOfBookingApproval(orgID, bookingID) {
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

        Your room booking request for ${details.eventName} has been Approved!

        Best,
        RoomBooker
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
 * @return {Promise<void>} - A promise that resolves when the email has been sent.
 */
async function notifyRequesterOfBookingDenial(orgID, bookingID) {
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

        Unfortunately rour room booking request for ${details.eventName} has been denied.

        Best,
        RoomBooker
        `);
    logger.debug(`Sent email notification for ${bookingID} to requester ${details.email}`);
  } catch (error) {
    logger.error(`Error sending email for ${bookingID}: ${error}`);
  }
}
