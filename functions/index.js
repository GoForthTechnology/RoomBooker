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
  await admin
    .firestore()
    .collection("mail")
    .add({
      to: to,
      message: {
        subject: subject,
        text: message,
      }
    })
}

exports.receivedNewBooking = functions.firestore
    .document("orgs/{orgID}/request-details/{bookingID}")
    .onCreate(async (snap, context) => {
      const details = snap.data();
      const bookingID = context.params.bookingID
      logger.log(`Received new booking request (${bookingID})`)

      try {
        await sendEmail(
          details.email,
          'Booking Request Received', `
          Dear ${details.name},

          Thank you for your request for ${details.eventName} has been received and we will be in touch shortly.

          Best,
          RoomBooker
          `)
        logger.info(`Sent email notification for ${bookingID}`)
      } catch (error) {
        logger.error(`Error sending email for ${bookingID}: ${error}`)
      }
      logger.log(`Function finished for ${bookingID}`);
    });
