import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:quotation/data/membership_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CharacterGroup { female, male, special }

/// Seasonal character pack sold once per pack (non-consumable, 900원).
/// Owned forever: premium and ad unlocks do not open pack characters, and
/// cancelling the subscription never takes a bought pack away.
class CharacterPack {
  const CharacterPack({
    required this.id,
    required this._productId,
    this._appStoreProductId,
    required this.characterIds,
  });

  final String id;
  final String _productId;
  final String? _appStoreProductId;
  final List<String> characterIds;

  /// Non-consumable product id on this device's store (also imported to
  /// RevenueCat). [appStoreProductId] overrides it on iOS when the two
  /// stores' ids differ.
  String get productId => defaultTargetPlatform == TargetPlatform.iOS
      ? (_appStoreProductId ?? _productId)
      : _productId;

  static const nyang = CharacterPack(
    id: 'nyang',
    productId: 'pack_nyang',
    characterIds: ['c20', 'c23', 'c24', 'c25', 'c26', 'c27', 'c28'],
  );

  /// `assets/images/character/christmas/01.png` … `08.png`.
  /// App Store uses `_v2`: `pack_christmas` was first made there as a
  /// consumable and deleted, and App Store Connect never lets a deleted
  /// product id be used again. Google Play keeps `pack_christmas`.
  static const christmas = CharacterPack(
    id: 'christmas',
    productId: 'pack_christmas',
    appStoreProductId: 'pack_christmas_v2',
    characterIds: ['x1', 'x2', 'x3', 'x4', 'x5', 'x6', 'x7', 'x8'],
  );

  /// Newest first. A new season goes at the top (name in AppStrings).
  static const List<CharacterPack> all = [christmas, nyang];

  static CharacterPack? forCharacter(String id) {
    for (final pack in all) {
      if (pack.characterIds.contains(id)) return pack;
    }
    return null;
  }

  List<AppCharacter> get characters =>
      [for (final id in characterIds) AppCharacter.byId(id)];
}

class AppCharacter {
  const AppCharacter({
    required this.id,
    required this.assetPath,
    this.isDefault = false,
    this.group = CharacterGroup.female,
  });

  final String id;
  final String assetPath;
  final bool isDefault;
  final CharacterGroup group;

  /// Always free. File is `assets/images/character/woman/character.png`.
  static const basic = AppCharacter(
    id: 'basic',
    assetPath: 'assets/images/character/woman/character.png',
    isDefault: true,
  );

  /// Share event reward: opens after sending an invite code
  /// [CharacterController.shareEventGoal] times. Not sold, not ad-unlocked.
  static const shareEvent = AppCharacter(
    id: 'e1',
    assetPath: 'assets/images/character/shareEvent/01.png',
    group: CharacterGroup.special,
  );

  /// Test-room friend sprite. Same art as the first shop character.
  static const bul = AppCharacter(
    id: 'bul',
    assetPath: 'assets/images/character/woman/character (1).png',
  );

  /// Female shop display order (stable character ids). Files are renamed to
  /// `character (1).png` … matching this list; c62/c11 were removed earlier.
  static const femaleShopOrder = <int>[
    76, 71, 72, 73, 74, 75, 1, 77, 65, 78, 3, 64, 6, 5, 4, 2, 13, 7, 8, 9, 10, 12,
    14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35,
    36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57,
    58, 59, 60, 61, 63, 66, 67, 68, 69, 70,
  ];

  /// Male art files: `character (n).png` is the n-th id here. Keep this list
  /// as is; change the order people see in [maleShopOrder] instead.
  /// m28 was removed earlier (old file character(26).png); a saved m28 pick
  /// falls back in [byId].
  static const _maleFileOrder = <int>[
    40, 41, 42, 43, 44, 45, 46,
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
    18, 19, 20, 21, 22, 23, 24, 25, 26, 27,
    29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39,
    47,
  ];

  /// Male character everyone can use from the start, like [basic].
  static const maleDefaultId = 47;

  /// Male shop display order (stable character ids).
  static const maleShopOrder = <int>[
    47, 40, 39, 41, 42, 43, 44, 45, 46,
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
    18, 19, 20, 21, 22, 23, 24, 25, 26, 27,
    29, 30, 31, 32, 33, 34, 35, 36, 37, 38,
  ];

