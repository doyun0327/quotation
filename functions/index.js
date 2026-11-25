const {
  onDocumentCreated,
  onDocumentDeleted,
  onDocumentUpdated,
} = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldPath, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

/**
 * Push tokens of one user. An up-to-date app writes its single current token
 * under `fcmDevices.{deviceId}` (the id survives a reinstall) and clears the
 * old `fcmTokens` map, which kept every token a phone ever had: an iPhone
 * often keeps its APNs token across reinstalls, so old tokens stayed valid
 * and one phone got the same alert several times. Older app versions still
 * write `fcmTokens`, so both are read; each token is sent once.
 */
function tokensOf(user) {
  const tokens = new Set();
  for (const t of Object.values(user.fcmDevices || {})) {
    if (typeof t === 'string' && t.length > 0) tokens.add(t);
  }
  const legacy = user.fcmTokens || {};
  for (const t of Object.keys(legacy)) {
    if (legacy[t]) tokens.add(t);
  }
  return [...tokens];
}

/**
 * Removes dead tokens. `set(..., {merge: true})` with a smaller map never
 * removed a key (merge keeps fields it is not given), so dead tokens used to
 * pile up; delete each field explicitly instead.
 */
async function pruneTokens(db, byOwner) {
  for (const [uid, tokens] of byOwner) {
    const ref = db.collection('users').doc(uid);
    const data = (await ref.get()).data() || {};
    const args = [];
    const legacy = data.fcmTokens || {};
    for (const token of tokens) {
      if (token in legacy) args.push(new FieldPath('fcmTokens', token), FieldValue.delete());
    }
    for (const [device, token] of Object.entries(data.fcmDevices || {})) {
      if (tokens.includes(token)) args.push(new FieldPath('fcmDevices', device), FieldValue.delete());
    }
    if (args.length === 0) continue;
    try {
      await ref.update(...args);
    } catch (e) {
      console.warn('prune tokens failed', { uid, message: e.message || '' });
    }
  }
}

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

    // One card per room: the one this edit replaced goes (also in a room
    // with nobody else to notify).
    const oldCard = typeof before.widgetCardId === 'string' ? before.widgetCardId : '';
    if (oldCard && oldCard !== after.widgetCardId) {
      try {
        await getFirestore().collection('widget_cards').doc(oldCard).delete();
      } catch (e) {
        console.warn('old widget card delete failed', {
          roomId: event.params.roomId,
          message: e.message || '',
        });
      }
    }

    const actor = after.updatedBy || after.layoutUpdatedBy || '';
    const recipients = [after.hostUid, ...(after.guestUids || [])].filter(
      (uid) => typeof uid === 'string' && uid.length > 0 && uid !== actor,
    );
    if (recipients.length === 0) {
      console.log('together push skipped: no recipients', {
        roomId: event.params.roomId,
        actor,
      });
      return;
    }

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
    // The editor's app saved the new widget picture (widget_cards/{id}) with
    // this edit. iPhones fetch it in the notification service extension and
    // redraw the widget without waking the app.
    const cardFresh = changed(before, after, 'widgetCardAt');
    const cardId = cardFresh && typeof after.widgetCardId === 'string'
      ? after.widgetCardId
      : '';
    const cardAt = cardFresh && typeof after.widgetCardAt?.toMillis === 'function'
      ? String(after.widgetCardAt.toMillis())
      : '';
    const cardData = cardId ? { cardId, cardAt } : {};

    // Tokens per app language. Anyone who blocked the actor gets nothing:
    // their phone cannot filter an iPhone alert the server already wrote.
    const tokensByLocale = new Map();
    const ownerByToken = new Map();
    // Per recipient: how many tokens, or why none (for iPhone debugging).
    const perRecipient = {};
    for (const uid of recipients) {
      const user = (await db.collection('users').doc(uid).get()).data() || {};
      const blocked = Array.isArray(user.blockedUids) ? user.blockedUids : [];
      if (actor && blocked.includes(actor)) {
        perRecipient[uid] = 'blocked';
        continue;
      }
      const locale = NOTICE_TEXT[user.locale] ? user.locale : 'ko';
      const userTokens = tokensOf(user);
      perRecipient[uid] = userTokens.length;
      for (const token of userTokens) {
        if (!tokensByLocale.has(locale)) tokensByLocale.set(locale, []);
        tokensByLocale.get(locale).push(token);
        ownerByToken.set(token, uid);
      }
    }
    console.log('together push', {
      roomId,
      actor,
      kind: refreshOnly ? (notify ? 'quiet-edit' : 'refresh') : 'alert',
      tokensByRecipient: perRecipient,
    });
    if (tokensByLocale.size === 0) return;

    const invalid = [];
    for (const [locale, tokens] of tokensByLocale) {
      const text = noticeText(locale);
      const name = actorName || text.friend;
      const title = roomTitle || text.together;
      const body = text.body(name);
      // A widget edit inside the one-alert-per-minute window: no second
      // banner, but the widget must still change. iPhone often drops or
      // delays a background push (priority 5), so send a passive alert
      // instead: no sound, no banner, it replaces the room's earlier notice
      // (same collapse id), and content-available wakes the app to redraw.
      const quietEdit = refreshOnly && notify;
      const message = refreshOnly
        ? {
            tokens,
            data: { type: 'together_refresh', roomId, actorUid: actor, ...cardData },
            android: { priority: 'high' },
            apns: quietEdit
              ? {
                  headers: {
                    'apns-push-type': 'alert',
                    'apns-priority': '10',
                    'apns-collapse-id': roomId.slice(0, 64),
                  },
                  payload: {
                    aps: {
                      alert: { title, body },
                      'content-available': 1,
                      'mutable-content': 1,
                      'thread-id': roomId,
                      'interruption-level': 'passive',
                    },
                  },
                }
              : {
                  // A friend changed their character: silent redraw.
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
              ...cardData,
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
                // Later quiet edits of this room replace this notice.
                'apns-collapse-id': roomId.slice(0, 64),
              },
              payload: {
                aps: {
                  alert: { title, body },
                  sound: 'default',
                  'content-available': 1,
                  'mutable-content': 1,
                  'thread-id': roomId,
                },
              },
            },
          };
      const response = await getMessaging().sendEachForMulticast(message);
      console.log('together push sent', {
        roomId,
        locale,
        ok: response.successCount,
        failed: response.failureCount,
      });
      response.responses.forEach((result, index) => {
        const code = result.error?.code || '';
        // Failed sends used to vanish. An iPhone-only failure is almost
        // always APNs setup: `messaging/third-party-auth-error` means the
        // APNs key is missing or wrong in Firebase › Cloud Messaging.
        if (result.error) {
          console.warn('together push failed', {
            roomId,
            kind: refreshOnly ? 'refresh' : 'alert',
            owner: ownerByToken.get(tokens[index]) || '',
            code,
            message: result.error.message || '',
          });
        }
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
    await pruneTokens(db, byOwner);
  },
);

