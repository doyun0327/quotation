import 'dart:math' as math;

import 'package:quotation/data/dday_friend_models.dart';

typedef TogetherCrowdSaved = ({String uid, int x, int y});

/// One person in a shared room, in stable draw order.
class TogetherCrowdPerson {
  const TogetherCrowdPerson({required this.uid, required this.characterId});

  final String uid;
  final String characterId;
}

/// A character placed on the together widget canvas.
class TogetherPlaced {
  const TogetherPlaced({
    required this.uid,
    required this.characterId,
    required this.x,
    required this.y,
    required this.scale,
  });

  final String uid;
  final String characterId;

  /// Same offsets as the widget preview: left = 4 + x, bottom = y.
  final double x;
  final double y;

  /// 1 draws the sprite at 72×96.
  final double scale;

  TogetherPlaced copyWith({double? x, double? y}) {
    return TogetherPlaced(
      uid: uid,
      characterId: characterId,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale,
    );
  }
}

/// Rows characters so they do not overlap.
/// Five or fewer people sit on one row. Six or more use two rows.
abstract final class TogetherCrowdLayout {
  static const baseW = 72.0;
  static const baseH = 96.0;
  static const gap = 8.0;
  static const rowGap = 6.0;

  static String keyFor(List<TogetherCrowdPerson> people) =>
      people.map((p) => p.uid).join('|');

  /// Host first, then everyone else by uid, so every phone draws the same order.
  static List<TogetherCrowdPerson> roster({
    required String myUid,
    required String myCharacterId,
    required String? hostUid,
    required List<DdayFriendMember> friends,
  }) {
    final people = <TogetherCrowdPerson>[
      TogetherCrowdPerson(
        uid: myUid,
        characterId: myCharacterId.isEmpty ? 'basic' : myCharacterId,
      ),
    ];
    for (final friend in friends) {
      if (friend.uid.isEmpty || friend.uid == myUid) continue;
      people.add(
        TogetherCrowdPerson(uid: friend.uid, characterId: friend.characterId),
      );
    }
    final host = hostUid?.trim() ?? '';
    people.sort((a, b) {
      if (host.isNotEmpty) {
        if (a.uid == host && b.uid != host) return -1;
        if (b.uid == host && a.uid != host) return 1;
      }
      return a.uid.compareTo(b.uid);
    });
    return people;
  }

  static List<TogetherPlaced> resolve({
    required List<TogetherCrowdPerson> people,
    required double canvasW,
    required double canvasH,
    double charFactor = 1,
    required List<TogetherCrowdSaved> saved,
  }) {
    if (people.isEmpty || canvasW < 40 || canvasH < 40) return const [];
    final byUid = {for (final slot in saved) slot.uid: slot};
    final known = [
      for (final person in people)
        if (byUid.containsKey(person.uid)) person,
    ];
    // Nothing placed yet: lay the whole group out once.
    if (known.isEmpty) {
      return place(
        people: people,
        canvasW: canvasW,
        canvasH: canvasH,
        charFactor: charFactor,
      );
    }
    final knownPlan = place(
      people: known,
      canvasW: canvasW,
      canvasH: canvasH,
      charFactor: charFactor,
    );
    final scale = knownPlan.first.scale;
    final kept = <TogetherPlaced>[
      for (final person in known)
        TogetherPlaced(
          uid: person.uid,
          characterId: person.characterId,
          x: byUid[person.uid]!.x.toDouble(),
          y: byUid[person.uid]!.y.toDouble(),
          scale: scale,
        ),
    ];
    final newcomers = [
      for (final person in people)
        if (!byUid.containsKey(person.uid)) person,
    ];
    if (newcomers.isEmpty) return kept;
    final placed = [...kept];
    for (final person in newcomers) {
      final spot = _openSpot(
        existing: placed,
        canvasW: canvasW,
        canvasH: canvasH,
        charFactor: charFactor,
        scale: scale,
      );
      placed.add(
        TogetherPlaced(
          uid: person.uid,
          characterId: person.characterId,
          x: spot.x,
          y: spot.y,
          scale: scale,
        ),
      );
    }
    return placed;
  }

