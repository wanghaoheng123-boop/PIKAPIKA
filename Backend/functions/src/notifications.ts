import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";

/// Runs once per hour. For each user whose last interaction is older than 24h,
/// push a "miss you" notification via FCM.
export const scheduleMissYouNudges = onSchedule(
  { schedule: "every 60 minutes", region: "us-central1" },
  async () => {
    const cutoff = Date.now() - 24 * 60 * 60 * 1000;
    const db = admin.firestore();
    const snap = await db.collectionGroup("pets")
      .where("lastInteractedAtMs", "<", cutoff)
      .limit(200)
      .get();

    const messaging = admin.messaging();

    for (const doc of snap.docs) {
      const data = doc.data() as { name?: string; ownerUid?: string; fcmToken?: string };
      if (!data.fcmToken || !data.name) continue;

      await messaging.send({
        token: data.fcmToken,
        notification: {
          title: `${data.name} misses you`,
          body: `It's been a while. Come say hi?`,
        },
      }).catch((e) => console.warn("FCM send failed", e));
    }
  }
);
