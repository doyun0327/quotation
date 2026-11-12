import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quotation/widgets/subscribe_flow.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:quotation/data/character_art_insets.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/home_widget_sync.dart';
import 'package:quotation/data/membership_controller.dart';
import 'package:quotation/data/together_bg_themes.dart';
import 'package:quotation/data/blocked_users_controller.dart';
import 'package:quotation/data/together_bubble.dart';
import 'package:quotation/data/widget_album_background.dart';
import 'package:quotation/data/widget_fonts.dart';
import 'package:quotation/data/together_cheer_repository.dart';
import 'package:quotation/data/together_crowd_layout.dart';
import 'package:quotation/data/together_editing.dart';
import 'package:quotation/data/together_guide.dart';
import 'package:quotation/data/user_profile_sync.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/screens/shop_screen.dart';
import 'package:quotation/widgets/color_palette_sheet.dart';
import 'package:quotation/widgets/editing_dots_overlay.dart';
import 'package:quotation/widgets/ios_widget_guide.dart';
import 'package:quotation/widgets/sign_in_flow.dart';
import 'package:quotation/widgets/together_bubble_view.dart';
import 'package:quotation/widgets/together_widget_preview.dart';
import 'package:quotation/widgets/subscription_terms.dart';

/// In-app editor for a Together room home widget.
class DdayWidgetDecorateScreen extends StatefulWidget {
  const DdayWidgetDecorateScreen({super.key, required this.roomId});

  final String roomId;

  @override
  State<DdayWidgetDecorateScreen> createState() =>
      _DdayWidgetDecorateScreenState();
}

class _DdayWidgetDecorateScreenState extends State<DdayWidgetDecorateScreen> {
  /// Matches Android widget character ImageView size (72×96 dp).
  static const charW = 72.0;
  static const charH = 96.0;

  static const _textQuick = <int>[
    0xFF000000,
    0xFFFFFFFF,
    0xFF9E9E9E,
    0xFFE53935,
    0xFFFF9800,
    0xFFFBC02D,
    0xFF43A047,
    0xFF1E88E5,
    0xFF8E24AA,
    0xFFF26B8A,
  ];

  late double _meX;
  late double _meY;
  late double _friendX;
  late double _friendY;
  late double _textX;
  late double _textY;
  late double _textRotation;
  late int _meScale;
  late int _friendScale;

  /// Size slider per friend in the room (uid → percent). [_friendScale] is
  /// only the fallback for friends an older layout never sized.
  Map<String, int> _personScale = {};
  late int _textScale;
  _DecorateFocus _focus = _DecorateFocus.none;
  String? _pickedFriendUid;
  bool _scaleMe = true;
  late String _bgThemeId;
  late int _textColor;
  late WidgetFont _textFont;
  late TogetherWidgetSize _widgetSize;
  Size? _hostSize;
  TogetherWidgetSize? _hostForSize;
  double _hostCornerDp = TogetherWidgetSize.defaultCornerDp;
  bool _dragging = false;
  bool _crowdDirty = false;
  List<TogetherPlaced> _placed = const [];
  String _placedKey = '';
  List<TogetherBubble> _bubbles = const [];
  String? _bubbleId;
  bool _editingBubble = false;
  Timer? _presenceBeat;
  AppLifecycleListener? _presenceLife;
  bool _savingCheer = false;
  final bool _loggingIn = false;

  final _cheerCtrl = TextEditingController();
  final _cheerDraft = ValueNotifier<String>('');
  final _cheerFocus = FocusNode();
  final _bubbleCtrl = TextEditingController();
  final _bubbleFocus = FocusNode();
  final _dragTick = ValueNotifier<int>(0);
  bool _applyingRemote = false;
  bool _samsung = false;
  bool _widgetExported = false;

  /// First home export: Galaxy opens the add sheet, iPhone shows the guide.
  bool get _firstExport =>
      (_samsung || IosWidgetGuide.isIOS) && !_widgetExported;

  static const _shape = TogetherWidgetShape.square;

  @override
  void initState() {
    super.initState();
    unawaited(_loadHostSize());
    unawaited(TogetherGuide.markDecorated(widget.roomId));
    unawaited(_loadExportLabel());
    final id = widget.roomId;
    _meX = ddayController.meOffsetXForRoom(id).toDouble();
    _meY = ddayController.meOffsetYForRoom(id).toDouble();
    _friendX = ddayController.friendOffsetXForRoom(id).toDouble();
    _friendY = ddayController.friendOffsetYForRoom(id).toDouble();
    _textX = ddayController.textOffsetXForRoom(id).toDouble();
    _textY = ddayController.textOffsetYForRoom(id).toDouble();
    _textRotation = ddayController.textRotationForRoom(id).toDouble();
    _meScale = ddayController.charScaleForRoom(id);
    _friendScale = ddayController.friendScaleForRoom(id);
    _adoptSavedScales(TogetherCrowdLayout.scalesOf(ddayController.crowdForRoom(id)));
    _textScale = ddayController.textScaleForRoom(id);
    final savedTheme = ddayController.bgThemeForRoom(id);
    _bgThemeId = savedTheme == TogetherBgTheme.albumId
        ? 'widget_background'
        : savedTheme;
    final migrateAlbum = savedTheme == TogetherBgTheme.albumId;
    _textColor = ddayController.textColorForRoom(id);
    _textFont = ddayController.textFontForRoom(id);
    _bubbles = ddayController.bubblesForRoom(id);
    _widgetSize = TogetherWidgetSize.s42;
    final rooms = ddayController.items.where((e) => e.id == id);
    _cheerCtrl.text =
        rooms.isEmpty ? '' : (rooms.first.latestCheer?.trim() ?? '');
    _cheerDraft.value = _cheerCtrl.text;
    _cheerCtrl.addListener(_onCheerEdited);
    // Typing cheer clears character / bubble selection on the preview.
    _cheerFocus.addListener(_onCheerFocusChanged);
    // Losing the keyboard focus some other way ends typing too.
    _bubbleFocus.addListener(() {
      if (!_bubbleFocus.hasFocus) _finishBubbleEdit();
    });
    _adoptCrowd();
    ddayController.addListener(_syncFromController);
    unawaited(_syncAfterOpen(migrateAlbum: migrateAlbum));
  }

  void _onCheerFocusChanged() {
    if (!_cheerFocus.hasFocus) return;
    _clearSelection();
  }

  /// Drops character / bubble / cheer selection on the preview.
  void _clearSelection() {
    if (_focus == _DecorateFocus.none && !_editingBubble) return;
    if (_editingBubble) _finishBubbleEdit();
    if (!mounted) return;
    setState(() {
      _focus = _DecorateFocus.none;
      _bubbleId = null;
    });
  }