  static final List<AppCharacter> shop = [
    basic,
    for (var i = 0; i < femaleShopOrder.length; i++)
      AppCharacter(
        id: 'c${femaleShopOrder[i]}',
        assetPath:
            'assets/images/character/woman/character (${i + 1}).png',
        // Pack characters keep their ids so existing picks still resolve.
        group: CharacterPack.forCharacter('c${femaleShopOrder[i]}') == null
            ? CharacterGroup.female
            : CharacterGroup.special,
      ),
    for (var i = 0; i < maleShopOrder.length; i++)
      AppCharacter(
        id: 'm${maleShopOrder[i]}',
        assetPath: 'assets/images/character/man/character '
            '(${_maleFileOrder.indexOf(maleShopOrder[i]) + 1}).png',
        isDefault: maleShopOrder[i] == maleDefaultId,
        group: CharacterGroup.male,
      ),
    for (var i = 1; i <= 8; i++)
      AppCharacter(
        id: 'x$i',
        assetPath: 'assets/images/character/christmas/0$i.png',
        group: CharacterGroup.special,
      ),
    shareEvent,
  ];

  /// Duplicates taken out of the pickers. They stay in [shop] so a saved pick
  /// (mine or a friend's, on any app version) still draws the same art.
  /// m8 repeats m7/m9; m16 repeats m13; c22 was taken out of the kitty pack
  /// (hidden so it does not fall into the female tab).
  static const Set<String> hiddenFromPickers = {'m8', 'm16', 'c22'};

  static List<AppCharacter> inGroup(CharacterGroup group) {
    return [
      for (final character in shop)
        if (character.group == group &&
            !hiddenFromPickers.contains(character.id))
          character,
    ];
  }

  CharacterPack? get pack => CharacterPack.forCharacter(id);

  static AppCharacter byId(String? id) {
    if (id == 'bul') return bul;
    for (final character in shop) {
      if (character.id == id) return character;
    }
    return basic;
  }
}

class CharacterController extends ChangeNotifier {
  CharacterController() {
    membershipController.addListener(notifyListeners);
  }

  static const _prefsKey = 'selected_character_id';
  static const _pickedKey = 'character_picked';
  static const _adUnlocksKey = 'character_ad_unlocks';
  static const _favoritesKey = 'character_favorites';
  static const _ownedPacksKey = 'character_owned_packs';
  static const _seenPacksKey = 'character_seen_packs';
  static const _inviteSendsKey = 'share_event_invite_sends';
  static const _inviteDoneKey = 'share_event_completed';

  /// Invite codes to send (any room, any number of rooms) for the event
  /// character.
  static const shareEventGoal = 3;
  /// Characters one person can open with ads (lock tiles).
  static const adUnlockLimit = 2;

  AppCharacter _character = AppCharacter.basic;
  bool _hasPicked = false;
  bool _loaded = false;
  final Set<String> _adUnlocked = {};
  final Set<String> _favorites = {};
  final Set<String> _ownedPacks = {};
  final Set<String> _seenPacks = {};
  int _inviteSends = 0;
  bool _inviteEventCompleted = false;

  /// Invite codes sent so far, capped at [shareEventGoal].
  int get inviteSends => _inviteSends.clamp(0, shareEventGoal);

  /// True after 3 invites (or a prior completion flag) — Together banner stays hidden.
  bool get shareEventDone =>
      _inviteEventCompleted || _inviteSends >= shareEventGoal;

