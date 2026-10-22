const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

function changed(before, after) {
  const beforeStamp = before.layoutNotifyAt ? JSON.stringify(before.layoutNotifyAt) : '';
  const afterStamp = after.layoutNotifyAt ? JSON.stringify(after.layoutNotifyAt) : '';
  return afterStamp.length > 0 && beforeStamp !== afterStamp;
}

exports.notifyRoomWidgetChange = onDocumentUpdated(
  'dday_memberships/{roomId}',
  async (event) => {
    const before = event.data.before.data() || {};
    const after = event.data.after.data() || {};
    if (!changed(before, after)) return;

    const actor = after.updatedBy || after.layoutUpdatedBy || '';
    const recipients = [after.hostUid, ...(after.guestUids || [])].filter(
      (uid) => typeof uid === 'string' && uid.length > 0 && uid !== actor,
    );
    if (recipients.length === 0) return;

    const db = getFirestore();
    const roomId = event.params.roomId;
    let actorName = (after.layoutUpdatedByName || '').trim();
    if (!actorName && actor) {
      const actorDoc = await db.collection('users').doc(actor).get();
      actorName = (actorDoc.data()?.displayName || '').trim();
    }
    const roomDoc = await db.collection('ddays').doc(roomId).get();
    const roomTitle = (roomDoc.data()?.title || '').trim();
    const stamp =
      after.layoutNotifyAt && typeof after.layoutNotifyAt.toMillis === 'function'
        ? String(after.layoutNotifyAt.toMillis())
        : '';
    const tokens = [];
    for (const uid of recipients) {
      const user = await db.collection('users').doc(uid).get();
      const map = user.data()?.fcmTokens || {};
      for (const token of Object.keys(map)) {
        if (map[token]) tokens.push(token);
      }
    }
    if (tokens.length === 0) return;

    const response = await getMessaging().sendEachForMulticast({
      tokens,
      data: {
        type: 'together_widget',
        roomId,
        stamp,
        roomTitle,
        actorName,
        title: roomTitle || '같이',
        body: `${actorName || '친구'} - 위젯을 수정했어요!`,
      },
      android: {
        priority: 'high',
      },
    });

    const invalid = [];
    response.responses.forEach((result, index) => {
      const code = result.error?.code || '';
      if (
        code.includes('registration-token-not-registered') ||
        code.includes('invalid-registration-token')
      ) {
        invalid.push(tokens[index]);
      }
    });
    if (invalid.length === 0) return;

    for (const uid of recipients) {
      const ref = db.collection('users').doc(uid);
      const snap = await ref.get();
      const map = { ...(snap.data()?.fcmTokens || {}) };
      let dirty = false;
      for (const token of invalid) {
        if (map[token]) {
          delete map[token];
          dirty = true;
        }
      }
      if (dirty) await ref.set({ fcmTokens: map }, { merge: true });
    }
  },
);
