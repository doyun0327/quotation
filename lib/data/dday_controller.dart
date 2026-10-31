import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Size;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quotation/data/dday_cloud_sync.dart';
import 'package:quotation/data/together_crowd_layout.dart';
import 'package:quotation/data/widget_album_background.dart';
import 'package:quotation/data/widget_fonts.dart';
import 'package:quotation/data/dday_friend_models.dart';
import 'package:quotation/widgets/dday_pixel_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DdayItem {
  const DdayItem({
    required this.id,
    required this.title,
    required this.targetDate,
    this.iconId = 'heart',
    this.repeatYearly = false,
    this.pinnedForWidget = false,
    this.favorite = false,
    this.friends = const [],
    this.cloudOwnerUid,
    this.latestCheer,
  });

  final String id;
  final String title;
  final DateTime targetDate;
  final String iconId;
  final bool repeatYearly;
  final bool pinnedForWidget;
  final bool favorite;

  /// Accepted friends for this room.
  /// Populated only from cloud membership — never from local picker.
  final List<DdayFriendMember> friends;

  /// Owner uid when this room came from / is synced with cloud.
  final String? cloudOwnerUid;

  /// Latest cheer text from the shared room (for list + home widget).
  final String? latestCheer;

  DdayIconKind get iconKind => DdayIconKind.byId(iconId);

  bool get hasFriend => friends.isNotEmpty;

  int get friendCount => friends.length;

  /// First friend character for the 2-slot home widget.
  String? get friendCharacterId =>
      friends.isEmpty ? null : friends.first.characterId;

  DateTime get effectiveDate {
    final base = DateTime(targetDate.year, targetDate.month, targetDate.day);
    if (!repeatYearly) return base;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var next = DateTime(today.year, base.month, base.day);
    if (next.isBefore(today)) {
      next = DateTime(today.year + 1, base.month, base.day);
    }
    return next;
  }

  int get daysLeft {
    final today = DateTime.now();
    final a = DateTime(today.year, today.month, today.day);
    return effectiveDate.difference(a).inDays;
  }

  String label({required bool korean}) {
    final d = daysLeft;
    if (d == 0) return 'D-Day';
    if (d > 0) return 'D-$d';
    return 'D+${-d}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'targetDate': targetDate.toIso8601String(),
        'iconId': iconId,
        'repeatYearly': repeatYearly,
        'pinnedForWidget': pinnedForWidget,
        'favorite': favorite,
        'friends': friends.map((e) => e.toJson()).toList(),
        if (cloudOwnerUid != null) 'cloudOwnerUid': cloudOwnerUid,
        if (latestCheer != null) 'latestCheer': latestCheer,
      };

  factory DdayItem.fromJson(Map<String, dynamic> json) {
    final friendsRaw = json['friends'] as List<dynamic>?;
    List<DdayFriendMember> friends = [];
    if (friendsRaw != null) {
      friends = friendsRaw
          .map((e) => DdayFriendMember.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((m) => m.uid.isNotEmpty)
          .toList();
    } else {
      // Migrate old single-friend local preview field → ignore (must re-invite).
      final legacy = json['friendCharacterId'] as String?;
      if (legacy != null && legacy.trim().isNotEmpty) {
        friends = const [];
      }
    }
    return DdayItem(
      id: json['id'] as String,
      title: json['title'] as String,
      targetDate: DateTime.parse(json['targetDate'] as String),
      iconId: json['iconId'] as String? ?? 'heart',
      repeatYearly: json['repeatYearly'] as bool? ?? false,
      pinnedForWidget: json['pinnedForWidget'] as bool? ?? false,
      favorite: json['favorite'] as bool? ?? false,
      friends: friends,
      cloudOwnerUid: json['cloudOwnerUid'] as String?,
      latestCheer: json['latestCheer'] as String?,
    );
  }

  DdayItem copyWith({
    String? id,
    String? title,
    DateTime? targetDate,
    String? iconId,
    bool? repeatYearly,
    bool? pinnedForWidget,
    bool? favorite,
    List<DdayFriendMember>? friends,
    bool clearFriends = false,
    String? cloudOwnerUid,
    bool clearCloudOwner = false,
    String? latestCheer,
    bool clearLatestCheer = false,
  }) {
    return DdayItem(
      id: id ?? this.id,
      title: title ?? this.title,
      targetDate: targetDate ?? this.targetDate,
      iconId: iconId ?? this.iconId,
      repeatYearly: repeatYearly ?? this.repeatYearly,
      pinnedForWidget: pinnedForWidget ?? this.pinnedForWidget,
      favorite: favorite ?? this.favorite,
      friends: clearFriends ? const [] : (friends ?? this.friends),
      cloudOwnerUid:
          clearCloudOwner ? null : (cloudOwnerUid ?? this.cloudOwnerUid),
      latestCheer:
          clearLatestCheer ? null : (latestCheer ?? this.latestCheer),
    );
  }
}