// ---------------------------------------------------------------------------
// "{nickname} - 방에 들어왔어요!" to everyone already in the room when someone
// joins with an invite code. Same wording as AppStrings.togetherJoinedBodyFor.

const JOIN_TEXT = {
  ko: { friend: '친구', together: '같이', body: (name) => `${name} - 방에 들어왔어요!` },
  en: { friend: 'Friend', together: 'Together', body: (name) => `${name} joined the room!` },
  ja: { friend: '友だち', together: '一緒', body: (name) => `${name}さんが入室しました！` },
};

// A real join is written by the joiner (updatedBy) with a fresh joinedAt.
// An account move (anonymous → Google) swaps uids without either.
const JOIN_FRESH_MS = 10 * 60 * 1000;

function uidList(data) {
  return (Array.isArray(data.guestUids) ? data.guestUids : []).filter(
    (uid) => typeof uid === 'string' && uid.length > 0,
  );
}

function joinedUid(before, after) {
  const joiner = after.updatedBy || '';
  if (!joiner || joiner === after.hostUid) return '';
  if (!uidList(after).includes(joiner)) return '';
  if (uidList(before).includes(joiner) || before.hostUid === joiner) return '';
  const member = (Array.isArray(after.members) ? after.members : []).find(
    (m) => m && m.uid === joiner,
  );
  const joinedAt = member?.joinedAt?.toMillis?.() || 0;
  if (!joinedAt || Date.now() - joinedAt > JOIN_FRESH_MS) return '';
  return joiner;
}

