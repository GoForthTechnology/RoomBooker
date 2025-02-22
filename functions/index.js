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
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

async function sendEmail(to, subject, message) {
  await db.collection("mail").add({
    to: to,
    message: {
      subject: subject,
      text: message,
    }
  })
}

async function getEmailTargets(orgID) {
  var snapshot = await db.collection("orgs").doc(orgID).get()
  var org = snapshot.data()
  return org.notificationSettings?.notificationTargets
}

async function getRequestDetails(orgID, bookingID) {
  try {
    var snapshot = await db
      .collection("orgs")
      .doc(orgID)
      .collection("request-details")
      .doc(bookingID)
      .get()
    return snapshot.data()
  } catch (error) {
    logger.error("Error fetching details for booking: " + bookingID)
    throw error
  }
}

async function notifyOwnerOfPendingBooking(orgID, bookingID) {
  try {
    var targets = await getEmailTargets(orgID)
    var target = targets?.bookingCreated ?? ""
    if (target != "") {
      await sendEmail(
        target,
        'Booking Request Received', `
        A new booking request is ready for review.
        `
      )
      logger.debug(`Sent email notification for ${bookingID} to org owner ${target}`)
    }
  } catch (error) {
    logger.error("Error reading target for orgID: " + orgID)
  }
}

async function notifyRequesterOfPeningBooking(orgID, bookingID) {
  try {
    const details =  await getRequestDetails(orgID, bookingID)
    await sendEmail(
      details.email,
      'Booking Request Received', `
      Dear ${details.name},

      Thank you for your request for ${details.eventName} has been received and we will be in touch shortly.

      Best,
      RoomBooker
      `)
    logger.debug(`Sent email notification for ${bookingID} to requester ${details.email}`)
  } catch (error) {
    logger.error(`Error sending email for ${bookingID}: ${error}`)
  }
}

async function notifyRequesterOfBookingApproval(orgID, bookingID) {
  try {
    const details =  await getRequestDetails(orgID, bookingID)
    await sendEmail(
      details.email,
      'Booking Request Approved', `
      Dear ${details.name},

      Your room booking request for ${details.eventName} has been Approved!

      Best,
      RoomBooker
      `)
    logger.debug(`Sent email notification for ${bookingID} to requester ${details.email}`)
  } catch (error) {
    logger.error(`Error sending email for ${bookingID}: ${error}`)
  }
}

async function notifyRequesterOfBookingDenial(orgID, bookingID) {
  try {
    const details =  await getRequestDetails(orgID, bookingID)
    await sendEmail(
      details.email,
      'Booking Request Denied', `
      Dear ${details.name},

      Unfortunately rour room booking request for ${details.eventName} has been denied.

      Best,
      RoomBooker
      `)
    logger.debug(`Sent email notification for ${bookingID} to requester ${details.email}`)
  } catch (error) {
    logger.error(`Error sending email for ${bookingID}: ${error}`)
  }
}

exports.onNewPendingBooking = functions.firestore
    .document("orgs/{orgID}/pending-requests/{bookingID}")
    .onCreate(async (snap, context) => {
      const orgID = context.params.orgID
      const bookingID = context.params.bookingID
      logger.log(`Received new booking request (${bookingID})`)
      await notifyRequesterOfPeningBooking(orgID, bookingID)
      await notifyOwnerOfPendingBooking(orgID, bookingID)
      logger.log(`Function finished for request ${bookingID}`);
    });

exports.onRequestApproved = functions.firestore
    .document("orgs/{orgID}/confirmed-requests/{bookingID}")
    .onCreate(async (snap, context) => {
      const orgID = context.params.orgID
      const bookingID = context.params.bookingID
      logger.log(`Received new request approval (${bookingID})`)
      await notifyRequesterOfBookingApproval(orgID, bookingID)
      logger.log(`Function finished for approval of ${bookingID}`);
    });

exports.onRequestDenied = functions.firestore
    .document("orgs/{orgID}/denied-requests/{bookingID}")
    .onCreate(async (snap, context) => {
      const orgID = context.params.orgID
      const bookingID = context.params.bookingID
      logger.log(`Received new request denial (${bookingID})`)
      await notifyRequesterOfBookingDenial(orgID, bookingID)
      logger.log(`Function finished for denial of ${bookingID}`);
    });