enum TogetherWidgetShape {
  circle('circle'),
  landscape('landscape'),
  square('square'),
  portrait('portrait');

  const TogetherWidgetShape(this.id);
  final String id;

  static TogetherWidgetShape byId(String? id) {
    // Shape picker removed — always rounded rectangle ("둥근 네모").
    return TogetherWidgetShape.square;
  }
}

/// Home-screen cell span. Default is 3×2 ([s32]).
enum TogetherWidgetSize {
  s32('s32', cellsW: 3, cellsH: 2),
  s42('s42', cellsW: 4, cellsH: 2),
  s33('s33', cellsW: 3, cellsH: 3),
  s43('s43', cellsW: 4, cellsH: 3);

  const TogetherWidgetSize(this.id, {required this.cellsW, required this.cellsH});
  final String id;
  final int cellsW;
  final int cellsH;

  /// Android App Widget min size: 70 × cells − 30.
  static double spanDp(int cells) => 70.0 * cells - 30.0;

  /// Shared Together card aspect (width / height) = iOS systemMedium.
  /// iPhone fills its widget exactly; Galaxy centers the card in the taller
  /// launcher cell and leaves the rest transparent.
  static const double cardAspect = 2.14;

  /// Largest [cardAspect] rect that fits inside [cell].
  static Size fitCardAspect(Size cell) {
    if (cell.width / cell.height > cardAspect) {
      return Size(cell.height * cardAspect, cell.height);
    }
    return Size(cell.width, cell.width / cardAspect);
  }

  /// Card size inside a One UI cell span on a 360dp-wide phone
  /// (measured 4×2 cell = 301×202 → card 301×141).
  Size homeSize(double screenWidthDp) {
    final screen = screenWidthDp.clamp(320.0, 480.0);
    return fitCardAspect(Size(
      screen * (80 * cellsW - 19) / 360.0,
      screen * (111 * cellsH - 20) / 360.0,
    ));
  }

  double get boxW => homeSize(360).width;
  double get boxH => homeSize(360).height;

  /// Character base scale vs 4×2.
  double get charFactor => (cellsW / 4.0).clamp(0.7, 1.2);

  /// One UI / Android 12 widget corner (dp) when host hasn't reported yet.
  static const double defaultCornerDp = 28;

  static TogetherWidgetSize byId(String? id) {
    switch (id) {
      case 's33':
      case 'sq':
      case 's22':
      case 's':
        return TogetherWidgetSize.s33;
      case 's43':
      case 'xl':
      case 's24':
        return TogetherWidgetSize.s43;
      case 's42':
      case 'l':
        return TogetherWidgetSize.s42;
      case 's32':
      case 'm':
      case 's23':
      case 'tall':
        return TogetherWidgetSize.s32;
      default:
        return TogetherWidgetSize.s42;
    }
  }
}

int _normDegrees(int value) {
  final n = value % 360;
  return n < 0 ? n + 360 : n;
}

