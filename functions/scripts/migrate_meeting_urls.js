/**
 * One-time migration: move `meetingUrl` off of the publicly-readable
 * `confirmed-requests` documents and onto the room-scoped
 * `request-details` (PrivateRequestDetails) documents.
 *
 * Part of Phase 4a (privacy-guard-meeting-url): this MUST be run against a
 * project's Firestore once, before/around the deploy of the app version
 * that stops writing `Request.meetingUrl`.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \
 *     node functions/scripts/migrate_meeting_urls.js [projectId]
 *
 * If `projectId` is omitted, the default project from the credentials /
 * application-default config is used. Safe to re-run: documents without a
 * `meetingUrl` are skipped.
 */

const admin = require("firebase-admin");

const projectId = process.argv[2];
admin.initializeApp(projectId ? {projectId} : {});
const db = admin.firestore();

async function migrateOrg(orgRef) {
  const confirmedRequests = await orgRef.collection("confirmed-requests").get();

  let migrated = 0;
  let skipped = 0;
  for (const doc of confirmedRequests.docs) {
    const meetingUrl = doc.data().meetingUrl;
    if (!meetingUrl) {
      continue;
    }

    const detailsRef = orgRef.collection("request-details").doc(doc.id);
    const detailsSnapshot = await detailsRef.get();
    if (!detailsSnapshot.exists) {
      // PrivateRequestDetails requires name/email/phone/eventName; writing
      // meetingUrl alone here would create a doc that fails to deserialize.
      // Flag for manual investigation instead.
      console.warn(
          `  Skipping ${orgRef.id}/confirmed-requests/${doc.id}: ` +
          "has meetingUrl but no request-details doc exists",
      );
      skipped++;
      continue;
    }

    await db.runTransaction(async (t) => {
      t.set(detailsRef, {meetingUrl}, {merge: true});
      t.update(doc.ref, {meetingUrl: admin.firestore.FieldValue.delete()});
    });
    migrated++;
    console.log(`  Migrated meetingUrl for ${orgRef.id}/confirmed-requests/${doc.id}`);
  }
  return {migrated, skipped};
}

async function main() {
  const orgs = await db.collection("orgs").get();
  let totalMigrated = 0;
  let totalSkipped = 0;
  for (const orgDoc of orgs.docs) {
    console.log(`Scanning org ${orgDoc.id}...`);
    const {migrated, skipped} = await migrateOrg(orgDoc.ref);
    totalMigrated += migrated;
    totalSkipped += skipped;
  }
  console.log(
      `Done. Migrated ${totalMigrated} confirmed-requests document(s), ` +
      `skipped ${totalSkipped}.`,
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