  /// A free spot for someone who just joined. Existing sprites stay put.
  static ({double x, double y}) _openSpot({
    required List<TogetherPlaced> existing,
    required double canvasW,
    required double canvasH,
    required double charFactor,
    required double scale,
  }) {
    final factor = charFactor.clamp(0.7, 1.2);
    final spriteW = baseW * factor * scale;
    final spriteH = baseH * factor * scale;
    final maxX = canvasW - 4 - spriteW;
    final hiX = maxX < -4 ? -4.0 : maxX;
    final maxY = canvasH - spriteH;
    final hiY = maxY < 0 ? 0.0 : maxY;
    final stepX = math.max(12.0, spriteW + gap);
    final stepY = math.max(12.0, spriteH + rowGap);
    for (var y = 0.0; y <= hiY + 0.1; y += stepY) {
      for (var x = -4.0; x <= hiX + 0.1; x += stepX) {
        final cx = x.clamp(-4.0, hiX).toDouble();
        final cy = y.clamp(0.0, hiY).toDouble();
        if (!_hits(cx, cy, spriteW, spriteH, existing)) {
          return (x: cx, y: cy);
        }
      }
    }
    final n = existing.length;
    return (
      x: (-4 + n * 16).clamp(-4.0, hiX).toDouble(),
      y: (n * 12).clamp(0.0, hiY).toDouble(),
    );
  }

  static bool _hits(
    double x,
    double y,
    double spriteW,
    double spriteH,
    List<TogetherPlaced> existing,
  ) {
    final left = 4 + x;
    final bottom = y;
    final right = left + spriteW;
    final top = bottom + spriteH;
    const pad = 4.0;
    for (final other in existing) {
      final otherLeft = 4 + other.x;
      final otherBottom = other.y;
      final otherRight = otherLeft + spriteW;
      final otherTop = otherBottom + spriteH;
      final separated = right + pad <= otherLeft ||
          otherRight + pad <= left ||
          top + pad <= otherBottom ||
          otherTop + pad <= bottom;
      if (!separated) return true;
    }
    return false;
  }

  /// Shrinks with the size slider, and does not grow past the row that fits.
  static double userFactor(int scalePercent) =>
      (scalePercent / 100).clamp(0.6, 1.0);

  static List<TogetherPlaced> withUserScale({
    required List<TogetherPlaced> placed,
    required String myUid,
    required int meScale,
    required int friendScale,
  }) {
    final me = userFactor(meScale);
    final friend = userFactor(friendScale);
    return [
      for (final slot in placed)
        TogetherPlaced(
          uid: slot.uid,
          characterId: slot.characterId,
          x: slot.x,
          y: slot.y,
          scale: slot.scale * (slot.uid == myUid ? me : friend),
        ),
    ];
  }

  static List<Map<String, Object>> widgetChars(List<TogetherPlaced> placed) {
    return [
      for (final slot in placed)
        {
          'id': slot.characterId,
          'x': slot.x.round(),
          'y': slot.y.round(),
          's': (slot.scale * 100).round().clamp(28, 120),
        },
    ];
  }

  static List<TogetherPlaced> place({
    required List<TogetherCrowdPerson> people,
    required double canvasW,
    required double canvasH,
    double charFactor = 1,
  }) {
    final count = people.length;
    if (count == 0 || canvasW < 40 || canvasH < 40) return const [];
    final rows = count <= 5 ? 1 : 2;
    final bottomCount = rows == 1 ? count : (count + 1) ~/ 2;
    final topCount = count - bottomCount;
    final maxRow = math.max(bottomCount, topCount);
    final factor = charFactor.clamp(0.7, 1.2);
    final fullW = baseW * factor;
    final fullH = baseH * factor;
    final availW = math.max(40.0, canvasW - 8);
    final naturalW = maxRow * fullW + (maxRow - 1) * gap;
    final scaleW = availW / naturalW;
    final double scaleH;
    if (rows == 1) {
      scaleH = 1;
    } else {
      final availH = math.max(48.0, canvasH * 0.70 - rowGap);
      scaleH = availH / (2 * fullH);
    }
    final scale = math.min(1.0, math.min(scaleW, scaleH)).clamp(0.28, 1.0);
    final spriteW = fullW * scale;
    final spriteH = fullH * scale;

    double xFor(int column, int rowCount) {
      final rowW = rowCount * spriteW + (rowCount - 1) * gap;
      final left = (canvasW - rowW) / 2 + column * (spriteW + gap);
      final maxX = canvasW - 4 - spriteW;
      final hiX = maxX < -4 ? -4.0 : maxX;
      return (left - 4).clamp(-4.0, hiX).toDouble();
    }

    return [
      for (var i = 0; i < count; i++)
        TogetherPlaced(
          uid: people[i].uid,
          characterId: people[i].characterId,
          x: i < bottomCount
              ? xFor(i, bottomCount)
              : xFor(i - bottomCount, topCount),
          y: i < bottomCount ? 0 : spriteH + rowGap,
          scale: scale,
        ),
    ];
  }
}
