import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppCharacter {
  basic(
    id: 'basic',
    assetPath: 'assets/images/character.png',
    androidDrawable: 'character',
  ),
  bul(
    id: 'bul',
    assetPath: 'assets/images/character_bul.png',
    androidDrawable: 'character_bul',
  );

  const AppCharacter({
    required this.id,
    required this.assetPath,
    required this.androidDrawable,
  });

  final String id;
  final String assetPath;
  final String androidDrawable;

  static AppCharacter byId(String? id) {
    return AppCharacter.values.firstWhere(
      (c) => c.id == id,
      orElse: () => AppCharacter.basic,
    );
  }
}

class CharacterController extends ChangeNotifier {
  CharacterController();

  static const _prefsKey = 'selected_character_id';
  static const _pickedKey = 'character_picked';

  AppCharacter _character = AppCharacter.basic;
  bool _hasPicked = false;
  bool _loaded = false;

  AppCharacter get character => _character;
  bool get hasPicked => _hasPicked;
  bool get isLoaded => _loaded;
  String get assetPath => _character.assetPath;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _hasPicked = prefs.getBool(_pickedKey) ?? false;
    final saved = prefs.getString(_prefsKey);
    if (saved != null) {
      _character = AppCharacter.byId(saved);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> select(AppCharacter character, {bool markPicked = true}) async {
    _character = character;
    if (markPicked) _hasPicked = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, character.id);
    if (markPicked) {
      await prefs.setBool(_pickedKey, true);
    }
  }
}

final characterController = CharacterController();
