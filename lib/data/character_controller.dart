import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:quotation/data/membership_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CharacterGroup { female, male }

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

  /// Always free. File is `assets/images/character/character.png`.
  static const basic = AppCharacter(
    id: 'basic',
    assetPath: 'assets/images/character/character.png',
    isDefault: true,
  );

  /// Test-room friend sprite. Same art as the first shop character.
  static const bul = AppCharacter(
    id: 'bul',
    assetPath: 'assets/images/character/character (1).png',
  );

  /// Current art is the female set. Male stays empty until images are added.
  static final List<AppCharacter> shop = [
    basic,
    for (var i = 1; i <= 64; i++)
      AppCharacter(
        id: 'c$i',
        assetPath: 'assets/images/character/character ($i).png',
        group: CharacterGroup.female,
      ),
    const AppCharacter(
      id: 'c65',
      assetPath: 'assets/images/character/character(65).png',
      group: CharacterGroup.female,
    ),
  ];

  static List<AppCharacter> inGroup(CharacterGroup group) {
    return [
      for (final character in shop)
        if (character.group == group) character,
    ];
  }

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
  static const adUnlockLimit = 3;

  AppCharacter _character = AppCharacter.basic;
  bool _hasPicked = false;
  bool _loaded = false;
  final Set<String> _adUnlocked = {};
  final Set<String> _favorites = {};

  AppCharacter get character => _character;
  bool get hasPicked => _hasPicked;
  bool get isLoaded => _loaded;
  String get assetPath => _character.assetPath;
  int get adUnlocksUsed => _adUnlocked.length;
  int get adUnlocksLeft =>
      (adUnlockLimit - _adUnlocked.length).clamp(0, adUnlockLimit);

  bool isUsable(AppCharacter character) {
    if (character.isDefault || character.id == AppCharacter.bul.id) return true;
    if (membershipController.isPremium) return true;
    return _adUnlocked.contains(character.id);
  }

  bool canUnlockWithAd(AppCharacter character) =>
      !isUsable(character) && adUnlocksLeft > 0;

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
