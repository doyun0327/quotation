import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:quotation/data/dday_cloud_sync.dart';
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
    this.friends = const [],
    this.cloudOwnerUid,
  });

  final String id;
  final String title;
  final DateTime targetDate;
  final String iconId;
  final bool repeatYearly;
  final bool pinnedForWidget;

  /// Accepted friends for this D-Day (max [DdayInviteLimits.maxFriends]).
  /// Populated only from cloud membership — never from local picker.
  final List<DdayFriendMember> friends;

  /// Owner uid when this D-Day came from / is synced with cloud.
  final String? cloudOwnerUid;

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
        'friends': friends.map((e) => e.toJson()).toList(),
        if (cloudOwnerUid != null) 'cloudOwnerUid': cloudOwnerUid,
      };

  factory DdayItem.fromJson(Map<String, dynamic> json) {
    final friendsRaw = json['friends'] as List<dynamic>?;
    List<DdayFriendMember> friends = [];
    if (friendsRaw != null) {
      friends = friendsRaw
          .map((e) => DdayFriendMember.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((m) => m.uid.isNotEmpty)
          .take(DdayInviteLimits.maxFriends)
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
      friends: friends,
      cloudOwnerUid: json['cloudOwnerUid'] as String?,
    );
  }

  DdayItem copyWith({
    String? title,
    DateTime? targetDate,
    String? iconId,
    bool? repeatYearly,
    bool? pinnedForWidget,
    List<DdayFriendMember>? friends,
    bool clearFriends = false,
    String? cloudOwnerUid,
    bool clearCloudOwner = false,
  }) {
    return DdayItem(
      id: id,
      title: title ?? this.title,
      targetDate: targetDate ?? this.targetDate,
      iconId: iconId ?? this.iconId,
      repeatYearly: repeatYearly ?? this.repeatYearly,
      pinnedForWidget: pinnedForWidget ?? this.pinnedForWidget,
      friends: clearFriends ? const [] : (friends ?? this.friends),
      cloudOwnerUid:
          clearCloudOwner ? null : (cloudOwnerUid ?? this.cloudOwnerUid),
    );
  }
}

class DdayController extends ChangeNotifier {
  static const _prefsKey = 'dday_items_v1';
  static const _offsetsPrefsKey = 'dday_duo_offsets_v2';
  static const duoOffsetMinX = -220;
  static const duoOffsetMaxX = 220;
  static const duoOffsetMinY = -80;
  static const duoOffsetMaxY = 120;

  final List<DdayItem> _items = [];
  bool _loaded = false;

  int _duoMeOffsetX = 0;
  int _duoMeOffsetY = 0;
  int _duoFriendOffsetX = 0;
  int _duoFriendOffsetY = 0;

  List<DdayItem> get items {
    final sorted = [..._items];
    sorted.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    return List.unmodifiable(sorted);
  }

  bool get isLoaded => _loaded;

  int get duoMeOffsetX => _duoMeOffsetX;
  int get duoMeOffsetY => _duoMeOffsetY;
  int get duoFriendOffsetX => _duoFriendOffsetX;
  int get duoFriendOffsetY => _duoFriendOffsetY;

  DdayItem? get widgetDday {
    final pinned = _items.where((e) => e.pinnedForWidget).toList();
    if (pinned.isNotEmpty) return pinned.first;
    if (_items.isEmpty) return null;
    final sorted = [..._items]..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    return sorted.first;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    _items.clear();
    if (raw != null && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final entry in list) {
        _items.add(DdayItem.fromJson(Map<String, dynamic>.from(entry as Map)));
      }
    }
    _readOffsets(prefs.getString(_offsetsPrefsKey));
    _loaded = true;
    notifyListeners();
  }

  Future<void> reloadOffsetsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final before =
        '$_duoMeOffsetX,$_duoMeOffsetY,$_duoFriendOffsetX,$_duoFriendOffsetY';
    _readOffsets(prefs.getString(_offsetsPrefsKey));
    final after =
        '$_duoMeOffsetX,$_duoMeOffsetY,$_duoFriendOffsetX,$_duoFriendOffsetY';
    if (before != after) notifyListeners();
  }

  void _readOffsets(String? offsetsRaw) {
    if (offsetsRaw == null || offsetsRaw.isEmpty) return;
    try {
      final map = Map<String, dynamic>.from(jsonDecode(offsetsRaw) as Map);
      _duoMeOffsetX = _clampX(map['meX'] as int? ?? 0);
      _duoMeOffsetY = _clampY(map['meY'] as int? ?? 0);
      _duoFriendOffsetX = _clampX(map['friendX'] as int? ?? 0);
      _duoFriendOffsetY = _clampY(map['friendY'] as int? ?? 0);
    } catch (_) {}
  }

  Future<void> setDuoOffsets({
    int? meX,
    int? meY,
    int? friendX,
    int? friendY,
  }) async {
    var changed = false;
    if (meX != null) {
      final next = _clampX(meX);
      if (next != _duoMeOffsetX) {
        _duoMeOffsetX = next;
        changed = true;
      }
    }
    if (meY != null) {
      final next = _clampY(meY);
      if (next != _duoMeOffsetY) {
        _duoMeOffsetY = next;
        changed = true;
      }
    }
    if (friendX != null) {
      final next = _clampX(friendX);
      if (next != _duoFriendOffsetX) {
        _duoFriendOffsetX = next;
        changed = true;
      }
    }
    if (friendY != null) {
      final next = _clampY(friendY);
      if (next != _duoFriendOffsetY) {
        _duoFriendOffsetY = next;
        changed = true;
      }
    }
    if (!changed) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _offsetsPrefsKey,
      jsonEncode({
        'meX': _duoMeOffsetX,
        'meY': _duoMeOffsetY,
        'friendX': _duoFriendOffsetX,
        'friendY': _duoFriendOffsetY,
      }),
    );
    notifyListeners();
  }

  int _clampX(int value) => value.clamp(duoOffsetMinX, duoOffsetMaxX).toInt();
  int _clampY(int value) => value.clamp(duoOffsetMinY, duoOffsetMaxY).toInt();

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

  Future<void> pinForWidget(String id) async {
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      _items[i] = item.copyWith(pinnedForWidget: item.id == id);
    }
    await _persist();
  }

  Future<void> upsertFromCloud(DdayItem item) async {
    final index = _items.indexWhere((e) => e.id == item.id);
    if (index < 0) {
      _items.add(item);
    } else {
      final existing = _items[index];
      _items[index] = item.copyWith(
        pinnedForWidget: existing.pinnedForWidget,
      );
    }
    await _persist();
  }

  Future<void> applyFriendsFromCloud({
    required String ddayId,
    required List<DdayFriendMember> friends,
    String? cloudOwnerUid,
  }) async {
    final index = _items.indexWhere((e) => e.id == ddayId);
    if (index < 0) return;
    final next = friends.take(DdayInviteLimits.maxFriends).toList();
    final cur = _items[index];
    final sameFriends = cur.friends.length == next.length &&
        List.generate(next.length, (i) {
          return cur.friends[i].uid == next[i].uid &&
              cur.friends[i].characterId == next[i].characterId;
        }).every((e) => e);
    if (sameFriends && cur.cloudOwnerUid == cloudOwnerUid) return;
    _items[index] = cur.copyWith(
      friends: next,
      cloudOwnerUid: cloudOwnerUid,
    );
    await _persist();
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
