const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

function changed(before, after, field = 'layoutNotifyAt') {
  const beforeStamp = before[field] ? JSON.stringify(before[field]) : '';
  const afterStamp = after[field] ? JSON.stringify(after[field]) : '';
  return afterStamp.length > 0 && beforeStamp !== afterStamp;
}

// Same wording as AppStrings.togetherWidgetChangedBodyFor / togetherFriendFallbackName.
const NOTICE_TEXT = {
  ko: { friend: '친구', together: '같이', body: (name) => `${name} - 위젯을 수정했어요!` },
  en: { friend: 'Friend', together: 'Together', body: (name) => `${name} updated the widget!` },
  ja: { friend: '友だち', together: '一緒', body: (name) => `${name}さんがウィジェットを更新しました！` },
};

function noticeText(locale) {
  return NOTICE_TEXT[locale] || NOTICE_TEXT.ko;
}

// One alert per sender per room per minute. Pressing Apply again within the
// minute still redraws friends' widgets, just without another alert.
const ALERT_GAP_MS = 60 * 1000;

/** True when [actor] may alert [roomId] now; records the time if so. */
async function claimAlert(db, roomId, actor) {
  if (!actor) return true;
  // Server-only collection: no client rule matches it, so apps cannot touch it.
  const ref = db.collection('notify_throttle').doc(`${roomId}_${actor}`);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const last = snap.data()?.lastAlertAt?.toMillis?.() || 0;
    const now = Date.now();
    if (now - last < ALERT_GAP_MS) return false;
    tx.set(ref, { lastAlertAt: new Date(now), roomId, actor });
    return true;
  });
}

exports.notifyRoomWidgetChange = onDocumentUpdated(
  'dday_memberships/{roomId}',
  async (event) => {
    const before = event.data.before.data() || {};
    const after = event.data.after.data() || {};
    const notify = changed(before, after);
    // A member changed their own character: redraw friends' widgets quietly.
    const refresh = changed(before, after, 'widgetRefreshAt');
    if (!notify && !refresh) return;

    const actor = after.updatedBy || after.layoutUpdatedBy || '';
    const recipients = [after.hostUid, ...(after.guestUids || [])].filter(
      (uid) => typeof uid === 'string' && uid.length > 0 && uid !== actor,
    );
    if (recipients.length === 0) return;

    const db = getFirestore();
    const roomId = event.params.roomId;
    // Over the per-minute limit: send the quiet redraw instead of an alert.
    const refreshOnly = !notify || !(await claimAlert(db, roomId, actor));
    let actorName = (after.layoutUpdatedByName || '').trim();
    if (!actorName && actor) {
      const actorDoc = await db.collection('profiles').doc(actor).get();
      actorName = (actorDoc.data()?.displayName || '').trim();
    }
    const roomDoc = await db.collection('ddays').doc(roomId).get();
    const roomTitle = (roomDoc.data()?.title || '').trim();
    const stamp =
      after.layoutNotifyAt && typeof after.layoutNotifyAt.toMillis === 'function'
        ? String(after.layoutNotifyAt.toMillis())
        : '';

    // Tokens per app language. Anyone who blocked the actor gets nothing:
    // their phone cannot filter an iPhone alert the server already wrote.
    const tokensByLocale = new Map();
    const ownerByToken = new Map();
    for (const uid of recipients) {
      const user = (await db.collection('users').doc(uid).get()).data() || {};
      const blocked = Array.isArray(user.blockedUids) ? user.blockedUids : [];
      if (actor && blocked.includes(actor)) continue;
      const locale = NOTICE_TEXT[user.locale] ? user.locale : 'ko';
      const map = user.fcmTokens || {};
      for (const token of Object.keys(map)) {
        if (!map[token]) continue;
        if (!tokensByLocale.has(locale)) tokensByLocale.set(locale, []);
        tokensByLocale.get(locale).push(token);
        ownerByToken.set(token, uid);
      }
    }
    if (tokensByLocale.size === 0) return;

    const invalid = [];
    for (const [locale, tokens] of tokensByLocale) {
      const text = noticeText(locale);
      const name = actorName || text.friend;
      const title = roomTitle || text.together;
      const body = text.body(name);
      const message = refreshOnly
        ? {
            tokens,
            data: { type: 'together_refresh', roomId, actorUid: actor },
            android: { priority: 'high' },
            // Silent background push: wakes the app to redraw, no alert.
            apns: {
              headers: { 'apns-push-type': 'background', 'apns-priority': '5' },
              payload: { aps: { 'content-available': 1 } },
            },
          }
        : {
            tokens,
            data: {
              type: 'together_widget',
              roomId,
              stamp,
              roomTitle,
              actorName,
              actorUid: actor,
              title,
              body,
            },
            android: {
              priority: 'high',
            },
            // iPhone: show the alert and wake the app in the background
            // (content-available) so it redraws the Together widget card.
            apns: {
              headers: {
                'apns-push-type': 'alert',
                'apns-priority': '10',
              },
              payload: {
                aps: {
                  alert: { title, body },
                  sound: 'default',
                  'content-available': 1,
                  'thread-id': roomId,
                },
              },
            },
          };
      const response = await getMessaging().sendEachForMulticast(message);
      response.responses.forEach((result, index) => {
        const code = result.error?.code || '';
        if (
          code.includes('registration-token-not-registered') ||
          code.includes('invalid-registration-token')
        ) {
          invalid.push(tokens[index]);
        }
      });
    }
    if (invalid.length === 0) return;

    const byOwner = new Map();
    for (const token of invalid) {
      const uid = ownerByToken.get(token);
      if (!uid) continue;
      if (!byOwner.has(uid)) byOwner.set(uid, []);
      byOwner.get(uid).push(token);
    }
    for (const [uid, tokens] of byOwner) {
      const ref = db.collection('users').doc(uid);
      const snap = await ref.get();
      const map = { ...(snap.data()?.fcmTokens || {}) };
      let dirty = false;
      for (const token of tokens) {
        if (map[token]) {
          delete map[token];
          dirty = true;
        }
      }
      if (dirty) await ref.set({ fcmTokens: map }, { merge: true });
    }
  },
);
