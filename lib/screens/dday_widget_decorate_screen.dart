import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:quotation/widgets/subscribe_flow.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:quotation/data/character_art_insets.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/home_widget_sync.dart';
import 'package:quotation/data/ios_fake_wallpaper.dart';
import 'package:quotation/data/membership_controller.dart';
import 'package:quotation/data/together_bg_themes.dart';
import 'package:quotation/data/sticker_unlock.dart';
import 'package:quotation/data/together_sticker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:quotation/widgets/ios_widget_guide.dart';
import 'package:quotation/widgets/sign_in_flow.dart';
import 'package:quotation/widgets/together_bubble_view.dart';
import 'package:quotation/widgets/decorate_coach.dart';
import 'package:quotation/widgets/together_widget_preview.dart';
import 'package:quotation/widgets/subscription_terms.dart';
import 'package:quotation/widgets/ios_transparent_guide.dart';

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

  /// The "applied to home" notice goes away when the app leaves the screen
  /// (the add-widget sheet, the launcher's widget list) and is not shown
  /// again on return.
  AppLifecycleListener? _noticeLife;
  ScaffoldMessengerState? _messenger;

  /// "Applied to home" notice from the last 홈에 적용. Shown once this screen
  /// has closed, so it stays its 3 seconds on the room screen.
  SnackBar? _homeNotice;

  // First-time tutorial (4 coach marks, then the "홈에 적용" pointer).
  static const _coachDoneKey = 'decorate_coach_done_v1';
  int? _coachStep;
  Timer? _coachTyping;
  final _coachPreviewKey = GlobalKey();
  final _coachCharScaleKey = GlobalKey();
  final _coachCheerKey = GlobalKey();
  final _coachTextScaleKey = GlobalKey();
  final _coachApplyKey = GlobalKey();

  /// Last touch or keystroke; the editor closes after [_idleLimit] without
  /// one so a forgotten screen does not keep friends locked out.
  DateTime _lastActivity = DateTime.now();
  Timer? _idleCheck;
  bool _closing = false;
  static const _idleLimit = Duration(minutes: 3);
  bool _savingCheer = false;
  final bool _loggingIn = false;

  final _cheerCtrl = TextEditingController();
  final _cheerDraft = ValueNotifier<String>('');
  final _cheerFocus = FocusNode();
  final _bubbleCtrl = TextEditingController();
  final _bubbleFocus = FocusNode();
  final _dragTick = ValueNotifier<int>(0);
  /// Last cheer pulled from the room. Local drafts stay until this changes
  /// (a friend save / apply), so bubble edits do not wipe typed home text.
  String _lastPulledCheer = '';
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
    _noticeLife = AppLifecycleListener(
      onHide: () => _messenger?.clearSnackBars(),
      onPause: () => _messenger?.clearSnackBars(),
    );
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
    final room = rooms.isEmpty ? null : rooms.first;
    _cheerCtrl.text = room?.latestCheer?.trim() ?? '';
    _cheerDraft.value = _cheerCtrl.text;
    _lastPulledCheer = _cheerCtrl.text.trim();
    _cheerCtrl.addListener(_onCheerEdited);
    // Typing cheer clears character / bubble selection on the preview.
    _cheerFocus.addListener(_onCheerFocusChanged);
    // Losing the keyboard focus some other way ends typing too.
    _bubbleFocus.addListener(() {
      if (!_bubbleFocus.hasFocus) _finishBubbleEdit();
    });
    _adoptCrowd();
    ddayController.addListener(_syncFromController);
    unawaited(_enterDecorate(migrateAlbum: migrateAlbum));
  }

  /// Claim the edit lock as soon as this screen opens (last step). If a
  /// friend already has it, leave with the busy message — the room screen
  /// itself never blocks.
  Future<void> _enterDecorate({required bool migrateAlbum}) async {
    if (_room?.friends.isNotEmpty ?? false) {
      final claim = await TogetherEditingPresence.claimLock(
        widget.roomId,
        myName: authController.nickname?.trim() ?? '',
      );
      if (!mounted) return;
      if (!claim.ok) {
        final name = claim.holderName.trim().isEmpty
            ? AppStrings.current.togetherFriendFallbackName
            : claim.holderName.trim();
        final message = AppStrings.current.decorateLockedBy(name);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_closeEditor(message));
        });
        return;
      }
    }
    unawaited(_loadIosWallpaper());
    await _syncAfterOpen(migrateAlbum: migrateAlbum);
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
    unawaited(_startCoachIfNeeded());
  }

  /// Holds the room edit lock while this screen is open.
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
    _lastActivity = DateTime.now();
    // Entry lock was already taken in [_enterDecorate]; heartbeat only renews.
    unawaited(_renewLock());
    _presenceBeat = Timer.periodic(TogetherEditingPresence.heartbeat, (_) {
      unawaited(_renewLock());
    });
    _idleCheck?.cancel();
    _idleCheck = Timer.periodic(const Duration(seconds: 15), (_) {
      if (DateTime.now().difference(_lastActivity) >= _idleLimit) {
        unawaited(_closeEditor(AppStrings.current.decorateIdleClosed));
      }
    });
  }

  /// Renews the room's edit lock. If a friend took it meanwhile (this phone
  /// was away longer than its lifetime), this editor closes instead of
  /// overwriting their work.
  Future<void> _renewLock() async {
    final claim = await TogetherEditingPresence.claimLock(
      widget.roomId,
      myName: authController.nickname?.trim() ?? '',
    );
    if (!mounted || _closing) return;
    if (!claim.ok) {
      final name = claim.holderName.trim().isEmpty
          ? AppStrings.current.togetherFriendFallbackName
          : claim.holderName.trim();
      await _closeEditor(AppStrings.current.decorateLockTaken(name));
    }
  }

  void _endPresence() {
    _idleCheck?.cancel();
    _idleCheck = null;
    // The lock was taken before this screen opened, so free it even when
    // the screen closes before the presence heartbeat started.
    if (_room?.friends.isNotEmpty ?? false) {
      unawaited(TogetherEditingPresence.releaseLock(widget.roomId));
    }
    if (_presenceBeat == null) return;
    _presenceBeat!.cancel();
    _presenceBeat = null;
  }

  void _touch() => _lastActivity = DateTime.now();

  /// Leaves the editor with [message]. What was changed is already saved on
  /// this phone; it reaches friends only when they press Apply.
  Future<void> _closeEditor(String message) async {
    if (_closing || !mounted) return;
    _closing = true;
    _endPresence();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await _persist();
    } catch (_) {}
    if (!mounted) return;
    await navigator.maybePop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
    // Room cheer unchanged → keep the typed draft (bubble persist notifies).
    if (cheer == _lastPulledCheer) return;
    _lastPulledCheer = cheer;
    if (_cheerCtrl.text == cheer) return;
    _applyingRemote = true;
    _cheerCtrl.text = cheer;
    _cheerDraft.value = cheer;
    _applyingRemote = false;
  }

  void _onCheerEdited() {
    if (_applyingRemote) return;
    _touch();
    final text = _cheerCtrl.text;
    if (_cheerDraft.value == text) return;
    _cheerDraft.value = text;
    // Tutorial step 3 moves on once typing pauses.
    if (_coachStep == 2 && text.trim().isNotEmpty) {
      _coachTyping?.cancel();
      _coachTyping = Timer(
        const Duration(milliseconds: 1200),
        () => _coachDone(2),
      );
    }
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
  }

  @override
  void dispose() {
    _noticeLife?.dispose();
    _coachTyping?.cancel();
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

  /// iPhone "투명" home photo (null until registered), shown in the preview.
  String? _iosWallpaperPath;

  Future<void> _loadIosWallpaper() async {
    if (!IosFakeWallpaper.isIOS) return;
    final path = await IosFakeWallpaper.currentPath();
    if (!mounted) return;
    if (path != null) {
      // The crop keeps its file name; drop the cached decode of the old one.
      unawaited(FileImage(File(path)).evict());
    }
    setState(() => _iosWallpaperPath = path);
  }

  /// "투명" picked with no home photo: the intro popup with the example.
  Future<void> _offerIosFakeWallpaper() async {
    if (!IosFakeWallpaper.isIOS || !mounted) return;
    final ok = await IosTransparentGuide.showIntro(context);
    if (ok) {
      await _loadIosWallpaper();
      await _persist();
    }
  }

  /// "변경하기": register a new home photo in place of the old one.
  Future<void> _changeIosWallpaper() async {
    final ok = await IosTransparentGuide.pickAndRegister(context);
    if (!ok) return;
    await _loadIosWallpaper();
    await _persist();
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
        _lastPulledCheer = _cheerCtrl.text.trim();
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
      final pin = await HomeWidgetSync.syncAndOfferPinTogetherWidget(
        roomId: widget.roomId,
        previousRoomId: previousRoom,
      );
      if (_samsung && !_widgetExported) {
        await TogetherGuide.markExportedWidget();
        _widgetExported = true;
      }
      // The launcher may still list a widget the user already removed, so
      // "already on home" offers an add button instead of assuming it.
      final onHome = pin == TogetherPinResult.alreadyOnHome;
      if (((toast && cheerOk) || onHome) && mounted) {
        final t = AppStrings.current;
        // Galaxy gets the add button (its launcher can lose the widget);
        // iPhone and other phones just get the confirmation.
        final offerAdd = _samsung;
        final messenger = ScaffoldMessenger.of(context);
        final roomId = widget.roomId;
        _homeNotice =
          SnackBar(
            // Always two lines on any screen width: each line keeps its own
            // break and shrinks to fit instead of wrapping to a third.
            content: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                offerAdd
                    ? t.togetherWidgetOnHomeBody
                    : t.togetherWidgetOnHomeShort,
                maxLines: 2,
                softWrap: false,
              ),
            ),
            duration: const Duration(seconds: 3),
            // A snackbar with an action stays until tapped unless told not to.
            persist: false,
            action: offerAdd
                ? SnackBarAction(
                    label: t.togetherWidgetOnHomeAdd,
                    onPressed: () {
                      // The add-widget sheet takes over; the notice is done.
                      messenger.hideCurrentSnackBar();
                      unawaited(
                        HomeWidgetSync.syncAndOfferPinTogetherWidget(
                          roomId: roomId,
                          force: true,
                        ),
                      );
                    },
                  )
                : null,
          );
      }
      return;
    }
    await HomeWidgetSync.syncDday();
    if (toast && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.current.ddayDuoTestUpdatedToast),
          duration: const Duration(seconds: 3),
        ),
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
        // Blocked friends are not drawn; their slot stays in the layout.
        if (!blockedUsersController.isBlocked(person.uid))
        TogetherPreviewSprite(
          keyId: person.uid,
          isMe: person.uid == myUid,
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
    if (_focus != _DecorateFocus.me) {
      setState(() {
        _focus = _DecorateFocus.me;
        _scaleMe = true;
      });
    }
    _coachDone(0);
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

  /// Paid subscription or the share unlock. The free trial does not count.
  bool get _canUseStickers =>
      membershipController.isPremium || stickerUnlock.unlocked;

  /// A friend's sticker shows here too, but only someone who opened the
  /// stickers may move, size or remove it.
  bool _locksBubble(TogetherBubble b) => b.isSticker && !_canUseStickers;

  List<TogetherPreviewBubble> _bubbleSprites() => [
        for (final b in blockedUsersController.visibleBubbles(
          widget.roomId,
          _bubbles,
        ))
          if (_locksBubble(b))
            TogetherPreviewBubble(
              bubble: b,
              onSelect: _showStickerLocked,
              onEdit: _showStickerLocked,
            )
          else
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

  void _showStickerLocked() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppStrings.current.stickerLockedEdit)),
      );
  }

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
    final isSticker = _bubbles.any((b) => b.id == id && b.isSticker);
    if (_focus == _DecorateFocus.bubble && _bubbleId == id) {
      if (isSticker) return;
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
    // Speech bubbles are free for everyone.
    if (_wordBubbleCount >= TogetherBubble.maxCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.ddayDecorateBubbleLimit)),
      );
      return;
    }
    if (_editingBubble) _finishBubbleEdit();
    final n = _wordBubbleCount;
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

  int get _wordBubbleCount => _bubbles.where((b) => !b.isSticker).length;

  /// Each tap on a sticker tile adds one more of it, a little apart from the
  /// last, and selects it so it can be moved, sized or removed.
  void _addSticker(TogetherStickerStyle style) {
    final t = AppStrings.current;
    final stickers = _bubbles.where((b) => b.isSticker).length;
    if (stickers >= TogetherBubble.maxStickers) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(t.ddayDecorateStickerLimit)));
      return;
    }
    if (_editingBubble) _finishBubbleEdit();
    final sticker = TogetherBubble(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      authorUid: authController.viewerUid,
      text: '',
      sticker: style.id,
      x: -40.0 + 20 * (stickers % 5),
      y: -10.0 + 8 * (stickers % 5),
    );
    setState(() {
      _bubbles = [..._bubbles, sticker];
      _focus = _DecorateFocus.bubble;
      _bubbleId = sticker.id;
    });
    _dragTick.value++;
    unawaited(_persist());
  }

  /// Types straight into the bubble: the bar under the preview takes the
  /// keys and the preview above it redraws each letter. All text starts
  /// selected, so the first key replaces the old words.
  void _startBubbleEdit(String id) {
    final bubble = _bubbles.where((b) => b.id == id).firstOrNull;
    if (bubble == null || bubble.isSticker) return;
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
            // A sticker is a picture: no words, tail or text color.
            if (!bubble.isSticker) ...[
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
            ],
            action(
              Icons.delete_outline_rounded,
              t.ddayDecorateBubbleDelete,
              () => _deleteBubble(bubble.id),
              const Color(0xFFE53935),
            ),
            const SizedBox(width: 6),
            sizeCell,
            if (!bubble.isSticker) ...[
              const SizedBox(width: 6),
              colorCell,
            ],
          ],
        ),
      ),
    );
  }

  void _setDragging(bool value) {
    if (_dragging == value) return;
    setState(() => _dragging = value);
  }

  /// Free users: share Dearly's store link with a friend to open the
  /// stickers for good. True once they are open.
  Future<bool> _offerStickerShare() async {
    final t = AppStrings.current;
    final share = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.stickerShareTitle),
        content: Text(t.stickerShareBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t.stickerShareAction),
          ),
        ],
      ),
    );
    if (share != true || !mounted) return false;
    final result = await SharePlus.instance.share(
      ShareParams(text: t.stickerShareText(DearlyStoreLinks.forThisPhone)),
    );
    // Android often cannot tell whether it was sent ("unavailable"); only a
    // sheet closed without picking an app is left out.
    if (result.status == ShareResultStatus.dismissed) return false;
    await stickerUnlock.unlock();
    if (!mounted) return true;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(t.stickerShareUnlocked)));
    return true;
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
        // Premium-only: heavily faded (no lock badge) so it reads as unavailable.
        child: Opacity(
          opacity: locked ? 0.22 : 1,
          child: child,
        ),
      ),
    );
  }

  /// Only blank space reaches this: buttons, the preview and fields win the tap.
  void _onBlankScreenTap() {
    if (_focus == _DecorateFocus.bubble || _editingBubble) _clearSelection();
  }

  /// First open after install: walk through the four basics once.
  Future<void> _startCoachIfNeeded() async {
    if (!mounted || _closing || _coachStep != null) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_coachDoneKey) ?? false) return;
    if (!mounted || _closing) return;
    setState(() => _coachStep = 0);
  }

  GlobalKey? _coachTarget(int? step) => switch (step) {
        0 => _coachPreviewKey,
        1 => _coachCharScaleKey,
        2 => _coachCheerKey,
        3 => _coachTextScaleKey,
        4 => _coachApplyKey,
        _ => null,
      };

  /// [step] was done for real: show the next one and scroll it into view.
  void _coachDone(int step) {
    if (_coachStep != step || !mounted) return;
    _coachTyping?.cancel();
    setState(() => _coachStep = step + 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _coachTarget(_coachStep)?.currentContext;
      if (target == null || !mounted) return;
      unawaited(Scrollable.ensureVisible(
        target,
        alignment: 0.5,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      ));
    });
  }

  Future<void> _finishCoach() async {
    _coachTyping?.cancel();
    if (mounted) setState(() => _coachStep = null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_coachDoneKey, true);
  }

  Widget _coachLayer() {
    final t = AppStrings.current;
    final step = _coachStep ?? 0;
    final target = _coachTarget(step) ?? _coachPreviewKey;
    final (title, body) = switch (step) {
      0 => (t.coachPickTitle, t.coachPickBody),
      1 => (t.coachSizeTitle, t.coachSizeBody),
      2 => (t.coachTextTitle, t.coachTextBody),
      3 => (t.coachTextSizeTitle, t.coachTextSizeBody),
      _ => (t.coachDoneTitle, t.coachDoneBody),
    };
    return DecorateCoach(
      target: target,
      step: step.clamp(0, 3),
      total: 4,
      title: title,
      body: body,
      skipLabel: t.coachSkip,
      onSkip: _finishCoach,
      accent: context.palette.accent,
      doneLabel: step >= 4 ? t.coachDoneButton : null,
      onDone: step >= 4 ? _finishCoach : null,
    );
  }

  /// Leaving with back (the app bar arrow or the system gesture) keeps
  /// everything on screen at that moment, on this phone only: cheer words,
  /// bubbles mid-typing, positions, colors. "홈에 적용" is what shares it.
  Future<void> _saveLocallyOnLeave() async {
    // Typed letters are already in the bubble; just stop typing.
    _editingBubble = false;
    try {
      await ddayController.setRoomCheer(widget.roomId, _cheerCtrl.text);
      await _persist();
    } catch (e) {
      debugPrint('decorate save on leave: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) unawaited(_saveLocallyOnLeave());
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onBlankScreenTap,
        child: Stack(
          children: [
            _buildScreen(context),
            if (_coachStep != null) Positioned.fill(child: _coachLayer()),
          ],
        ),
      ),
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
        // Any touch counts as activity for the 3-minute idle close.
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _touch(),
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
      // A drag that ends anywhere (simulator pans can skip onPanEnd)
      // must unlock the list, not only a pointer-up inside it.
      body: Listener(
        onPointerUp: (_) {
          if (_dragging) _setDragging(false);
        },
        onPointerCancel: (_) {
          if (_dragging) _setDragging(false);
        },
        child: ListenableBuilder(
        listenable: Listenable.merge([
          ddayController,
          characterController,
          localeController,
          authController,
          membershipController,
          stickerUnlock,
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
                            key: _coachPreviewKey,
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
                            iosWallpaperPath: _iosWallpaperPath,
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
                            : _selectedBubble != null &&
                                    !_locksBubble(_selectedBubble!)
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
                  scrollCacheExtent: const ScrollCacheExtent.pixels(4000),
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
                          if (!blockedUsersController.isBlocked(friend.uid))
                          _RoomMember(
                            friendUid: friend.uid,
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
                      // Pencil on my card: my character for this room only.
                      onEditMe: _pickMyCharacter,
                      editLabel: t.ddayDecorateChangeMyCharacter,
                    ),
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
                      key: _coachCheerKey,
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
                        // Transparent, the speech-bubble tile, the stickers,
                        // then the backgrounds.
                        itemCount: TogetherBgTheme.choices.length +
                            1 +
                            TogetherSticker.styles.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          if (index == 1) {
                            return _bgChoice(
                              selected: _selectedBubble != null &&
                                  !_selectedBubble!.isSticker,
                              accent: palette.accent,
                              // Bubbles are free for everyone.
                              locked: false,
                              onTap: _addBubble,
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
                                    '$_wordBubbleCount/${TogetherBubble.maxCount}',
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
                          final linkCount = TogetherSticker.styles.length;
                          if (index >= 2 && index < 2 + linkCount) {
                            final style = TogetherSticker.styles[index - 2];
                            // Paid subscribers right away; everyone else
                            // (free trial included) once they shared Dearly
                            // with a friend (kept for good).
                            final locked = !_canUseStickers;
                            final placed = _bubbles
                                .where((b) => b.sticker == style.id)
                                .length;
                            return _bgChoice(
                              // Every sticker kind on the card stays lit, so
                              // several can be picked at once.
                              selected: placed > 0,
                              accent: palette.accent,
                              locked: locked,
                              onTap: () async {
                                if (locked) {
                                  if (await _offerStickerShare() && mounted) {
                                    _addSticker(style);
                                  }
                                  return;
                                }
                                _addSticker(style);
                              },
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Image.asset(
                                        style.asset,
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.medium,
                                      ),
                                    ),
                                  ),
                                  if (placed > 0)
                                    Positioned(
                                      right: 3,
                                      top: 3,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: palette.accent,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '$placed',
                                          style: AppTheme.body.copyWith(
                                            fontFamily: 'Galmuri',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }
                          final theme = TogetherBgTheme.choices[
                              index == 0 ? 0 : index - 1 - linkCount];
                          final locked =
                              !isPremium && TogetherBgTheme.requiresPremium(theme);
                          return _bgChoice(
                            selected: _bgThemeId == theme.id,
                            accent: palette.accent,
                            locked: locked,
                            onTap: () async {
                              if (locked) {
                                _showPremiumLock();
                                return;
                              }
                              _clearSelection();
                              setState(() => _bgThemeId = theme.id);
                              _persist();
                              // iPhone: no home photo yet → explain and offer to add.
                              if (theme.isNone &&
                                  IosFakeWallpaper.isIOS &&
                                  _iosWallpaperPath == null) {
                                await _offerIosFakeWallpaper();
                              }
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
                    // iPhone, "투명" picked: the home photo + change button.
                    if (IosFakeWallpaper.isIOS &&
                        _bgThemeId == TogetherBgTheme.none.id) ...[
                      const SizedBox(height: 12),
                      IosTransparentSetting(
                        photoPath: _iosWallpaperPath,
                        onChange: () => unawaited(_changeIosWallpaper()),
                      ),
                    ],
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
                      key: _coachCharScaleKey,
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
                      onChangeEnd: (_) {
                        _persist();
                        if (_scaleMe || !liveHasFriend) _coachDone(1);
                      },
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
                      key: _coachTextScaleKey,
                      value: _textScale.toDouble(),
                      min: DdayController.scaleMin.toDouble(),
                      max: DdayController.scaleMax.toDouble(),
                      divisions:
                          DdayController.scaleMax - DdayController.scaleMin,
                      label: '$_textScale%',
                      onChanged: (v) {
                        setState(() => _textScale = v.round());
                      },
                      onChangeEnd: (_) {
                        _persist();
                        _coachDone(3);
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      key: _coachApplyKey,
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
                                final notice = _homeNotice;
                                _homeNotice = null;
                                final messenger = ScaffoldMessenger.of(context);
                                await Navigator.of(context).maybePop();
                                // On the room screen now: only the latest
                                // notice, never a queue of repeats.
                                if (notice != null) {
                                  messenger
                                    ..clearSnackBars()
                                    ..showSnackBar(notice);
                                }
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
  });

  final bool isMe;
  final String? friendUid;
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
    required this.onEditMe,
    required this.editLabel,
  });

  final List<_RoomMember> members;
  final bool meSelected;
  final String? selectedFriendUid;
  final Color accent;
  final ValueChanged<_RoomMember> onTap;

  /// The pencil on my card.
  final VoidCallback onEditMe;
  final String editLabel;

  /// Two across for 1-2 people, three across from 3 on (wrapping).
  static int _perRow(int count) => count <= 2 ? 2 : 3;

  bool _selected(_RoomMember member) {
    if (member.isMe) return meSelected;
    return selectedFriendUid != null && member.friendUid == selectedFriendUid;
  }

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 12.0;
          final perRow = _perRow(members.length);
          final cellW = (constraints.maxWidth - gap * (perRow - 1)) / perRow;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final member in members)
                SizedBox(
                  width: cellW,
                  child: _MemberChip(
                    member: member,
                    selected: _selected(member),
                    accent: accent,
                    onTap: () => onTap(member),
                    onEdit: member.isMe ? onEditMe : null,
                    editLabel: editLabel,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// One person as a tall rounded card: character, then nickname. My card
/// carries a round pencil button that changes my character for this room.
class _MemberChip extends StatelessWidget {
  const _MemberChip({
    required this.member,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.onEdit,
    this.editLabel = '',
  });

  final _RoomMember member;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final String editLabel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 0.68,
        child: LayoutBuilder(
          builder: (context, box) {
            final charH = box.maxHeight * 0.34;
            final nameSize = (box.maxWidth * 0.11).clamp(11.0, 18.0);
            final pen = (box.maxWidth * 0.26).clamp(28.0, 40.0);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(box.maxWidth * 0.12),
                border: Border.all(
                  color: selected ? accent : const Color(0xFFE4ECF7),
                  width: selected ? 2.5 : 1.5,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: box.maxHeight * 0.06),
                        Image.asset(
                          member.assetPath,
                          height: charH,
                          fit: BoxFit.contain,
                          cacheHeight: (charH *
                                  MediaQuery.devicePixelRatioOf(context))
                              .round(),
                          gaplessPlayback: true,
                          filterQuality: FilterQuality.none,
                          isAntiAlias: false,
                        ),
                        SizedBox(height: box.maxHeight * 0.06),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            member.nickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppTheme.body.copyWith(
                              fontFamily: 'Galmuri',
                              fontSize: nameSize,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2C3340),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onEdit != null)
                    Positioned(
                      top: box.maxWidth * 0.07,
                      right: box.maxWidth * 0.07,
                      child: Semantics(
                        button: true,
                        label: editLabel,
                        child: Material(
                          // Same theme accent as the rest of the decorator
                          // (selected border, buttons), at full strength.
                          color: accent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onEdit,
                            child: SizedBox(
                              width: pen,
                              height: pen,
                              child: Icon(
                                Icons.edit_rounded,
                                size: pen * 0.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
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
        opacity: locked ? 0.22 : 1,
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