class _RoomOffsets {
  const _RoomOffsets({
    this.meX = 0,
    this.meY = 0,
    this.friendX = DdayController.defaultFriendOffsetX,
    this.friendY = 0,
    this.textX = 0,
    this.textY = 0,
    this.textRotation = 0,
    this.charScale = 100,
    this.friendScale = 100,
    this.textScale = 100,
    this.bgColor = 0xFFFFF3E8,
    this.bgOpacity = 100,
    this.bgTheme = 'widget_background',
    this.textColor = 0xFFF26B8A,
    this.textFont = '',
    this.shape = 'square',
    this.widgetSize = 's42',
    this.crowdKey = '',
    this.crowd = const [],
  });

  final int meX;
  final int meY;
  final int friendX;
  final int friendY;
  final int textX;
  final int textY;
  /// Clockwise degrees, same step as a character tap.
  final int textRotation;
  final int charScale;
  final int friendScale;
  final int textScale;
  final int bgColor;
  final int bgOpacity;
  final String bgTheme;
  final int textColor;
  /// [WidgetFont.id]. Empty keeps the style default font.
  final String textFont;
  final String shape;
  final String widgetSize;
  final String crowdKey;
  final List<TogetherCrowdSaved> crowd;

  Map<String, dynamic> toJson() => {
        'meX': meX,
        'meY': meY,
        'friendX': friendX,
        'friendY': friendY,
        'textX': textX,
        'textY': textY,
        'textRotation': textRotation,
        'charScale': charScale,
        'friendScale': friendScale,
        'textScale': textScale,
        'bgColor': bgColor,
        'bgOpacity': bgOpacity,
        'bgTheme': bgTheme,
        'textColor': textColor,
        if (textFont.isNotEmpty) 'textFont': textFont,
        'shape': shape,
        'widgetSize': widgetSize,
        if (crowdKey.isNotEmpty) 'crowdKey': crowdKey,
        if (crowd.isNotEmpty)
          'crowd': [
            for (final slot in crowd)
              {
                'uid': slot.uid,
                'x': slot.x,
                'y': slot.y,
                'rotation': slot.rotation,
              },
          ],
      };

  factory _RoomOffsets.fromJson(Map<String, dynamic> json) {
    final meX = json['meX'] as int? ?? 0;
    final meY = json['meY'] as int? ?? 0;
    var friendX = json['friendX'] as int? ?? 0;
    final friendY = json['friendY'] as int? ?? 0;
    if (meX == 0 && meY == 0 && friendX == 0 && friendY == 0) {
      friendX = DdayController.defaultFriendOffsetX;
    }
    return _RoomOffsets(
      meX: meX,
      meY: meY,
      friendX: friendX,
      friendY: friendY,
      textX: json['textX'] as int? ?? 0,
      textY: json['textY'] as int? ?? 0,
      textRotation: _normDegrees(json['textRotation'] as int? ?? 0),
      charScale: json['charScale'] as int? ?? 100,
      friendScale: (json['friendScale'] as num?)?.toInt() ??
          json['charScale'] as int? ??
          100,
      textScale: json['textScale'] as int? ?? 100,
      bgColor: json['bgColor'] as int? ?? 0xFFFFF3E8,
      bgOpacity: json['bgOpacity'] as int? ?? 100,
      bgTheme: json['bgTheme'] as String? ?? 'widget_background',
      textColor: json['textColor'] as int? ?? 0xFFF26B8A,
      textFont: json['textFont'] as String? ?? '',
      shape: 'square',
      widgetSize: json['widgetSize'] as String? ?? 's42',
      crowdKey: json['crowdKey'] as String? ?? '',
      crowd: _crowdFromJson(json['crowd']),
    );
  }