  /// Widget re-render is heavy, so it waits until the push transition has
  /// finished; running it during the slide made opening the decorator stall.
  Future<void> _syncAfterOpen({required bool migrateAlbum}) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    if (migrateAlbum) {
      await _persist();
    } else {
      try {
        await HomeWidgetSync.syncDday();
      } catch (_) {}
    }
    // The launcher may report a new cell size after the refresh.
    await _loadHostSize();
    _startPresence();
  }

  /// Friends see typing dots over my character while this screen is open.
  /// Only rooms with friends, so a solo room never writes.
  void _startPresence() {
    if (!mounted || (_room?.friends.isEmpty ?? true)) return;
    _beginPresence();
    // Leaving the app with the decorator open is not editing: clear the
    // stamp right away instead of waiting for it to expire.
    _presenceLife = AppLifecycleListener(
      onPause: _endPresence,
      onResume: () {
        if (mounted) _beginPresence();
      },
    );
  }

  void _beginPresence() {
    _presenceBeat?.cancel();
    unawaited(TogetherEditingPresence.write(widget.roomId, editing: true));
    _presenceBeat = Timer.periodic(TogetherEditingPresence.heartbeat, (_) {
      unawaited(TogetherEditingPresence.write(widget.roomId, editing: true));
    });
  }

  void _endPresence() {
    if (_presenceBeat == null) return;
    _presenceBeat!.cancel();
    _presenceBeat = null;
    unawaited(TogetherEditingPresence.write(widget.roomId, editing: false));
  }

  void _syncFromController() {
    if (!mounted || _dragging || _applyingRemote) return;
    final id = widget.roomId;
    final meX = ddayController.meOffsetXForRoom(id).toDouble();
    final meY = ddayController.meOffsetYForRoom(id).toDouble();
    final friendX = ddayController.friendOffsetXForRoom(id).toDouble();
    final friendY = ddayController.friendOffsetYForRoom(id).toDouble();
    final textX = ddayController.textOffsetXForRoom(id).toDouble();
    final textY = ddayController.textOffsetYForRoom(id).toDouble();
    final textRotation = ddayController.textRotationForRoom(id).toDouble();
    final meScale = ddayController.charScaleForRoom(id);
    final friendScale = ddayController.friendScaleForRoom(id);
    final textScale = ddayController.textScaleForRoom(id);
    final theme = ddayController.bgThemeForRoom(id);
    final color = ddayController.textColorForRoom(id);
    final font = ddayController.textFontForRoom(id);
    // The open edit sheet owns the draft; a reload would drop a new bubble.
    final bubbles =
        _editingBubble ? _bubbles : ddayController.bubblesForRoom(id);
    final layoutChanged = _meX != meX ||
        _meY != meY ||
        _friendX != friendX ||
        _friendY != friendY ||
        _textX != textX ||
        _textY != textY ||
        _textRotation != textRotation ||
        _meScale != meScale ||
        _friendScale != friendScale ||
        _textScale != textScale ||
        _bgThemeId != theme ||
        _textColor != color ||
        _textFont != font ||
        !TogetherBubble.sameList(_bubbles, bubbles);
    final crowdChanged = _adoptCrowd();
    // Sizes a friend saved for each person. Skipped while my own crowd edit
    // is unsaved so the slider I am dragging does not jump back.
    final scales = TogetherCrowdLayout.scalesOf(ddayController.crowdForRoom(id));
    final scalesChanged = !_crowdDirty && _savedScalesDiffer(scales);
    if (scalesChanged) _adoptSavedScales(scales);
    if (layoutChanged || crowdChanged || scalesChanged) {
      setState(() {
        _meX = meX;
        _meY = meY;
        _friendX = friendX;
        _friendY = friendY;
        _textX = textX;
        _textY = textY;
        _textRotation = textRotation;
        _meScale = meScale;
        _friendScale = friendScale;
        _textScale = textScale;
        _bgThemeId = theme;
        _textColor = color;
        _textFont = font;
        _bubbles = bubbles;
        if (!_bubbles.any((b) => b.id == _bubbleId)) _bubbleId = null;
        if (_focus == _DecorateFocus.friend) _scaleMe = false;
      });
    }
    if (_cheerFocus.hasFocus) return;
    final cheer = _room?.latestCheer?.trim() ?? '';
    if (_cheerCtrl.text == cheer) return;
    _applyingRemote = true;
    _cheerCtrl.text = cheer;
    _cheerDraft.value = cheer;
    _applyingRemote = false;
  }

  void _onCheerEdited() {
    if (_applyingRemote) return;
    final text = _cheerCtrl.text;
    if (_cheerDraft.value == text) return;
    _cheerDraft.value = text;
  }

  Future<void> _loadHostSize() async {
    // Offsets changed from the home-widget ⚙ screen. Cheap prefs read; the
    // full widget redraw runs later in _syncAfterOpen.
    try {
      await ddayController.reloadOffsetsFromPrefs();
    } catch (_) {}
    final host = await HomeWidgetSync.loadHostPreviewSize(
      roomId: widget.roomId,
    );
    if (!mounted || host == null) return;
    if (host.size == _hostSize &&
        host.forSize == _hostForSize &&
        host.cornerDp == _hostCornerDp) {
      return;
    }
    setState(() {
      _hostSize = host.size;
      _hostForSize = host.forSize;
      _hostCornerDp = host.cornerDp;
      if (_dragging) return;
      _adoptCrowd();
      final id = widget.roomId;
      _meX = ddayController.meOffsetXForRoom(id).toDouble();
      _meY = ddayController.meOffsetYForRoom(id).toDouble();
      _friendX = ddayController.friendOffsetXForRoom(id).toDouble();
      _friendY = ddayController.friendOffsetYForRoom(id).toDouble();
      _fitCharacters();
    });
  }

  @override
  void dispose() {
    _presenceLife?.dispose();
    _endPresence();
    ddayController.removeListener(_syncFromController);
    _cheerCtrl.removeListener(_onCheerEdited);
    _cheerFocus.removeListener(_onCheerFocusChanged);
    _cheerCtrl.dispose();
    _cheerDraft.dispose();
    _cheerFocus.dispose();
    _bubbleCtrl.dispose();
    _bubbleFocus.dispose();
    _dragTick.dispose();
    super.dispose();
  }

  String _nicknameOr(String? raw, String fallback) {
    final name = raw?.trim();
    if (name != null && name.isNotEmpty) return name;
    return fallback;
  }

  String _friendNickname(DdayItem? room, AppStrings t) {
    final friends = room?.friends ?? const [];
    for (final friend in friends) {
      if (friend.uid == _pickedFriendUid) {
        return _nicknameOr(friend.displayName, t.togetherFriendFallbackName);
      }
    }
    if (friends.isNotEmpty) {
      return _nicknameOr(friends.first.displayName, t.togetherFriendFallbackName);
    }
    return t.togetherFriendFallbackName;
  }

  DdayItem? get _room {
    final matches =
        ddayController.items.where((e) => e.id == widget.roomId);
    return matches.isEmpty ? null : matches.first;
  }

  Future<bool> _saveCheerIfNeeded({bool quiet = false}) async {
    final t = AppStrings.current;
    final text = _cheerCtrl.text.trim();
    final existing = _room?.latestCheer?.trim() ?? '';
    // An emptied field is saved too, so the old cheer does not come back.
    if (text == existing) return true;
    if (_savingCheer || _loggingIn) return false;

    final ok = await authController.ensureFirebaseSession();
    if (!ok) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.togetherCheerFailed)),
      );
      return false;
    }

    setState(() => _savingCheer = true);
    final result = await TogetherCheerRepository.save(
      roomId: widget.roomId,
      text: text,
    );
    if (!mounted) return false;
    setState(() => _savingCheer = false);
    if (result.ok) return true;
    if (quiet) return false;
    final message = switch (result.errorCode) {
      'not_signed_in' => t.togetherCheerNeedLogin,
      'permission' => t.togetherCheerPermission,
      'other_account' => t.togetherCheerOtherAccount,
      _ => t.togetherCheerFailed,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    return false;
  }

  Future<void> _loadExportLabel() async {
    final samsung = await TogetherGuide.isSamsung();
    final exported = await TogetherGuide.hasExportedWidget();
    if (!mounted) return;
    setState(() {
      _samsung = samsung;
      _widgetExported = exported;
    });
  }

  Future<void> _persist({bool applyToHome = false, bool toast = false}) async {
    // A cheer the room did not take must not look applied: the cloud copy
    // would put the old words back a moment later.
    var cheerOk = true;
    if (applyToHome) {
      cheerOk = await _saveCheerIfNeeded(quiet: !toast);
      if (cheerOk) {
        await ddayController.setRoomCheer(widget.roomId, _cheerCtrl.text);
      }
    }
    await ddayController.setDuoOffsets(
      roomId: widget.roomId,
      meX: _meX.round(),
      meY: _meY.round(),
      friendX: _friendX.round(),
      friendY: _friendY.round(),
      textX: _textX.round(),
      textY: _textY.round(),
      textRotation: _textRotation.round(),
      charScale: _meScale,
      friendScale: _friendScale,
      textScale: _textScale,
      bgTheme: _bgThemeId,
      bgOpacity: 100,
      textColor: _textColor,
      textFont: _textFont,
      shape: _shape,
      widgetSize: _widgetSize,
      bubbles: _bubbles,
      notifyFriends: applyToHome,
      canvasW: _previewSize.width,
      canvasH: _previewSize.height,
      crowdKey: (_crowdDirty || applyToHome) ? _placedKey : null,
      crowd: (_crowdDirty || applyToHome)
          ? [
              for (final person in _placed)
                (
                  uid: person.uid,
                  x: person.x.round(),
                  y: person.y.round(),
                  rotation: person.rotationDegrees,
                  scale: _scaleOf(person.uid),
                ),
            ]
          : null,
    );
    if (_crowdDirty) _crowdDirty = false;
    if (applyToHome) {
      final previousRoom = ddayController.widgetDday?.id;
      await ddayController.applyRoomToHomeWidget(widget.roomId);
      await HomeWidgetSync.syncAndOfferPinTogetherWidget(
        roomId: widget.roomId,
        previousRoomId: previousRoom,
      );
      if (_samsung && !_widgetExported) {
        await TogetherGuide.markExportedWidget();
        _widgetExported = true;
      }
      if (toast && cheerOk && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.current.togetherWidgetSyncToast)),
        );
      }
      return;
    }
    await HomeWidgetSync.syncDday();
    if (toast && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.current.ddayDuoTestUpdatedToast)),
      );
    }
  }

  /// My character in this room (main-screen pick until one is chosen here).
  AppCharacter get _meChar => ddayController.meCharacterForRoom(widget.roomId);

  /// Picks my character for this room only, then redraws the widgets.
  Future<void> _pickMyCharacter() async {
    final picked = await Navigator.of(context).push<AppCharacter>(
      MaterialPageRoute(
        builder: (_) => ShopScreen(pickForRoomSelectedId: _meChar.id),
      ),
    );
    if (picked == null || !mounted || picked.id == _meChar.id) return;
    await ddayController.setMeCharacterForRoom(widget.roomId, picked.id);
    if (!mounted) return;
    setState(() {
      _adoptCrowd();
      _fitCharacters();
    });
    _dragTick.value++;
    // Heavy work (cloud write, widget image render) waits until the pop
    // transition has finished so returning to the decorator stays smooth.
    unawaited(() async {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      await UserProfileSync.syncRoomCharacter(widget.roomId, picked.id);
      await HomeWidgetSync.syncDday();
    }());
  }

  bool _adoptCrowd() {
    final room = _room;
    if (room == null) return false;
    final people = TogetherCrowdLayout.roster(
      myUid: authController.viewerUid,
      myCharacterId: _meChar.id,
      myIds: authController.myIds,
      hostUid: room.cloudOwnerUid,
      friends: room.friends,
    );
    final key = TogetherCrowdLayout.keyFor(people);
    if (_crowdDirty && key == _placedKey) {
      return _applyLiveCharacters(people);
    }
    final next = TogetherCrowdLayout.resolve(
      people: people,
      canvasW: _previewSize.width,
      canvasH: _previewSize.height,
      charFactor: _widgetSize.charFactor,
      saved: ddayController.crowdForRoom(room.id),
    );
    if (key == _placedKey && _samePlaced(_placed, next)) {
      return _applyLiveCharacters(people);
    }
    _placed = next;
    _placedKey = key;
    _crowdDirty = false;
    return true;
  }

  /// Positions stay put. The picture follows the friend's current character.
  bool _applyLiveCharacters(List<TogetherCrowdPerson> people) {
    final byUid = {for (final person in people) person.uid: person.characterId};
    var changed = false;
    final next = <TogetherPlaced>[];
    for (final person in _placed) {
      final id = byUid[person.uid];
      if (id == null) {
        changed = true;
        continue;
      }
      if (id == person.characterId) {
        next.add(person);
        continue;
      }
      changed = true;
      next.add(person.copyWith(characterId: id));
    }
    if (changed) _placed = next;
    return changed;
  }

  bool _samePlaced(List<TogetherPlaced> a, List<TogetherPlaced> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].uid != b[i].uid ||
          a[i].x.round() != b[i].x.round() ||
          a[i].y.round() != b[i].y.round() ||
          a[i].scale != b[i].scale ||
          a[i].rotationDegrees != b[i].rotationDegrees) {
        return false;
      }
    }
    return true;
  }

  void _movePerson(String uid, double dx, double dy) {
    final next = <TogetherPlaced>[];
    for (final person in _placed) {
      if (person.uid != uid) {
        next.add(person);
        continue;
      }
      next.add(_fitPerson(person, person.x + dx, person.y + dy));
    }
    _placed = next;
    _crowdDirty = true;
    _dragTick.value++;
  }

  /// Size slider for [uid]: mine, that friend's own, else the shared
  /// friend fallback.
  int _scaleOf(String uid) => uid == authController.viewerUid
      ? _meScale
      : (_personScale[uid] ?? _friendScale);

  void _adoptSavedScales(Map<String, int> scales) {
    final me = authController.viewerUid;
    final mine = scales[me];
    if (mine != null) _meScale = mine;
    _personScale = {
      for (final e in scales.entries)
        if (e.key != me) e.key: e.value,
    };
  }

  bool _savedScalesDiffer(Map<String, int> scales) {
    final me = authController.viewerUid;
    if (scales.containsKey(me) && scales[me] != _meScale) return true;
    for (final e in scales.entries) {
      if (e.key != me && _personScale[e.key] != e.value) return true;
    }
    return false;
  }

  /// The slider moved for the friend I picked. Friends not sized yet keep
  /// the size they show now, so only the picked one changes.
  void _setFriendScale(int value) {
    final picked = _pickedFriendUid;
    if (picked == null || _placed.isEmpty) {
      _friendScale = value;
      return;
    }
    final me = authController.viewerUid;
    for (final person in _placed) {
      if (person.uid == me) continue;
      _personScale.putIfAbsent(person.uid, () => _friendScale);
    }
    _personScale[picked] = value;
    _crowdDirty = true;
  }

  /// Clamps [person] inside the background at the size it is actually drawn
  /// (layout scale × size slider), so a scaled-up character cannot be
  /// dragged or grown past the edge.
  TogetherPlaced _fitPerson(TogetherPlaced person, double x, double y) {
    final size = _previewSize;
    final isMe = person.uid == authController.viewerUid;
    final scale =
        person.scale * TogetherCrowdLayout.userFactor(_scaleOf(person.uid));
    final fitted = TogetherCharacterBounds.me(
      x: x,
      y: y,
      width: size.width,
      height: size.height,
      charW: charW * _widgetSize.charFactor * scale,
      charH: charH * _widgetSize.charFactor * scale,
      art: CharacterArtInsets.forAsset(
        isMe ? _meChar.assetPath : AppCharacter.byId(person.characterId).assetPath,
      ),
    );
    return person.copyWith(x: fitted.x, y: fitted.y);
  }

  void _rotateText(double degrees) {
    var next = degrees.round() % 360;
    if (next < 0) next += 360;
    _textRotation = next.toDouble();
    _dragTick.value++;
  }

  void _rotatePerson(String uid, double degrees) {
    final next = <TogetherPlaced>[];
    for (final person in _placed) {
      if (person.uid != uid) {
        next.add(person);
        continue;
      }
      next.add(person.copyWith(rotation: degrees));
    }
    _placed = next;
    _crowdDirty = true;
    _dragTick.value++;
  }

  List<TogetherPreviewSprite> _crowdSprites() {
    final myUid = authController.viewerUid;
    return [
      for (final person in _placed)
        TogetherPreviewSprite(
          keyId: person.uid,
          assetPath: person.uid == myUid
              ? _meChar.assetPath
              : AppCharacter.byId(person.characterId).assetPath,
          x: person.x,
          y: person.y,
          scale: person.scale *
              TogetherCrowdLayout.userFactor(_scaleOf(person.uid)),
          rotation: person.rotation,
          onRotate: (person.uid == myUid
                  ? _focus == _DecorateFocus.me
                  : _focus == _DecorateFocus.friend &&
                      _pickedFriendUid == person.uid)
              ? (delta) => _rotatePerson(person.uid, delta)
              : null,
          highlight: person.uid == myUid
              ? _focus == _DecorateFocus.me
              : _focus == _DecorateFocus.friend &&
                  _pickedFriendUid == person.uid,
          onSelect: () {
            if (person.uid == myUid) {
              _selectMe();
            } else {
              _selectFriendMember(person.uid);
            }
          },
          onPan: (person.uid == myUid
                  ? _focus == _DecorateFocus.me
                  : _focus == _DecorateFocus.friend &&
                      _pickedFriendUid == person.uid)
              ? (dx, dy) => _movePerson(person.uid, dx, dy)
              : null,
        ),
    ];
  }

  double _spriteW(int scale) =>
      charW *
      _widgetSize.charFactor *
      (scale / 100).clamp(
        DdayController.scaleMin / 100,
        DdayController.charScaleMax / 100,
      );

  double _spriteH(int scale) =>
      charH *
      _widgetSize.charFactor *
      (scale / 100).clamp(
        DdayController.scaleMin / 100,
        DdayController.charScaleMax / 100,
      );

  Size get _previewSize => TogetherWidgetPreview.sizeForShape(
        _shape,
        _widgetSize,
        _hostSize,
        _hostForSize,
      );

  void _fitCharacters() {
    final size = _previewSize;
    final me = TogetherCharacterBounds.me(
      x: _meX,
      y: _meY,
      width: size.width,
      height: size.height,
      charW: _spriteW(_meScale),
      charH: _spriteH(_meScale),
    );
    final friend = TogetherCharacterBounds.me(
      x: _friendX,
      y: _friendY,
      width: size.width,
      height: size.height,
      charW: _spriteW(_friendScale),
      charH: _spriteH(_friendScale),
    );
    _meX = me.x;
    _meY = me.y;
    _friendX = friend.x;
    _friendY = friend.y;
    // Crowd sprites too: growing one with the slider pulls it back inside.
    var moved = false;
    final placed = <TogetherPlaced>[];
    for (final person in _placed) {
      final fitted = _fitPerson(person, person.x, person.y);
      if (fitted.x != person.x || fitted.y != person.y) moved = true;
      placed.add(fitted);
    }
    if (moved) {
      _placed = placed;
      _crowdDirty = true;
    }
  }

  void _clampMe(double dx, double dy) {
    _meX += dx;
    _meY += dy;
    _fitCharacters();
    _dragTick.value++;
  }

  void _clampFriend(double dx, double dy) {
    _friendX += dx;
    _friendY += dy;
    _fitCharacters();
    _dragTick.value++;
  }

  void _selectMe() {
    if (_focus == _DecorateFocus.me) return;
    setState(() {
      _focus = _DecorateFocus.me;
      _scaleMe = true;
    });
  }

  void _selectFriend() {
    final friends = _room?.friends;
    if (friends == null || friends.isEmpty) return;
    final uid = friends.first.uid;
    if (_focus == _DecorateFocus.friend && _pickedFriendUid == uid) return;
    setState(() {
      _pickedFriendUid = uid;
      _focus = _DecorateFocus.friend;
      _scaleMe = false;
    });
  }

  void _selectFriendMember(String uid) {
    if (_focus == _DecorateFocus.friend && _pickedFriendUid == uid) return;
    setState(() {
      _pickedFriendUid = uid;
      _focus = _DecorateFocus.friend;
      _scaleMe = false;
    });
  }

  void _selectText() {
    if (_focus == _DecorateFocus.text) return;
    setState(() => _focus = _DecorateFocus.text);
  }

  void _clampText(double dx, double dy) {
    _textX = (_textX + dx).clamp(
      DdayController.textOffsetMinX.toDouble(),
      DdayController.textOffsetMaxX.toDouble(),
    );
    _textY = (_textY + dy).clamp(
      DdayController.textOffsetMinY.toDouble(),
      DdayController.textOffsetMaxY.toDouble(),
    );
    _dragTick.value++;
  }

  List<TogetherPreviewBubble> _bubbleSprites() => [
        for (final b in blockedUsersController.visibleBubbles(
          widget.roomId,
          _bubbles,
        ))
          TogetherPreviewBubble(
            bubble: b,
            highlight: _focus == _DecorateFocus.bubble && _bubbleId == b.id,
            onSelect: () => _selectBubble(b.id),
            onPan: _editingBubble
                ? null
                : (dx, dy) => _moveBubble(b.id, dx, dy),
            onEdit: () => _tapBubble(b.id),
            onRotate: _editingBubble
                ? null
                : (degrees) => _updateBubble(
                      b.id,
                      (bubble) => bubble.copyWith(rotation: degrees.round()),
                    ),
          ),
      ];

  void _selectBubble(String id) {
    if (_focus == _DecorateFocus.bubble && _bubbleId == id) return;
    if (_editingBubble) _finishBubbleEdit();
    setState(() {
      _focus = _DecorateFocus.bubble;
      _bubbleId = id;
    });
  }

  /// First tap selects (the toolbar shows); a tap on the selected one types.
  void _tapBubble(String id) {
    if (_focus == _DecorateFocus.bubble && _bubbleId == id) {
      if (!_editingBubble) _startBubbleEdit(id);
      return;
    }
    _selectBubble(id);
  }

  void _updateBubble(String id, TogetherBubble Function(TogetherBubble) edit) {
    _bubbles = [
      for (final b in _bubbles) b.id == id ? edit(b) : b,
    ];
    _dragTick.value++;
  }

  /// Center stays on the card; the clip cuts whatever hangs past the edge.
  void _moveBubble(String id, double dx, double dy) {
    final size = _previewSize;
    _updateBubble(
      id,
      (b) => b.copyWith(
        x: (b.x + dx).clamp(-size.width / 2, size.width / 2),
        y: (b.y + dy).clamp(-size.height / 2, size.height / 2),
      ),
    );
  }

  /// Each tap adds one more bubble, a little apart from the last.
  Future<void> _addBubble() async {
    final t = AppStrings.current;
    if (!membershipController.hasPremiumContent) {
      await _showPremiumLock();
      return;
    }
    if (_bubbles.length >= TogetherBubble.maxCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.ddayDecorateBubbleLimit)),
      );
      return;
    }
    if (_editingBubble) _finishBubbleEdit();
    final n = _bubbles.length;
    final bubble = TogetherBubble(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      authorUid: authController.viewerUid,
      text: t.ddayDecorateBubbleDefault,
      x: -60.0 + 30 * n,
      y: 30.0 - 10 * n,
      tail: n.isEven ? TogetherBubbleTail.left : TogetherBubbleTail.right,
    );
    setState(() {
      _bubbles = [..._bubbles, bubble];
      _focus = _DecorateFocus.bubble;
      _bubbleId = bubble.id;
    });
    _dragTick.value++;
    _startBubbleEdit(bubble.id);
  }

  /// Types straight into the bubble: the bar under the preview takes the
  /// keys and the preview above it redraws each letter. All text starts
  /// selected, so the first key replaces the old words.
  void _startBubbleEdit(String id) {
    if (!membershipController.hasPremiumContent) {
      unawaited(_showPremiumLock());
      return;
    }
    final bubble = _bubbles.where((b) => b.id == id).firstOrNull;
    if (bubble == null) return;
    _bubbleCtrl.value = TextEditingValue(
      text: bubble.text,
      selection: TextSelection(baseOffset: 0, extentOffset: bubble.text.length),
    );
    setState(() {
      _focus = _DecorateFocus.bubble;
      _bubbleId = id;
      _editingBubble = true;
    });
    _dragTick.value++;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _editingBubble) _bubbleFocus.requestFocus();
    });
  }

  void _onBubbleTyped(String raw) {
    final id = _bubbleId;
    if (id == null) return;
    final text = TogetherBubble.clean(raw);
    // setState too: the letter count in the bar follows the text.
    setState(() {
      _updateBubble(
        id,
        (b) => b.copyWith(text: text, authorUid: authController.viewerUid),
      );
    });
  }

  /// Ends typing. An emptied bubble stays as a blank bubble.
  void _finishBubbleEdit() {
    if (!_editingBubble || !mounted) return;
    // Cleared first: unfocus calls back in here through the focus listener.
    _editingBubble = false;
    _bubbleFocus.unfocus();
    setState(() {});
    _dragTick.value++;
    unawaited(_persist());
  }

  void _flipBubbleTail(String id) {
    setState(() {
      _updateBubble(
        id,
        (b) => b.copyWith(
          tail: b.tail == TogetherBubbleTail.left
              ? TogetherBubbleTail.right
              : TogetherBubbleTail.left,
        ),
      );
    });
    unawaited(_persist());
  }

  void _stepBubbleScale(String id, int delta) {
    setState(() {
      _updateBubble(id, (b) => b.copyWith(scale: b.scale + delta));
    });
    unawaited(_persist());
  }

  Future<void> _pickBubbleColor(TogetherBubble bubble) async {
    final t = AppStrings.current;
    await showColorPaletteSheet(
      context,
      initialArgb: bubble.textColorOn(_textColor).toARGB32(),
      allowTransparent: false,
      title: t.ddayDecorateBubbleColor,
      // Applied on each tap, like the room text color.
      onChanged: (picked) {
        if (!mounted) return;
        setState(() {
          _updateBubble(bubble.id, (b) => b.copyWith(color: picked));
        });
        unawaited(_persist());
      },
    );
  }

  TogetherBubble? get _selectedBubble => _focus == _DecorateFocus.bubble
      ? _bubbles.where((b) => b.id == _bubbleId).firstOrNull
      : null;

  void _deleteBubble(String id) {
    setState(() {
      _bubbles = [for (final b in _bubbles) if (b.id != id) b];
      _bubbleId = null;
      _focus = _DecorateFocus.none;
    });
    _dragTick.value++;
    unawaited(_persist());
  }

  /// Replaces the drag hint while typing, right under the preview, so the
  /// bubble stays in sight above the keyboard.
  Widget _bubbleEditBar(Color accent) {
    final t = AppStrings.current;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _bubbleCtrl,
              focusNode: _bubbleFocus,
              maxLength: TogetherBubble.maxLength,
              textInputAction: TextInputAction.done,
              onChanged: _onBubbleTyped,
              onSubmitted: (_) => _finishBubbleEdit(),
              style: AppTheme.body.copyWith(
                fontFamily: 'Galmuri',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2C3340),
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: t.ddayDecorateBubbleTextHint,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                // Count sits inside the field so the bar stays one line.
                counterText: '',
                suffixText: '${_bubbleCtrl.text.length}'
                    '/${TogetherBubble.maxLength}',
                suffixStyle: AppTheme.body.copyWith(
                  fontFamily: 'Galmuri',
                  fontSize: 11,
                  color: AppColors.muted,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE4ECF7)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accent),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _finishBubbleEdit,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(
              t.ddayDecorateBubbleDone,
              style: AppTheme.body.copyWith(
                fontFamily: 'Galmuri',
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Actions for the selected bubble, fixed under the preview so they never
  /// cover the card. Taps on its gaps must not count as blank-space taps.
  Widget _bubbleToolsBar(TogetherBubble bubble) {
    final t = AppStrings.current;
    const ink = Color(0xFF2C3340);
    const faded = Color(0xFFB8C2D3);
    final numberStyle = AppTheme.body.copyWith(
      fontFamily: 'Galmuri',
      fontSize: 12,
      fontWeight: FontWeight.w800,
      color: ink,
    );

    Widget action(IconData icon, String label, VoidCallback onTap, Color color) {
      return Expanded(
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: _bubbleBarHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: color),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: numberStyle.copyWith(fontSize: 11, color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Small −/+ tap areas inside the size cell; the cell keeps the same
    // width as the other actions.
    Widget step(IconData icon, String tooltip, VoidCallback? onTap) {
      return Expanded(
        child: Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 26,
              child: Icon(icon, size: 18, color: onTap == null ? faded : ink),
            ),
          ),
        ),
      );
    }

    final sizeCell = Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: _bubbleBarHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  step(
                    Icons.remove_rounded,
                    t.ddayDecorateBubbleSmaller,
                    bubble.scale <= TogetherBubble.scaleMin
                        ? null
                        : () => _stepBubbleScale(
                              bubble.id,
                              -TogetherBubble.scaleStep,
                            ),
                  ),
                  step(
                    Icons.add_rounded,
                    t.ddayDecorateBubbleLarger,
                    bubble.scale >= TogetherBubble.scaleMax
                        ? null
                        : () => _stepBubbleScale(
                              bubble.id,
                              TogetherBubble.scaleStep,
                            ),
                  ),
                ],
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${bubble.scale}%',
                  maxLines: 1,
                  style: numberStyle.copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final colorCell = Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _pickBubbleColor(bubble),
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: _bubbleBarHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: bubble.textColorOn(_textColor),
                    shape: BoxShape.circle,
                    border: Border.all(color: faded),
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    t.ddayDecorateBubbleColor,
                    maxLines: 1,
                    style: numberStyle.copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            action(
              Icons.edit_rounded,
              t.ddayDecorateBubbleEdit,
              () => _startBubbleEdit(bubble.id),
              ink,
            ),
            const SizedBox(width: 6),
            action(
              Icons.swap_horiz_rounded,
              t.ddayDecorateBubbleDirection,
              () => _flipBubbleTail(bubble.id),
              ink,
            ),
            const SizedBox(width: 6),
            action(
              Icons.delete_outline_rounded,
              t.ddayDecorateBubbleDelete,
              () => _deleteBubble(bubble.id),
              const Color(0xFFE53935),
            ),
            const SizedBox(width: 6),
            sizeCell,
            const SizedBox(width: 6),
            colorCell,
          ],
        ),
      ),
    );
  }

  void _setDragging(bool value) {
    if (_dragging == value) return;
    setState(() => _dragging = value);
  }

  Future<void> _showPremiumLock() async {
    if (!mounted) return;
    final t = AppStrings.current;
    final palette = context.palette;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: palette.border, width: 1.5),
          ),
          title: Text(
            t.premiumLockedTitle,
            style: AppTheme.body.copyWith(
              fontFamily: 'Galmuri',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          content: SubscriptionPromptBody(
            message: t.premiumLockedDecorateBody,
            style: AppTheme.body.copyWith(
              fontFamily: 'Galmuri',
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                t.premiumLockedDismiss,
                style: AppTheme.body.copyWith(
                  fontFamily: 'Galmuri',
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                if (!await suggestSignInBeforePurchase(context) || !mounted) {
                  return;
                }
                await runMonthlySubscription(context);
              },
              child: Text(
                t.premiumLockedCta,
                style: AppTheme.body.copyWith(
                  fontFamily: 'Galmuri',
                  fontWeight: FontWeight.w900,
                  color: palette.accent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _bgChoice({
    required bool selected,
    required Color accent,
    required VoidCallback onTap,
    required Widget child,
    bool locked = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFFE8EEF6),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 3,
          ),
        ),
        clipBehavior: Clip.hardEdge,
        // Premium-only: just dimmed (no lock badge) so it reads as unavailable.
        child: Opacity(
          opacity: locked ? 0.42 : 1,
          child: child,
        ),
      ),
    );
  }

  /// Only blank space reaches this: buttons, the preview and fields win the tap.
  void _onBlankScreenTap() {
    if (_focus == _DecorateFocus.bubble || _editingBubble) _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onBlankScreenTap,
      child: _buildScreen(context),
    );
  }

  Widget _buildScreen(BuildContext context) {
    final t = AppStrings.current;
    final palette = context.palette;

    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: 'Galmuri'),
        primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Galmuri'),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontFamily: 'Galmuri'),
        child: Scaffold(
      backgroundColor: const Color(0xFFF3F7FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F7FD),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
        ),
        title: Text(
          t.ddayDuoDecorateTitle,
          style: AppTheme.body.copyWith(
            fontFamily: 'Galmuri',
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: palette.accent,
          ),
        ),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          ddayController,
          characterController,
          localeController,
          authController,
          membershipController,
          togetherEditing,
        ]),
        builder: (context, _) {
          final isPremium = membershipController.hasPremiumContent;
          final live = _room;
          final liveHasFriend = live?.hasFriend ?? false;
          final liveFriendId = live?.friendCharacterId;
          final draftCheer = _cheerCtrl.text.trim();
          final liveLabel = draftCheer.isNotEmpty
              ? draftCheer
              : (live?.latestCheer?.trim() ?? '');
          final previewSize = TogetherWidgetPreview.sizeForShape(
            _shape,
            _widgetSize,
            _hostSize,
            _hostForSize,
          );
          // Decorate stays pixel even when the rest of the app is clean.
          const isPixel = true;
          final charBase = _widgetSize.charFactor;

          // Preview is pinned above the scroll area so dragging never scrolls the page.
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                child: Column(
                  children: [
                    Center(
                      child: ValueListenableBuilder<int>(
                        valueListenable: _dragTick,
                        builder: (context, _, _) {
                          return TogetherWidgetPreview(
                            width: previewSize.width,
                            height: previewSize.height,
                            charW: charW * charBase,
                            charH: charH * charBase,
                            label: liveLabel,
                            labelListenable: _cheerDraft,
                            me: _meChar,
                            friend: liveHasFriend && liveFriendId != null
                                ? AppCharacter.byId(liveFriendId)
                                : null,
                            meX: _meX,
                            meY: _meY,
                            friendX: _friendX,
                            friendY: _friendY,
                            crowd: _crowdSprites(),
                            bubbles: _bubbleSprites(),
                            textX: _textX,
                            textY: _textY,
                            textRotation: _textRotation,
                            isPixel: isPixel,
                            meScale: _meScale,
                            friendScale: _friendScale,
                            textScale: _textScale,
                            bgColor: 0x00000000,
                            bgOpacity: 100,
                            bgAssetPath: WidgetAlbumBackground.resolvedAsset(
                              themeId: _bgThemeId,
                              roomId: widget.roomId,
                            ),
                            textColor: _textColor,
                            textFont: _textFont,
                            shape: _shape,
                            cornerRadius: _hostCornerDp,
                            onMePan: (_focus == _DecorateFocus.me ||
                                    (!liveHasFriend &&
                                        _focus == _DecorateFocus.friend))
                                ? _clampMe
                                : null,
                            onFriendPan: (liveHasFriend &&
                                    _focus == _DecorateFocus.friend)
                                ? _clampFriend
                                : null,
                            onTextPan: _focus == _DecorateFocus.text
                                ? _clampText
                                : null,
                            onTextRotate: _focus == _DecorateFocus.text
                                ? _rotateText
                                : null,
                            onTextSelect: _selectText,
                            onMeSelect: _selectMe,
                            onFriendSelect:
                                liveHasFriend ? _selectFriend : null,
                            highlightMe: _focus == _DecorateFocus.me,
                            highlightFriend: liveHasFriend &&
                                _focus == _DecorateFocus.friend,
                            highlightText: _focus == _DecorateFocus.text,
                            onBlankTap: _clearSelection,
                            onDragStart: () => _setDragging(true),
                            onDragEnd: () {
                              _setDragging(false);
                              _persist();
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Same height either way, so the list below never jumps.
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: _bubbleBarHeight,
                      ),
                      child: Center(
                        child: _editingBubble
                            ? _bubbleEditBar(palette.accent)
                            : _selectedBubble != null
                                ? _bubbleToolsBar(_selectedBubble!)
                                : Text(
                                    t.ddayDuoDecorateDragHint,
                                    textAlign: TextAlign.center,
                                    style: AppTheme.body.copyWith(
                                      fontFamily: 'Galmuri',
                                      fontSize: 12,
                                      color: AppColors.muted,
                                    ),
                                  ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Listener(
                  // Simulator pans can skip onPanEnd; never leave the list locked.
                  onPointerUp: (_) {
                    if (_dragging) _setDragging(false);
                  },
                  onPointerCancel: (_) {
                    if (_dragging) _setDragging(false);
                  },
                  child: ListView(
                  physics: _dragging
                      ? const NeverScrollableScrollPhysics()
                      : const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    _MemberPickGrid(
                      members: [
                        _RoomMember(
                          isMe: true,
                          assetPath: _meChar.assetPath,
                          nickname: _nicknameOr(
                            authController.nickname,
                            t.meLabel,
                          ),
                        ),
                        for (final friend in TogetherCrowdLayout.withoutMe(
                          live?.friends ?? const [],
                          myIds: authController.myIds,
                          myCharacterId: _meChar.id,
                        ))
                          _RoomMember(
                            friendUid: friend.uid,
                            editing: togetherEditing.isEditing(
                              widget.roomId,
                              friend.uid,
                            ),
                            assetPath: AppCharacter.byId(
                              friend.characterId,
                            ).assetPath,
                            nickname: _nicknameOr(
                              friend.displayName,
                              t.togetherFriendFallbackName,
                            ),
                          ),
                      ],
                      meSelected: _focus == _DecorateFocus.me,
                      selectedFriendUid: _focus == _DecorateFocus.friend
                          ? _pickedFriendUid
                          : null,
                      accent: palette.accent,
                      onTap: (member) {
                        if (member.isMe) {
                          _selectMe();
                        } else if (member.friendUid != null) {
                          _selectFriendMember(member.friendUid!);
                        }
                      },
                    ),
                    // My character for this room only (main pick is default).
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _pickMyCharacter,
                        icon: Icon(
                          Icons.swap_horiz_rounded,
                          size: 18,
                          color: palette.accent,
                        ),
                        label: Text(
                          t.ddayDecorateChangeMyCharacter,
                          style: AppTheme.body.copyWith(
                            fontFamily: 'Galmuri',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: palette.accent,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: palette.accent.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t.togetherCheerTitle,
                      style: AppTheme.body.copyWith(
            fontFamily: 'Galmuri',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: palette.accent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _cheerCtrl,
                      focusNode: _cheerFocus,
                      onTap: _clearSelection,
                      maxLength: 80,
                      maxLines: 3,
                      minLines: 2,
                      enabled: !_savingCheer && !_loggingIn,
                      style: AppTheme.body.copyWith(
            fontFamily: 'Galmuri',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2C3340),
                        height: 1.35,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: t.togetherCheerPlaceholder,
                        hintStyle: AppTheme.body.copyWith(
            fontFamily: 'Galmuri',
                          fontSize: 15,
                          color: const Color(0xFFB0B8C6),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE4ECF7)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE4ECF7)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: palette.accent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      t.ddayDecorateBgLabel,
                      style: AppTheme.body.copyWith(
            fontFamily: 'Galmuri',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: palette.accent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 72,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        // +1: the speech-bubble tile right after Transparent.
                        itemCount: TogetherBgTheme.choices.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          if (index == 1) {
                            return _bgChoice(
                              selected: _focus == _DecorateFocus.bubble,
                              accent: palette.accent,
                              locked: !isPremium,
                              onTap: isPremium ? _addBubble : _showPremiumLock,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TogetherBubbleView(
                                    text: '+',
                                    tail: TogetherBubbleTail.left,
                                    isPixel: false,
                                    textColor: Color(_textColor),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${t.ddayDecorateBubbleLabel} '
                                    '${_bubbles.length}/${TogetherBubble.maxCount}',
                                    textAlign: TextAlign.center,
                                    style: AppTheme.body.copyWith(
                                      fontFamily: 'Galmuri',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF5B6B8C),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          final theme =
                              TogetherBgTheme.choices[index == 0 ? 0 : index - 1];
                          final locked =
                              !isPremium && TogetherBgTheme.requiresPremium(theme);
                          return _bgChoice(
                            selected: _bgThemeId == theme.id,
                            accent: palette.accent,
                            locked: locked,
                            onTap: () {
                              if (locked) {
                                _showPremiumLock();
                                return;
                              }
                              _clearSelection();
                              setState(() => _bgThemeId = theme.id);
                              _persist();
                            },
                            child: theme.isNone
                                ? Center(
                                    child: Text(
                                      t.ddayDecorateBgNone,
                                      textAlign: TextAlign.center,
                                      style: AppTheme.body.copyWith(
                                        fontFamily: 'Galmuri',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF5B6B8C),
                                      ),
                                    ),
                                  )
                                : Image.asset(
                                    theme.assetPath,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    cacheWidth: (72 * MediaQuery.devicePixelRatioOf(context)).round(),
                                    gaplessPlayback: true,
                                    filterQuality: FilterQuality.none,
                                    isAntiAlias: false,
                                  ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      t.ddayDecorateFontLabel,
                      style: AppTheme.body.copyWith(
            fontFamily: 'Galmuri',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: palette.accent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: WidgetFont.values.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final font = WidgetFont.values[index];
                          final locked =
                              !isPremium && font.requiresPremium;
                          return _FontChip(
                            label: t.ddayDecorateFontName(font),
                            // Basic matches the pixel preview label.
                            fontFamily: font.family ?? 'Galmuri',
                            selected: _textFont == font,
                            accent: palette.accent,
                            locked: locked,
                            onTap: () {
                              if (locked) {
                                _showPremiumLock();
                                return;
                              }
                              if (_textFont == font) return;
                              _clearSelection();
                              setState(() => _textFont = font);
                              _dragTick.value++;
                              _persist();
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      t.ddayDecorateTextColorLabel,
                      style: AppTheme.body.copyWith(
            fontFamily: 'Galmuri',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: palette.accent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _textQuick.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          if (index == _textQuick.length) {
                            return _MoreColorsButton(
                              accent: palette.accent,
                              label: t.ddayDecorateMoreColors,
                              onTap: () async {
                                _clearSelection();
                                await showColorPaletteSheet(
                                  context,
                                  initialArgb: _textColor,
                                  allowTransparent: false,
                                  title: t.ddayDecorateTextColorLabel,
                                  // Applied on each tap, like the quick dots.
                                  onChanged: (picked) {
                                    if (!mounted) return;
                                    setState(() => _textColor = picked);
                                    _persist();
                                  },
                                );
                              },
                            );
                          }
                          final c = _textQuick[index];
                          return _ColorDot(
                            argb: c,
                            selected: _textColor == c,
                            transparent: false,
                            accent: palette.accent,
                            onTap: () {
                              _clearSelection();
                              setState(() => _textColor = c);
                              _persist();
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      t.ddayDecorateCharScaleFor(
                        _scaleMe || !liveHasFriend
                            ? _nicknameOr(authController.nickname, t.meLabel)
                            : _friendNickname(live, t),
                      ),
                      style: AppTheme.body.copyWith(
            fontFamily: 'Galmuri',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: palette.accent,
                      ),
                    ),
                    Slider(
                      value: (_scaleMe || !liveHasFriend
                              ? _meScale
                              : _scaleOf(_pickedFriendUid ?? ''))
                          .toDouble(),
                      min: DdayController.scaleMin.toDouble(),
                      max: DdayController.charScaleMax.toDouble(),
                      divisions:
                          DdayController.charScaleMax - DdayController.scaleMin,
                      label:
                          '${_scaleMe || !liveHasFriend ? _meScale : _scaleOf(_pickedFriendUid ?? '')}%',
                      onChanged: (v) {
                        setState(() {
                          if (_scaleMe || !liveHasFriend) {
                            _meScale = v.round();
                            // My size travels with the crowd too.
                            if (_placed.isNotEmpty) _crowdDirty = true;
                          } else {
                            _setFriendScale(v.round());
                          }
                          _fitCharacters();
                        });
                      },
                      onChangeEnd: (_) => _persist(),
                    ),
                    Text(
                      t.ddayDecorateTextScaleLabel,
                      style: AppTheme.body.copyWith(
            fontFamily: 'Galmuri',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: palette.accent,
                      ),
                    ),
                    Slider(
                      value: _textScale.toDouble(),
                      min: DdayController.scaleMin.toDouble(),
                      max: DdayController.scaleMax.toDouble(),
                      divisions:
                          DdayController.scaleMax - DdayController.scaleMin,
                      label: '$_textScale%',
                      onChanged: (v) {
                        setState(() => _textScale = v.round());
                      },
                      onChangeEnd: (_) => _persist(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: (_savingCheer || _loggingIn)
                            ? null
                            : () async {
                                final iosFirst =
                                    IosWidgetGuide.isIOS && !_widgetExported;
                                await _persist(
                                  applyToHome: true,
                                  toast: !iosFirst,
                                );
                                if (!context.mounted) return;
                                // iPhone cannot add the widget from the app:
                                // explain the steps on the first export.
                                if (iosFirst) {
                                  await IosWidgetGuide.show(
                                    context,
                                    widgetName:
                                        IosWidgetGuide.togetherWidgetName,
                                  );
                                  await TogetherGuide.markExportedWidget();
                                  _widgetExported = true;
                                  if (!context.mounted) return;
                                }
                                Navigator.of(context).maybePop();
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.accent,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          _loggingIn
                              ? t.togetherCheerLoggingIn
                              : _savingCheer
                                  ? t.togetherCheerSend
                                  : _firstExport
                                      ? t.ddayDuoDecorateExport
                                      : t.ddayDuoDecorateDone,
                          style: AppTheme.body.copyWith(
            fontFamily: 'Galmuri',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ],
          );
        },
      ),
        ),
      ),
    );
  }

}

/// Tap height of the selected-bubble bar under the preview.
const double _bubbleBarHeight = 48;

enum _DecorateFocus { none, me, friend, text, bubble }

class _RoomMember {
  const _RoomMember({
    required this.assetPath,
    required this.nickname,
    this.isMe = false,
    this.friendUid,
    this.editing = false,
  });

  final bool isMe;
  final String? friendUid;

  /// This friend has the decorator open right now.
  final bool editing;
  final String assetPath;
  final String nickname;
}

/// Room roster above the cheer field.
/// Chip width stays at the 5-across size. 1–5 people use one row;
/// 6 or more split into two rows (6→3+3, 7→4+3, 8→4+4, 9→5+4, 10→5+5).
class _MemberPickGrid extends StatelessWidget {
  const _MemberPickGrid({
    required this.members,
    required this.meSelected,
    required this.selectedFriendUid,
    required this.accent,
    required this.onTap,
  });

  final List<_RoomMember> members;
  final bool meSelected;
  final String? selectedFriendUid;
  final Color accent;
  final ValueChanged<_RoomMember> onTap;

  static int _rowCount(int count) {
    if (count <= 5) return count;
    return (count / 2).ceil();
  }

  bool _selected(_RoomMember member) {
    if (member.isMe) return meSelected;
    return selectedFriendUid != null && member.friendUid == selectedFriendUid;
  }

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 8.0;
          final cellW = (constraints.maxWidth - gap * 4) / 5;
          final perRow = _rowCount(members.length);
          final rows = <List<_RoomMember>>[];
          for (var i = 0; i < members.length; i += perRow) {
            final end = (i + perRow).clamp(0, members.length);
            rows.add(members.sublist(i, end));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var r = 0; r < rows.length; r++) ...[
                if (r > 0) const SizedBox(height: gap),
                Row(
                  children: [
                    for (var i = 0; i < rows[r].length; i++) ...[
                      if (i > 0) const SizedBox(width: gap),
                      SizedBox(
                        width: cellW,
                        child: _MemberChip(
                          member: rows[r][i],
                          selected: _selected(rows[r][i]),
                          accent: accent,
                          onTap: () => onTap(rows[r][i]),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({
    required this.member,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final _RoomMember member;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(2, 6, 2, 6),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? accent : const Color(0xFFE4ECF7),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            EditingDotsOverlay(
              editing: member.editing,
              child: Image.asset(
                member.assetPath,
                height: 44,
                fit: BoxFit.contain,
                cacheHeight:
                    (44 * MediaQuery.devicePixelRatioOf(context)).round(),
                gaplessPlayback: true,
                filterQuality: FilterQuality.none,
                isAntiAlias: false,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              member.nickname,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTheme.body.copyWith(
                fontFamily: 'Galmuri',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2C3340),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.argb,
    required this.selected,
    required this.transparent,
    required this.accent,
    required this.onTap,
  });

  final int argb;
  final bool selected;
  final bool transparent;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: transparent ? Colors.transparent : Color(argb),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? accent : const Color(0xFFE0E0E0),
            width: selected ? 2.5 : 1,
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: transparent
            ? CustomPaint(painter: _MiniCheckerPainter())
            : null,
      ),
    );
  }
}

/// One font option, drawn in its own typeface.
class _FontChip extends StatelessWidget {
  const _FontChip({
    required this.label,
    required this.fontFamily,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.locked = false,
  });

  final String label;
  final String? fontFamily;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: locked ? 0.42 : 1,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? accent : accent.withValues(alpha: 0.35),
              width: selected ? 2 : 1,
            ),
            color: selected
                ? accent.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 15,
                  color: selected ? accent : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreColorsButton extends StatelessWidget {
  const _MoreColorsButton({
    required this.accent,
    required this.label,
    required this.onTap,
  });

  final Color accent;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.55)),
          color: accent.withValues(alpha: 0.08),
        ),
        child: Text(
          label,
          style: AppTheme.body.copyWith(
            fontFamily: 'Galmuri',
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: accent,
          ),
        ),
      ),
    );
  }
}

class _MiniCheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const n = 4;
    final cell = size.width / n;
    final light = Paint()..color = const Color(0xFFE8E8E8);
    final dark = Paint()..color = const Color(0xFFBDBDBD);
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * cell, cell + 0.5, cell + 0.5),
          ((x + y).isEven) ? light : dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