  /// Counts one sent invite code. True when this send opened the event
  /// character.
  Future<bool> recordInviteSent() async {
    if (shareEventDone) return false;
    _inviteSends++;
    final opened = _inviteSends >= shareEventGoal;
    if (opened) _inviteEventCompleted = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_inviteSendsKey, _inviteSends);
    if (opened) await prefs.setBool(_inviteDoneKey, true);
    return opened;
  }

  AppCharacter get character => _character;
  bool get hasPicked => _hasPicked;
  bool get isLoaded => _loaded;
  String get assetPath => _character.assetPath;
  int get adUnlocksUsed => _adUnlocked.length;
  int get adUnlocksLeft =>
      (adUnlockLimit - _adUnlocked.length).clamp(0, adUnlockLimit);

  bool isUsable(AppCharacter character) {
    if (character.isDefault || character.id == AppCharacter.bul.id) return true;
    // The event character opens only through the share event.
    if (character.id == AppCharacter.shareEvent.id) return shareEventDone;
    // Pack characters open only by buying the pack (not premium / ads).
    final pack = character.pack;
    if (pack != null) return ownsPack(pack);
    if (membershipController.isPremium) return true;
    return _adUnlocked.contains(character.id);
  }

  bool canUnlockWithAd(AppCharacter character) =>
      character.pack == null &&
      character.id != AppCharacter.shareEvent.id &&
      !isUsable(character) &&
      adUnlocksLeft > 0;

  bool ownsPack(CharacterPack pack) => _ownedPacks.contains(pack.id);

  /// Adds packs the store reports as bought. Never removes one, so a pack
  /// stays owned whatever happens to the subscription.
  Future<void> addOwnedPacks(Iterable<String> packIds) async {
    final before = _ownedPacks.length;
    _ownedPacks.addAll(packIds);
    if (_ownedPacks.length == before) return;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ownedPacksKey, jsonEncode(_ownedPacks.toList()));
  }

  /// Newest pack not opened in the special tab yet (shows a dot on the tab).
  bool get hasUnseenPack =>
      CharacterPack.all.isNotEmpty &&
      !_seenPacks.contains(CharacterPack.all.first.id);

  Future<void> markPacksSeen() async {
    final before = _seenPacks.length;
    _seenPacks.addAll(CharacterPack.all.map((p) => p.id));
    if (_seenPacks.length == before) return;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_seenPacksKey, jsonEncode(_seenPacks.toList()));
  }

  bool isFavorite(AppCharacter character) =>
      _favorites.contains(character.id);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _hasPicked = prefs.getBool(_pickedKey) ?? false;
    _inviteSends = prefs.getInt(_inviteSendsKey) ?? 0;
    _inviteEventCompleted = prefs.getBool(_inviteDoneKey) ?? false;
    // Older installs only had the send count — treat goal reached as done.
    if (!_inviteEventCompleted && _inviteSends >= shareEventGoal) {
      _inviteEventCompleted = true;
      await prefs.setBool(_inviteDoneKey, true);
    }
    _adUnlocked
      ..clear()
      ..addAll(_readIdList(prefs.getString(_adUnlocksKey)));
    // Keep characters already opened under the old limit of 3; the new
    // limit only stops further ad unlocks (adUnlocksLeft clamps to 0).
    _favorites
      ..clear()
      ..addAll(_readIdList(prefs.getString(_favoritesKey)));
    _ownedPacks
      ..clear()
      ..addAll(_readIdList(prefs.getString(_ownedPacksKey)));
    _seenPacks
      ..clear()
      ..addAll(_readIdList(prefs.getString(_seenPacksKey)));
    final saved = prefs.getString(_prefsKey);
    if (saved != null) {
      _character = AppCharacter.byId(saved);
    }
    if (!isUsable(_character)) _character = AppCharacter.basic;
    _loaded = true;
    notifyListeners();
  }

  Future<bool> select(AppCharacter character, {bool markPicked = true}) async {
    if (!isUsable(character)) return false;
    _character = character;
    if (markPicked) _hasPicked = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, character.id);
    if (markPicked) {
      await prefs.setBool(_pickedKey, true);
    }
    return true;
  }

  /// Marks an owned character so it stays at the front of the list.
  Future<void> toggleFavorite(AppCharacter character) async {
    if (!isUsable(character)) return;
    if (_favorites.contains(character.id)) {
      _favorites.remove(character.id);
    } else {
      _favorites.add(character.id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favoritesKey, jsonEncode(_favorites.toList()));
  }

  /// Remembers one character opened with a full-screen ad. Capped at 3.
  Future<bool> unlockWithAd(AppCharacter character) async {
    if (isUsable(character)) return true;
    if (adUnlocksLeft <= 0 || character.isDefault) return false;
    _adUnlocked.add(character.id);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adUnlocksKey, jsonEncode(_adUnlocked.toList()));
    return true;
  }

  static List<String> _readIdList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is String && item.isNotEmpty) item,
      ];
    } catch (_) {
      return const [];
    }
  }
}

final characterController = CharacterController();