  static List<TogetherCrowdSaved> _crowdFromJson(Object? raw) {
    if (raw is! List) return const [];
    final out = <TogetherCrowdSaved>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final uid = entry['uid']?.toString() ?? '';
      if (uid.isEmpty) continue;
      out.add((
        uid: uid,
        x: (entry['x'] as num?)?.toInt() ?? 0,
        y: (entry['y'] as num?)?.toInt() ?? 0,
        rotation: (entry['rotation'] as num?)?.toInt() ??
            (entry['r'] as num?)?.toInt() ??
            0,
      ));
    }
    return out;
  }

  _RoomOffsets copyWith({
    int? meX,
    int? meY,
    int? friendX,
    int? friendY,
    int? textX,
    int? textY,
    int? textRotation,
    int? charScale,
    int? friendScale,
    int? textScale,
    int? bgColor,
    int? bgOpacity,
    String? bgTheme,
    int? textColor,
    String? textFont,
    String? shape,
    String? widgetSize,
    String? crowdKey,
    List<TogetherCrowdSaved>? crowd,
  }) {
    return _RoomOffsets(
      meX: meX ?? this.meX,
      meY: meY ?? this.meY,
      friendX: friendX ?? this.friendX,
      friendY: friendY ?? this.friendY,
      textX: textX ?? this.textX,
      textY: textY ?? this.textY,
      textRotation: textRotation == null
          ? this.textRotation
          : _normDegrees(textRotation),
      charScale: charScale ?? this.charScale,
      friendScale: friendScale ?? this.friendScale,
      textScale: textScale ?? this.textScale,
      bgColor: bgColor ?? this.bgColor,
      bgOpacity: bgOpacity ?? this.bgOpacity,
      bgTheme: bgTheme ?? this.bgTheme,
      textColor: textColor ?? this.textColor,
      textFont: textFont ?? this.textFont,
      shape: shape ?? this.shape,
      widgetSize: widgetSize ?? this.widgetSize,
      crowdKey: crowdKey ?? this.crowdKey,
      crowd: crowd ?? this.crowd,
    );
  }
}

class DdayController extends ChangeNotifier {
  static const _prefsKey = 'dday_items_v1';
  static const _offsetsPrefsKey = 'dday_duo_offsets_v3';
  static const _legacyOffsetsPrefsKey = 'dday_duo_offsets_v2';
  /// First placement puts the friend beside me so the two sprites do not stack.
  static const defaultFriendOffsetX = 96;

  static const duoOffsetMinX = -480;
  static const duoOffsetMaxX = 480;
  /// Feet stay inside the widget. The editor tightens this to the live background.
  static const duoOffsetMinY = 0;
  static const duoOffsetMaxY = 480;
  static const textOffsetMinX = -480;
  static const textOffsetMaxX = 480;
  static const textOffsetMinY = -320;
  static const textOffsetMaxY = 320;
  static const scaleMin = 60;
  static const bgOpacityMin = 20;
  static const bgOpacityMax = 100;
  static const scaleMax = 240;

  final List<DdayItem> _items = [];
  final Map<String, _RoomOffsets> _roomOffsets = {};
  bool _loaded = false;

  int _duoMeOffsetX = 0;
  int _duoMeOffsetY = 0;
  int _duoFriendOffsetX = 0;
  int _duoFriendOffsetY = 0;

  List<DdayItem> get items {
    final sorted = [..._items];
    sorted.sort((a, b) {
      if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return List.unmodifiable(sorted);
  }

  bool get isLoaded => _loaded;

  int get duoMeOffsetX => _duoMeOffsetX;
  int get duoMeOffsetY => _duoMeOffsetY;
  int get duoFriendOffsetX => _duoFriendOffsetX;
  int get duoFriendOffsetY => _duoFriendOffsetY;

  /// Rooms with a cheer this phone just saved, until that same text comes back.
  /// A friend's cheer still replaces it.
  final Set<String> _localCheerIds = {};

  DdayItem? get widgetDday {
    final pinned = _items.where((e) => e.pinnedForWidget).toList();
    if (pinned.isNotEmpty) return pinned.first;
    if (_items.isEmpty) return null;
    final sorted = [..._items]..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    return sorted.first;
  }

  Future<void> load() async {
    await WidgetAlbumBackground.load();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    _items.clear();
    if (raw != null && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final entry in list) {
        _items.add(DdayItem.fromJson(Map<String, dynamic>.from(entry as Map)));
      }
    }
    await _loadRoomOffsets(prefs);
    _applyActiveOffsetsFromPinned();
    _loaded = true;
    notifyListeners();
  }

  Future<void> reloadOffsetsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final before =
        '$_duoMeOffsetX,$_duoMeOffsetY,$_duoFriendOffsetX,$_duoFriendOffsetY';
    await _loadRoomOffsets(prefs);
    _applyActiveOffsetsFromPinned();
    final after =
        '$_duoMeOffsetX,$_duoMeOffsetY,$_duoFriendOffsetX,$_duoFriendOffsetY';
    if (before != after) notifyListeners();
  }

