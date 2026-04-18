import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import { z } from "zod";

const PublishRequest = z.object({
  petId: z.string().uuid(),
  name: z.string().min(1).max(32),
  species: z.string().min(1).max(32),
  traits: z.array(z.string().max(32)).max(8),
  spritePath: z.string().max(512),
});

export const publishPet = onCall({ cors: true }, async (req) => {
  if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Sign in required.");
  const parsed = PublishRequest.safeParse(req.data);
  if (!parsed.success) throw new HttpsError("invalid-argument", parsed.error.message);

  const doc = {
    ...parsed.data,
    authorUid: req.auth.uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    likes: 0,
  };
  await admin.firestore().collection("gallery").doc(parsed.data.petId).set(doc);
  return { ok: true };
});

export const listenForNewGalleryPets = onDocumentCreated("gallery/{petId}", async (event) => {
  const data = event.data?.data();
  if (!data) return;
  // Future: fan out a "trending" feed, image moderation, etc.
  console.log(`New pet published: ${data.name} by ${data.authorUid}`);
});
