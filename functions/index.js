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

exports.receivedNewBooking = functions.firestore
    .document("orgs/{orgID}/request-details/{bookingID}")
    .onCreate((snap, context) => {
      const details = snap.data();
      logger.log(`Got new booking for ${context.params.orgID}, name: ${details.eventName}`);

      var message = `
      Dear ${details.name},

      Thank you for your request for ${details.eventName} has been received and we will be in touch shortly.

      Best,
      RoomBooker
      `
      logger.log(`Sending notification to ${details.email}: ${message}`);
    });