  Future<void> _loadRoomOffsets(SharedPreferences prefs) async {
    _roomOffsets.clear();
    final raw = prefs.getString(_offsetsPrefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        final rooms = map['rooms'];
        if (rooms is Map) {
          for (final entry in rooms.entries) {
            _roomOffsets[entry.key.toString()] = _RoomOffsets.fromJson(
              Map<String, dynamic>.from(entry.value as Map),
            );
          }
          return;
        }
      } catch (_) {}
    }

    // Migrate legacy global offsets → pinned/first room.
    final legacy = prefs.getString(_legacyOffsetsPrefsKey);
    if (legacy == null || legacy.isEmpty) return;
    try {
      final map = Map<String, dynamic>.from(jsonDecode(legacy) as Map);
      final offsets = _RoomOffsets(
        meX: _clampX(map['meX'] as int? ?? 0),
        meY: _clampY(map['meY'] as int? ?? 0),
        friendX: _clampX(map['friendX'] as int? ?? 0),
        friendY: _clampY(map['friendY'] as int? ?? 0),
      );
      final targetId = widgetDday?.id;
      if (targetId != null) {
        _roomOffsets[targetId] = offsets;
        await _persistRoomOffsets();
      }
    } catch (_) {}
  }

  void _applyActiveOffsetsFromPinned() {
    final id = widgetDday?.id;
    final o = id == null ? const _RoomOffsets() : _offsetsForRoom(id);
    _duoMeOffsetX = o.meX;
    _duoMeOffsetY = o.meY;
    _duoFriendOffsetX = o.friendX;
    _duoFriendOffsetY = o.friendY;
  }

  _RoomOffsets _offsetsForRoom(String roomId) {
    final o = _roomOffsets[roomId];
    if (o == null) return const _RoomOffsets();
    return _RoomOffsets(
      meX: _clampX(o.meX),
      meY: _clampY(o.meY),
      friendX: _clampX(o.friendX),
      friendY: _clampY(o.friendY),
      textX: _clampTextX(o.textX),
      textY: _clampTextY(o.textY),
      textRotation: _normDegrees(o.textRotation),
      charScale: _clampScale(o.charScale),
      friendScale: _clampScale(o.friendScale),
      textScale: _clampScale(o.textScale),
      bgColor: o.bgColor,
      bgOpacity: _clampBgOpacity(o.bgOpacity),
      bgTheme: o.bgTheme,
      textColor: o.textColor,
      textFont: WidgetFont.byId(o.textFont).id,
      shape: TogetherWidgetShape.byId(o.shape).id,
      widgetSize: TogetherWidgetSize.byId(o.widgetSize).id,
      crowdKey: o.crowdKey,
      crowd: o.crowd,
    );
  }

  int meOffsetXForRoom(String roomId) => _offsetsForRoom(roomId).meX;
  int meOffsetYForRoom(String roomId) => _offsetsForRoom(roomId).meY;
  int friendOffsetXForRoom(String roomId) => _offsetsForRoom(roomId).friendX;
  int friendOffsetYForRoom(String roomId) => _offsetsForRoom(roomId).friendY;
  int textOffsetXForRoom(String roomId) => _offsetsForRoom(roomId).textX;
  int textOffsetYForRoom(String roomId) => _offsetsForRoom(roomId).textY;
  int textRotationForRoom(String roomId) => _offsetsForRoom(roomId).textRotation;
  int charScaleForRoom(String roomId) => _offsetsForRoom(roomId).charScale;
  int friendScaleForRoom(String roomId) => _offsetsForRoom(roomId).friendScale;
  int textScaleForRoom(String roomId) => _offsetsForRoom(roomId).textScale;
  int bgColorForRoom(String roomId) => _offsetsForRoom(roomId).bgColor;
  int bgOpacityForRoom(String roomId) => _offsetsForRoom(roomId).bgOpacity;
  String bgThemeForRoom(String roomId) => _offsetsForRoom(roomId).bgTheme;
  int textColorForRoom(String roomId) => _offsetsForRoom(roomId).textColor;
  WidgetFont textFontForRoom(String roomId) =>
      WidgetFont.byId(_offsetsForRoom(roomId).textFont);
  TogetherWidgetShape shapeForRoom(String roomId) =>
      TogetherWidgetShape.byId(_offsetsForRoom(roomId).shape);
  TogetherWidgetSize widgetSizeForRoom(String roomId) => TogetherWidgetSize.s42;
  String crowdKeyForRoom(String roomId) => _offsetsForRoom(roomId).crowdKey;
  List<TogetherCrowdSaved> crowdForRoom(String roomId) =>
      _offsetsForRoom(roomId).crowd;

  Future<void> _persistRoomOffsets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _offsetsPrefsKey,
      jsonEncode({
        'rooms': {
          for (final e in _roomOffsets.entries) e.key: e.value.toJson(),
        },
      }),
    );
  }

  Future<void> setDuoOffsets({
    String? roomId,
    int? meX,
    int? meY,
    int? friendX,
    int? friendY,
    int? textX,
    int? textY,
    int? textRotation,
    int? charScale,
    int? friendScale,
    int? textScale,
    int? bgColor,
    int? bgOpacity,
    String? bgTheme,
    int? textColor,
    WidgetFont? textFont,
    TogetherWidgetShape? shape,
    TogetherWidgetSize? widgetSize,
    bool fromCloud = false,
    bool notifyFriends = false,
    double? canvasW,
    double? canvasH,
    String? crowdKey,
    List<TogetherCrowdSaved>? crowd,
  }) async {
    final targetId = roomId ?? widgetDday?.id;
    if (targetId == null) return;

    final cur = _offsetsForRoom(targetId);
    final next = cur.copyWith(
      meX: meX == null ? null : _clampX(meX),
      meY: meY == null ? null : _clampY(meY),
      friendX: friendX == null ? null : _clampX(friendX),
      friendY: friendY == null ? null : _clampY(friendY),
      textX: textX == null ? null : _clampTextX(textX),
      textY: textY == null ? null : _clampTextY(textY),
      textRotation: textRotation == null ? null : _normDegrees(textRotation),
      charScale: charScale == null ? null : _clampScale(charScale),
      friendScale: friendScale == null ? null : _clampScale(friendScale),
      textScale: textScale == null ? null : _clampScale(textScale),
      bgColor: bgColor,
      bgOpacity: bgOpacity == null ? null : _clampBgOpacity(bgOpacity),
      bgTheme: bgTheme,
      textColor: textColor,
      textFont: textFont?.id,
      shape: shape?.id,
      widgetSize: widgetSize?.id,
      crowdKey: crowdKey,
      crowd: crowd,
    );
    final same = cur.meX == next.meX &&
        cur.meY == next.meY &&
        cur.friendX == next.friendX &&
        cur.friendY == next.friendY &&
        cur.textX == next.textX &&
        cur.textY == next.textY &&
        cur.textRotation == next.textRotation &&
        cur.charScale == next.charScale &&
        cur.friendScale == next.friendScale &&
        cur.textScale == next.textScale &&
        cur.bgColor == next.bgColor &&
        cur.bgOpacity == next.bgOpacity &&
        cur.bgTheme == next.bgTheme &&
        cur.textColor == next.textColor &&
        cur.textFont == next.textFont &&
        cur.shape == next.shape &&
        cur.widgetSize == next.widgetSize &&
        _sameCrowd(cur, next);
    if (same) {
      if (!fromCloud && notifyFriends) {
        await DdayCloudSync.pushSharedLayout(
          roomId: targetId,
          notifyFriends: true,
          canvasW: canvasW,
          canvasH: canvasH,
        );
      }
      return;
    }

    _roomOffsets[targetId] = next;
    if (widgetDday?.id == targetId) {
      _duoMeOffsetX = next.meX;
      _duoMeOffsetY = next.meY;
      _duoFriendOffsetX = next.friendX;
      _duoFriendOffsetY = next.friendY;
    }
    await _persistRoomOffsets();
    notifyListeners();
    // Share with the room only when the user applies the widget to home.
    if (!fromCloud && notifyFriends) {
      await DdayCloudSync.pushSharedLayout(
        roomId: targetId,
        notifyFriends: true,
        canvasW: canvasW,
        canvasH: canvasH,
      );
    }
  }

  bool _sameCrowd(_RoomOffsets a, _RoomOffsets b) {
    if (a.crowdKey != b.crowdKey || a.crowd.length != b.crowd.length) {
      return false;
    }
    for (var i = 0; i < a.crowd.length; i++) {
      final left = a.crowd[i];
      final right = b.crowd[i];
      if (left.uid != right.uid ||
          left.x != right.x ||
          left.y != right.y ||
          left.rotation != right.rotation) {
        return false;
      }
    }
    return true;
  }

  int _clampX(int value) => value.clamp(duoOffsetMinX, duoOffsetMaxX).toInt();
  int _clampY(int value) => value.clamp(duoOffsetMinY, duoOffsetMaxY).toInt();
  int _clampTextX(int value) =>
      value.clamp(textOffsetMinX, textOffsetMaxX).toInt();
  int _clampTextY(int value) =>
      value.clamp(textOffsetMinY, textOffsetMaxY).toInt();
  int _clampScale(int value) => value.clamp(scaleMin, scaleMax).toInt();
  int _clampBgOpacity(int value) =>
      value.clamp(bgOpacityMin, bgOpacityMax).toInt();

  Future<void> add({
    required String title,
    required DateTime targetDate,
    String iconId = 'heart',
    bool repeatYearly = false,
  }) async {
    final item = DdayItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim(),
      targetDate: DateTime(targetDate.year, targetDate.month, targetDate.day),
      iconId: iconId,
      repeatYearly: repeatYearly,
      pinnedForWidget: _items.isEmpty,
    );
    _items.add(item);
    await _persist();
    unawaited(DdayCloudSync.pushDday(item));
  }

  /// Points a local room at a new cloud id after the signed-in account
  /// can no longer write the previous membership.
  Future<void> rekeyRoom(
    String oldId,
    String newId, {
    required String cloudOwnerUid,
  }) async {
    final index = _items.indexWhere((e) => e.id == oldId);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(
      id: newId,
      cloudOwnerUid: cloudOwnerUid,
    );
    final offsets = _roomOffsets.remove(oldId);
    if (offsets != null) _roomOffsets[newId] = offsets;
    if (_localCheerIds.remove(oldId)) _localCheerIds.add(newId);
    await _persist();
    await _persistRoomOffsets();
    notifyListeners();
  }

  Future<void> update(DdayItem item) async {
    final index = _items.indexWhere((e) => e.id == item.id);
    if (index < 0) return;
    _items[index] = item;
    await _persist();
    unawaited(DdayCloudSync.pushDday(item));
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    if (_items.isNotEmpty && !_items.any((e) => e.pinnedForWidget)) {
      _items[0] = _items[0].copyWith(pinnedForWidget: true);
    }
    await _persist();
  }

  Future<void> toggleFavorite(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final item = _items[index];
    _items[index] = item.copyWith(favorite: !item.favorite);
    await _persist();
    notifyListeners();
  }

  Future<void> pinForWidget(String id) async {
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      _items[i] = item.copyWith(pinnedForWidget: item.id == id);
    }
    _applyActiveOffsetsFromPinned();
    await _persist();
  }

  /// Pin room for home widget and make its layout the active one.
  Future<void> applyRoomToHomeWidget(String roomId) async {
    await pinForWidget(roomId);
  }

  /// Keep the typed cheer on this device and on the home widget immediately.
  Future<void> setRoomCheer(String roomId, String text) async {
    final index = _items.indexWhere((e) => e.id == roomId);
    if (index < 0) return;
    final trimmed = text.trim();
    final next = trimmed.isEmpty ? null : trimmed;
    _localCheerIds.add(roomId);
    final cur = _items[index];
    final already = (cur.latestCheer ?? '') == (next ?? '');
    if (!already) {
      _items[index] = cur.copyWith(
        latestCheer: next,
        clearLatestCheer: next == null,
      );
      await _persist();
      notifyListeners();
    }
  }

  Future<void> upsertFromCloud(
    DdayItem item, {
    String? cheerAuthorUid,
  }) async {
    final index = _items.indexWhere((e) => e.id == item.id);
    if (index < 0) {
      _items.add(item);
    } else {
      final existing = _items[index];
      final cheer = _cheerFromCloud(
        roomId: item.id,
        current: existing.latestCheer,
        incoming: item.latestCheer,
        incomingAuthorUid: cheerAuthorUid,
      );
      _items[index] = item.copyWith(
        pinnedForWidget: existing.pinnedForWidget,
        favorite: existing.favorite,
        latestCheer: cheer,
        clearLatestCheer: cheer == null || cheer.isEmpty,
      );
    }
    await _persist();
  }

  Future<void> applyFriendsFromCloud({
    required String ddayId,
    required List<DdayFriendMember> friends,
    String? cloudOwnerUid,
    String? latestCheer,
    String? latestCheerAuthorUid,
  }) async {
    final index = _items.indexWhere((e) => e.id == ddayId);
    if (index < 0) return;
    final next = friends.toList();
    final cur = _items[index];
    final sameFriends = cur.friends.length == next.length &&
        List.generate(next.length, (i) {
          return cur.friends[i].uid == next[i].uid &&
              cur.friends[i].characterId == next[i].characterId &&
              (cur.friends[i].displayName ?? '') == (next[i].displayName ?? '');
        }).every((e) => e);
    final nextCheer = _cheerFromCloud(
      roomId: ddayId,
      current: cur.latestCheer,
      incoming: latestCheer,
      incomingAuthorUid: latestCheerAuthorUid,
    );
    final sameCheer = (cur.latestCheer ?? '') == (nextCheer ?? '');
    if (sameFriends &&
        cur.cloudOwnerUid == cloudOwnerUid &&
        sameCheer) {
      return;
    }
    _items[index] = cur.copyWith(
      friends: next,
      cloudOwnerUid: cloudOwnerUid,
      latestCheer: nextCheer,
      clearLatestCheer: nextCheer == null,
    );
    await _persist();
  }

  /// Room cheer is shared. Keep a local edit only when the cloud copy is still
  /// this phone's older text, so a friend's cheer replaces the widget.
  String? _cheerFromCloud({
    required String roomId,
    required String? current,
    String? incoming,
    String? incomingAuthorUid,
  }) {
    final remote = incoming?.trim();
    final next = (remote == null || remote.isEmpty) ? null : remote;
    if (!_localCheerIds.contains(roomId)) return next ?? current;
    final mine = FirebaseAuth.instance.currentUser?.uid ?? '';
    final fromMe = incomingAuthorUid != null &&
        incomingAuthorUid.isNotEmpty &&
        mine.isNotEmpty &&
        incomingAuthorUid == mine;
    if (next == null || (fromMe && next != (current ?? '').trim())) {
      return current;
    }
    _localCheerIds.remove(roomId);
    return next;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(_items.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
  }
}

final ddayController = DdayController();