async function notifyJoin(roomId, after, joiner) {
  const recipients = [
    ...new Set([after.hostUid, ...uidList(after)].filter(
      (uid) => typeof uid === 'string' && uid.length > 0 && uid !== joiner,
    )),
  ];
  if (recipients.length === 0) return;

  const db = getFirestore();
  const member = (after.members || []).find((m) => m && m.uid === joiner) || {};
  let joinerName = (member.displayName || '').trim();
  if (!joinerName) {
    const profile = await db.collection('profiles').doc(joiner).get();
    joinerName = (profile.data()?.displayName || '').trim();
  }
  const roomDoc = await db.collection('ddays').doc(roomId).get();
  const roomTitle = (roomDoc.data()?.title || '').trim();
  const stamp = `join_${joiner}_${member.joinedAt?.toMillis?.() || Date.now()}`;

  const tokensByLocale = new Map();
  const ownerByToken = new Map();
  for (const uid of recipients) {
    const user = (await db.collection('users').doc(uid).get()).data() || {};
    const blocked = Array.isArray(user.blockedUids) ? user.blockedUids : [];
    if (blocked.includes(joiner)) continue;
    const locale = JOIN_TEXT[user.locale] ? user.locale : 'ko';
    for (const token of tokensOf(user)) {
      if (!tokensByLocale.has(locale)) tokensByLocale.set(locale, []);
      tokensByLocale.get(locale).push(token);
      ownerByToken.set(token, uid);
    }
  }

  const invalid = [];
  for (const [locale, tokens] of tokensByLocale) {
    const text = JOIN_TEXT[locale];
    const name = joinerName || text.friend;
    const title = roomTitle || text.together;
    const body = text.body(name);
    const response = await getMessaging().sendEachForMulticast({
      tokens,
      // Android: the app shows the notice (and redraws the widget with the
      // new character). iPhone: APNs shows it and wakes the app to redraw.
      data: {
        type: 'together_join',
        roomId,
        stamp,
        roomTitle,
        actorName: joinerName,
        actorUid: joiner,
        title,
        body,
      },
      android: { priority: 'high' },
      apns: {
        headers: { 'apns-push-type': 'alert', 'apns-priority': '10' },
        payload: {
          aps: {
            alert: { title, body },
            sound: 'default',
            'content-available': 1,
            'thread-id': roomId,
          },
        },
      },
    });
    response.responses.forEach((result, index) => {
      const code = result.error?.code || '';
      if (result.error) {
        console.warn('together join push failed', {
          roomId,
          owner: ownerByToken.get(tokens[index]) || '',
          code,
          message: result.error.message || '',
        });
      }
      if (
        code.includes('registration-token-not-registered') ||
        code.includes('invalid-registration-token')
      ) {
        invalid.push(tokens[index]);
      }
    });
  }

  const byOwner = new Map();
  for (const token of invalid) {
    const uid = ownerByToken.get(token);
    if (!uid) continue;
    if (!byOwner.has(uid)) byOwner.set(uid, []);
    byOwner.get(uid).push(token);
  }
  await pruneTokens(db, byOwner);
}

exports.notifyRoomJoin = onDocumentUpdated(
  'dday_memberships/{roomId}',
  async (event) => {
    const before = event.data.before.data() || {};
    const after = event.data.after.data() || {};
    const joiner = joinedUid(before, after);
    if (!joiner) return;
    await notifyJoin(event.params.roomId, after, joiner);
  },
);

// The first friend can create the room's membership doc (no host copy yet).
exports.notifyRoomJoinCreated = onDocumentCreated(
  'dday_memberships/{roomId}',
  async (event) => {
    const after = event.data?.data() || {};
    const joiner = joinedUid({}, after);
    if (!joiner) return;
    await notifyJoin(event.params.roomId, after, joiner);
  },
);

// The room went away (its last person left, or the host deleted their
// account): what is left of it on the server goes too, so a room's title,
// date and codes do not stay behind. Each part on its own, so one failure
// does not keep the others.
exports.removeRoomWidgetCard = onDocumentDeleted(
  'dday_memberships/{roomId}',
  async (event) => {
    const roomId = event.params.roomId;
    if (roomId === 'together-test-room') return;
    const db = getFirestore();
    const removed = {};
    async function part(name, work) {
      try {
        removed[name] = await work();
      } catch (e) {
        console.warn('room cleanup failed', { roomId, part: name, message: e.message || '' });
      }
    }
    // The room's widget picture (iPhone notices).
    await part('widgetCard', async () => {
      const cardId = event.data?.data()?.widgetCardId;
      if (typeof cardId !== 'string' || !cardId) return 0;
      await db.collection('widget_cards').doc(cardId).delete();
      return 1;
    });
    // Title and date.
    await part('dday', async () => {
      await db.collection('ddays').doc(roomId).delete();
      return 1;
    });
    // Invite codes: nobody can join a room that is gone.
    await part('invites', async () => {
      const snap = await db.collection('dday_invites').where('ddayId', '==', roomId).get();
      await Promise.all(snap.docs.map((doc) => doc.ref.delete()));
      return snap.size;
    });
    // One-alert-per-minute records ({roomId}_{actor}).
    await part('throttle', async () => {
      const snap = await db.collection('notify_throttle').where('roomId', '==', roomId).get();
      await Promise.all(snap.docs.map((doc) => doc.ref.delete()));
      return snap.size;
    });
    console.log('room cleanup', { roomId, removed });
  },
);
