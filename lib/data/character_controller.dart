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
    required this.productId,
    required this.characterIds,
  });

  final String id;

  /// App Store / Play non-consumable product id (also imported to RevenueCat).
  final String productId;
  final List<String> characterIds;

  static const nyang = CharacterPack(
    id: 'nyang',
    productId: 'pack_nyang',
    characterIds: ['c20', 'c22', 'c23', 'c25', 'c26', 'c27', 'c28'],
  );

  /// Newest first. A new season goes at the top (name in AppStrings).
  static const List<CharacterPack> all = [nyang];

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

  /// Test-room friend sprite. Same art as the first shop character.
  static const bul = AppCharacter(
    id: 'bul',
    assetPath: 'assets/images/character/woman/character (1).png',
  );

  static final List<AppCharacter> shop = [
    basic,
    for (var i = 1; i <= 64; i++)
      AppCharacter(
        id: 'c$i',
        assetPath: 'assets/images/character/woman/character ($i).png',
        // Pack characters keep their ids so existing picks still resolve.
        group: CharacterPack.forCharacter('c$i') == null
            ? CharacterGroup.female
            : CharacterGroup.special,
      ),
    const AppCharacter(
      id: 'c65',
      assetPath: 'assets/images/character/woman/character(65).png',
      group: CharacterGroup.female,
    ),
    for (var i = 1; i <= 15; i++)
      AppCharacter(
        id: 'm$i',
        assetPath: 'assets/images/character/man/character ($i).png',
        group: CharacterGroup.male,
      ),
    const AppCharacter(
      id: 'm16',
      assetPath: 'assets/images/character/man/charcter(1).png',
      group: CharacterGroup.male,
    ),
    const AppCharacter(
      id: 'm17',
      assetPath: 'assets/images/character/man/character(2).png',
      group: CharacterGroup.male,
    ),
  ];

  static List<AppCharacter> inGroup(CharacterGroup group) {
    return [
      for (final character in shop)
        if (character.group == group) character,
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
  static const adUnlockLimit = 3;

  AppCharacter _character = AppCharacter.basic;
  bool _hasPicked = false;
  bool _loaded = false;
  final Set<String> _adUnlocked = {};
  final Set<String> _favorites = {};
  final Set<String> _ownedPacks = {};
  final Set<String> _seenPacks = {};

  AppCharacter get character => _character;
  bool get hasPicked => _hasPicked;
  bool get isLoaded => _loaded;
  String get assetPath => _character.assetPath;
  int get adUnlocksUsed => _adUnlocked.length;
  int get adUnlocksLeft =>
      (adUnlockLimit - _adUnlocked.length).clamp(0, adUnlockLimit);

  bool isUsable(AppCharacter character) {
    if (character.isDefault || character.id == AppCharacter.bul.id) return true;
    // Pack characters open only by buying the pack (not premium / ads).
    final pack = character.pack;
    if (pack != null) return ownsPack(pack);
    if (membershipController.isPremium) return true;
    return _adUnlocked.contains(character.id);
  }

  bool canUnlockWithAd(AppCharacter character) =>
      character.pack == null && !isUsable(character) && adUnlocksLeft > 0;

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
      isUsable(character) && _favorites.contains(character.id);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _hasPicked = prefs.getBool(_pickedKey) ?? false;
    _adUnlocked
      ..clear()
      ..addAll(_readIdList(prefs.getString(_adUnlocksKey)));
    if (_adUnlocked.length > adUnlockLimit) {
      final kept = _adUnlocked.take(adUnlockLimit).toList();
      _adUnlocked
        ..clear()
        ..addAll(kept);
      await prefs.setString(_adUnlocksKey, jsonEncode(kept));
    }
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
