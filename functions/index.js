/**
 * matiapu プッシュ通知送信用 Cloud Functions
 *
 * Firestore の変更をトリガーに FCM でリモートプッシュを送信する。
 * ペイロードのキーは iOS 側 PushNotificationUserInfoKey と一致させること。
 */

import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { onDocumentCreated, onDocumentWritten } from "firebase-functions/v2/firestore";
import { setGlobalOptions } from "firebase-functions/v2";
import { logger } from "firebase-functions";

initializeApp();
setGlobalOptions({ region: "asia-northeast1" });

const db = getFirestore();
const messaging = getMessaging();

const ANNOUNCEMENTS_TOPIC = "announcements";

// iOS 側 PushNotificationUserInfoKey と対応
const PayloadKey = {
  kind: "notification_kind",
  relatedID: "notification_related_id",
  notificationID: "notification_id",
};

/** ユーザーの表示名を解決（iOS 側 FirestoreUserPublicProfileMapper と同じ優先順） */
function displayName(userData) {
  const candidates = [
    userData?.nickname,
    userData?.storeName,
    [userData?.lastName, userData?.firstName]
      .map((value) => (value ?? "").trim())
      .filter((value) => value.length > 0)
      .join(" "),
  ];
  for (const candidate of candidates) {
    const trimmed = (candidate ?? "").trim();
    if (trimmed.length > 0) return trimmed;
  }
  return "ユーザー";
}

async function fetchUser(uid) {
  const snapshot = await db.collection("users").doc(uid).get();
  return snapshot.exists ? snapshot.data() : null;
}

/**
 * 指定ユーザーの全デバイストークンへ送信し、無効なトークンは削除する
 */
async function sendToUser(uid, { title, body, kind, relatedID, notificationID }) {
  const userData = await fetchUser(uid);
  const tokens = userData?.fcmTokens ?? [];
  if (tokens.length === 0) {
    logger.info(`FCMトークン未登録のためスキップ: ${uid}`);
    return;
  }

  const message = {
    notification: { title, body },
    data: {
      [PayloadKey.kind]: kind,
      [PayloadKey.relatedID]: relatedID ?? "",
      [PayloadKey.notificationID]: notificationID,
    },
    apns: {
      payload: {
        aps: { sound: "default" },
      },
    },
  };

  const response = await messaging.sendEachForMulticast({ ...message, tokens });

  const invalidTokens = [];
  response.responses.forEach((result, index) => {
    if (result.success) return;
    const code = result.error?.code ?? "";
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
    ) {
      invalidTokens.push(tokens[index]);
    } else {
      logger.warn(`送信失敗 (${uid}): ${code}`);
    }
  });

  if (invalidTokens.length > 0) {
    await db
      .collection("users")
      .doc(uid)
      .update({ fcmTokens: FieldValue.arrayRemove(...invalidTokens) });
    logger.info(`無効トークンを削除: ${uid} (${invalidTokens.length}件)`);
  }
}

/** チャットルームID（iOS 側 ChatCrypto.chatRoomID と同一ロジック） */
function chatRoomID(uid1, uid2) {
  return [uid1, uid2].sort().join("_");
}

/**
 * マッチ成立通知
 * matches/{matchID} の status が matched に変化したら両者に送信
 */
export const notifyMatch = onDocumentWritten("matches/{matchID}", async (event) => {
  const after = event.data?.after?.data();
  if (!after || after.status !== "matched") return;

  const before = event.data?.before?.data();
  if (before?.status === "matched") return; // 既にマッチ済み（再書き込み）

  const userUID = after.user_uid;
  const politicianUID = after.politician_uid;
  if (!userUID || !politicianUID) return;

  const roomID = chatRoomID(userUID, politicianUID);
  const [userData, politicianData] = await Promise.all([
    fetchUser(userUID),
    fetchUser(politicianUID),
  ]);

  const send = (recipientUID, partnerData) =>
    sendToUser(recipientUID, {
      title: "マッチしました！",
      body: `${displayName(partnerData)}さんとマッチしました。チャットを始めましょう。`,
      kind: "match",
      relatedID: roomID,
      notificationID: `match-${event.params.matchID}`,
    });

  await Promise.all([send(userUID, politicianData), send(politicianUID, userData)]);
});

/**
 * チャットメッセージ通知
 * メッセージ本文はクライアント側で暗号化されているため、本文は定型文で送る
 */
export const notifyMessage = onDocumentCreated(
  "chat_rooms/{roomID}/messages/{messageID}",
  async (event) => {
    const message = event.data?.data();
    if (!message || message.is_system === true) return;

    const senderID = message.sender_id;
    const recipientID = message.recipient_id;
    if (!senderID || !recipientID || recipientID === "system") return;

    const senderData = await fetchUser(senderID);

    await sendToUser(recipientID, {
      title: displayName(senderData),
      body: "新しいメッセージが届きました",
      kind: "message",
      relatedID: event.params.roomID,
      notificationID: `message-${event.params.roomID}-${event.params.messageID}`,
    });
  }
);

/**
 * 運営お知らせ通知
 * 全ユーザーが購読する announcements トピックへ配信
 */
export const notifyAnnouncement = onDocumentCreated("announcements/{announcementID}", async (event) => {
  const announcement = event.data?.data();
  const title = (announcement?.title ?? "").trim();
  const body = (announcement?.body ?? "").trim();
  if (!title || !body) return;

  await messaging.send({
    topic: ANNOUNCEMENTS_TOPIC,
    notification: { title, body },
    data: {
      [PayloadKey.kind]: "announcement",
      [PayloadKey.relatedID]: event.params.announcementID,
      [PayloadKey.notificationID]: `announcement-${event.params.announcementID}`,
    },
    apns: {
      payload: {
        aps: { sound: "default" },
      },
    },
  });
});
