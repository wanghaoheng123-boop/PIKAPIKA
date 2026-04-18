import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import Anthropic from "@anthropic-ai/sdk";
import OpenAI from "openai";
import { z } from "zod";

const ANTHROPIC_KEY = defineSecret("ANTHROPIC_API_KEY");
const OPENAI_KEY = defineSecret("OPENAI_API_KEY");

const AiChatRequestSchema = z.object({
  provider: z.enum(["anthropic", "openai"]).default("anthropic"),
  model: z.string().optional(),
  systemPrompt: z.string().min(1).max(8000),
  messages: z.array(z.object({
    role: z.enum(["user", "assistant", "system"]),
    content: z.string().min(1).max(8000),
  })).min(1).max(50),
  temperature: z.number().min(0).max(2).default(0.8),
});

const DEFAULT_MODELS = {
  anthropic: "claude-sonnet-4-6",
  openai: "gpt-4o-mini",
} as const;

// Simple per-UID daily quota. Tighten before production.
const DAILY_QUOTA = 200;

export const aiChat = onCall(
  { secrets: [ANTHROPIC_KEY, OPENAI_KEY], cors: true },
  async (req) => {
    if (!req.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const parsed = AiChatRequestSchema.safeParse(req.data);
    if (!parsed.success) {
      throw new HttpsError("invalid-argument", parsed.error.message);
    }
    const data = parsed.data;

    await enforceQuota(req.auth.uid);

    if (data.provider === "anthropic") {
      const client = new Anthropic({ apiKey: ANTHROPIC_KEY.value() });
      const resp = await client.messages.create({
        model: data.model ?? DEFAULT_MODELS.anthropic,
        max_tokens: 512,
        temperature: data.temperature,
        // Plain string: current `@anthropic-ai/sdk` typings omit `cache_control` on text blocks.
        system: data.systemPrompt,
        messages: data.messages
          .filter((m) => m.role !== "system")
          .map((m) => ({ role: m.role as "user" | "assistant", content: m.content })),
      });
      const text = resp.content
        .map((b) => (b.type === "text" ? b.text : ""))
        .join("");
      return { reply: text };
    }

    const client = new OpenAI({ apiKey: OPENAI_KEY.value() });
    const resp = await client.chat.completions.create({
      model: data.model ?? DEFAULT_MODELS.openai,
      temperature: data.temperature,
      messages: [{ role: "system", content: data.systemPrompt }, ...data.messages],
    });
    return { reply: resp.choices[0]?.message?.content ?? "" };
  }
);

async function enforceQuota(uid: string): Promise<void> {
  const db = admin.firestore();
  const today = new Date().toISOString().slice(0, 10);
  const ref = db.collection("rateLimits").doc(`${uid}_${today}`);
  const delta = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const current = (snap.exists ? (snap.data()?.count ?? 0) : 0) as number;
    if (current >= DAILY_QUOTA) return -1;
    tx.set(ref, { count: current + 1, updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    return current + 1;
  });
  if (delta < 0) {
    throw new HttpsError("resource-exhausted", "Daily AI quota reached. Try again tomorrow.");
  }
}
