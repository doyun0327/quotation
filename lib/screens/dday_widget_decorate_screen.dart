import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/home_widget_sync.dart';
import 'package:quotation/data/together_bg_themes.dart';
import 'package:quotation/data/together_cheer_repository.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/theme/visual_style_controller.dart';
import 'package:quotation/widgets/color_palette_sheet.dart';
import 'package:quotation/widgets/together_widget_preview.dart';

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
    0xFF43A047,
    0xFF1E88E5,
  ];

  late double _meX;
  late double _meY;
  late double _friendX;
  late double _friendY;
  late double _textX;
  late double _textY;
  late int _meScale;
  late int _friendScale;
  late int _textScale;
  _DecorateFocus _focus = _DecorateFocus.me;
  bool _scaleMe = true;
  late String _bgThemeId;
  late int _textColor;
  late TogetherWidgetSize _widgetSize;
  Size? _hostSize;
  Timer? _cheerPush;
  TogetherWidgetSize? _hostForSize;
  double _hostCornerDp = TogetherWidgetSize.defaultCornerDp;
  bool _dragging = false;
  bool _savingCheer = false;
  final bool _loggingIn = false;

  final _cheerCtrl = TextEditingController();
  final _dragTick = ValueNotifier<int>(0);

  static const _shape = TogetherWidgetShape.square;

  @override
  void initState() {
    super.initState();
    unawaited(_loadHostSize());
    final id = widget.roomId;
    _meX = ddayController.meOffsetXForRoom(id).toDouble();
    _meY = ddayController.meOffsetYForRoom(id).toDouble();
    _friendX = ddayController.friendOffsetXForRoom(id).toDouble();
    _friendY = ddayController.friendOffsetYForRoom(id).toDouble();
    _textX = ddayController.textOffsetXForRoom(id).toDouble();
    _textY = ddayController.textOffsetYForRoom(id).toDouble();
    _meScale = ddayController.charScaleForRoom(id);
    _friendScale = ddayController.friendScaleForRoom(id);
    _textScale = ddayController.textScaleForRoom(id);
    _bgThemeId = ddayController.bgThemeForRoom(id);
    _textColor = ddayController.textColorForRoom(id);
    _widgetSize = TogetherWidgetSize.s42;
    _fitCharacters();
    final rooms = ddayController.items.where((e) => e.id == id);
    _cheerCtrl.text =
        rooms.isEmpty ? '' : (rooms.first.latestCheer?.trim() ?? '');
    _cheerCtrl.addListener(() {
      if (mounted) setState(() {});
      _scheduleCheerPush();
    });
  }

  Future<void> _loadHostSize() async {
    try {
      await HomeWidgetSync.syncDday();
    } catch (_) {}
    final host = await HomeWidgetSync.loadHostPreviewSize();
    if (!mounted || host == null) return;
    setState(() {
      _hostSize = host.size;
      _hostForSize = host.forSize;
      _hostCornerDp = host.cornerDp;
      _fitCharacters();
    });
  }

  void _scheduleCheerPush() {
    _cheerPush?.cancel();
    _cheerPush = Timer(const Duration(milliseconds: 350), () async {
      await ddayController.setRoomCheer(widget.roomId, _cheerCtrl.text);
      await HomeWidgetSync.syncDday();
    });
  }

  @override
  void dispose() {
    _cheerPush?.cancel();
    _cheerCtrl.dispose();
    _dragTick.dispose();
    super.dispose();
  }

  DdayItem? get _room {
    final matches =
        ddayController.items.where((e) => e.id == widget.roomId);
    return matches.isEmpty ? null : matches.first;
  }

  Future<bool> _saveCheerIfNeeded() async {
    final t = AppStrings.current;
    final text = _cheerCtrl.text.trim();
    final existing = _room?.latestCheer?.trim() ?? '';
    if (text.isEmpty || text == existing) return true;
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
    final message = switch (result.errorCode) {
      'not_signed_in' => t.togetherCheerNeedLogin,
      'permission' => t.togetherCheerPermission,
      _ => t.togetherCheerFailed,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    return false;
  }

  Future<void> _persist({bool applyToHome = false, bool toast = false}) async {
    if (applyToHome) {
      _cheerPush?.cancel();
      await ddayController.setRoomCheer(widget.roomId, _cheerCtrl.text);
      await HomeWidgetSync.syncDday();
      final cheerOk = await _saveCheerIfNeeded();
      if (!cheerOk) return;
    }
    await ddayController.setDuoOffsets(
      roomId: widget.roomId,
      meX: _meX.round(),
      meY: _meY.round(),
      friendX: _friendX.round(),
      friendY: _friendY.round(),
      textX: _textX.round(),
      textY: _textY.round(),
      charScale: _meScale,
      friendScale: _friendScale,
      textScale: _textScale,
      bgTheme: _bgThemeId,
      bgOpacity: 100,
      textColor: _textColor,
      shape: _shape,
      widgetSize: _widgetSize,
    );
    if (applyToHome) {
      await ddayController.applyRoomToHomeWidget(widget.roomId);
      final pinned =
          await HomeWidgetSync.syncAndOfferPinTogetherWidget();
      if (toast && mounted) {
        final t = AppStrings.current;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pinned ? t.togetherWidgetPinnedToast : t.togetherWidgetSyncToast,
            ),
          ),
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

  double _spriteW(int scale) =>
      charW * _widgetSize.charFactor * (scale / 100).clamp(0.6, 1.6);

  double _spriteH(int scale) =>
      charH * _widgetSize.charFactor * (scale / 100).clamp(0.6, 1.6);

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
    final friend = TogetherCharacterBounds.friend(
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
    if (_focus == _DecorateFocus.friend) return;
    setState(() {
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

  void _setDragging(bool value) {
    if (_dragging == value) return;
    setState(() => _dragging = value);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.current;
    final palette = context.palette;

    return Scaffold(
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
          visualStyleController,
          localeController,
        ]),
        builder: (context, _) {
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
          final isPixel = visualStyleController.isPixel;
          final charBase = _widgetSize.charFactor;

          // Preview is pinned above the scroll area so dragging never scrolls the page.
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                child: Column(
                  children: [
                    if (liveHasFriend) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            t.ddayInviteFriendCount(live?.friendCount ?? 0),
                            style: AppTheme.body.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: palette.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
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
                            me: characterController.character,
                            friend: liveHasFriend && liveFriendId != null
                                ? AppCharacter.byId(liveFriendId)
                                : null,
                            meX: _meX,
                            meY: _meY,
                            friendX: _friendX,
                            friendY: _friendY,
                            textX: _textX,
                            textY: _textY,
                            isPixel: isPixel,
                            meScale: _meScale,
                            friendScale: _friendScale,
                            textScale: _textScale,
                            bgColor: 0x00000000,
                            bgOpacity: 100,
                            bgAssetPath: () {
                              final theme =
                                  TogetherBgTheme.byId(_bgThemeId);
                              return theme.isNone ? null : theme.assetPath;
                            }(),
                            textColor: _textColor,
                            shape: _shape,
                            cornerRadius: _hostCornerDp,
                            onMePan: (_focus == _DecorateFocus.me ||
                                    (!liveHasFriend &&
                                        _focus != _DecorateFocus.text))
                                ? _clampMe
                                : null,
                            onFriendPan: (liveHasFriend &&
                                    _focus == _DecorateFocus.friend)
                                ? _clampFriend
                                : null,
                            onTextPan: _focus == _DecorateFocus.text
                                ? _clampText
                                : null,
                            onTextSelect: _selectText,
                            onMeSelect: _selectMe,
                            onFriendSelect:
                                liveHasFriend ? _selectFriend : null,
                            highlightMe: _focus == _DecorateFocus.me ||
                                (!liveHasFriend &&
                                    _focus != _DecorateFocus.text),
                            highlightFriend: liveHasFriend &&
                                _focus == _DecorateFocus.friend,
                            highlightText: _focus == _DecorateFocus.text,
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
                    Text(
                      t.ddayDuoDecorateDragHint,
                      textAlign: TextAlign.center,
                      style: AppTheme.body.copyWith(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    if (liveHasFriend) ...[
                      const SizedBox(height: 10),
                      _CharacterPickRow(
                        me: characterController.character,
                        friend: AppCharacter.byId(liveFriendId),
                        meLabel: t.ddayDecorateMeChip(
                          t.characterName(characterController.character.id),
                        ),
                        friendLabel: t.ddayDecorateFriendChip(
                          t.characterName(
                            liveFriendId ?? characterController.character.id,
                          ),
                        ),
                        selectedMe: _focus == _DecorateFocus.me,
                        selectedFriend: _focus == _DecorateFocus.friend,
                        accent: palette.accent,
                        onMe: _selectMe,
                        onFriend: _selectFriend,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  physics: _dragging
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    Text(
                      t.togetherCheerTitle,
                      style: AppTheme.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: palette.accent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _cheerCtrl,
                      maxLength: 80,
                      maxLines: 3,
                      minLines: 2,
                      enabled: !_savingCheer && !_loggingIn,
                      style: AppTheme.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2C3340),
                        height: 1.35,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: t.togetherCheerPlaceholder,
                        hintStyle: AppTheme.body.copyWith(
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
                        itemCount: TogetherBgTheme.all.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final theme = TogetherBgTheme.all[index];
                          return GestureDetector(
                            onTap: () {
                              setState(() => _bgThemeId = theme.id);
                              _persist();
                            },
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8EEF6),
                              ),
                              clipBehavior: Clip.hardEdge,
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
                                      fit: BoxFit.cover,
                                      filterQuality: FilterQuality.none,
                                      isAntiAlias: false,
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      t.ddayDecorateTextColorLabel,
                      style: AppTheme.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: palette.accent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final c in _textQuick)
                          _ColorDot(
                            argb: c,
                            selected: _textColor == c,
                            transparent: false,
                            accent: palette.accent,
                            onTap: () {
                              setState(() => _textColor = c);
                              _persist();
                            },
                          ),
                        _MoreColorsButton(
                          accent: palette.accent,
                          label: t.ddayDecorateMoreColors,
                          onTap: () async {
                            final picked = await showColorPaletteSheet(
                              context,
                              initialArgb: _textColor,
                              allowTransparent: false,
                              title: t.ddayDecorateTextColorLabel,
                            );
                            if (picked == null || !mounted) return;
                            setState(() => _textColor = picked);
                            _persist();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      t.ddayDecorateCharScaleFor(
                        _scaleMe || !liveHasFriend
                            ? t.ddayDecorateMeChip(
                                t.characterName(
                                  characterController.character.id,
                                ),
                              )
                            : t.ddayDecorateFriendChip(
                                t.characterName(liveFriendId ?? ''),
                              ),
                      ),
                      style: AppTheme.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: palette.accent,
                      ),
                    ),
                    Slider(
                      value: (_scaleMe || !liveHasFriend ? _meScale : _friendScale)
                          .toDouble(),
                      min: DdayController.scaleMin.toDouble(),
                      max: DdayController.scaleMax.toDouble(),
                      divisions:
                          DdayController.scaleMax - DdayController.scaleMin,
                      label:
                          '${_scaleMe || !liveHasFriend ? _meScale : _friendScale}%',
                      onChanged: (v) {
                        setState(() {
                          if (_scaleMe || !liveHasFriend) {
                            _meScale = v.round();
                          } else {
                            _friendScale = v.round();
                          }
                          _fitCharacters();
                        });
                      },
                      onChangeEnd: (_) => _persist(),
                    ),
                    Text(
                      t.ddayDecorateTextScaleLabel,
                      style: AppTheme.body.copyWith(
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
                                await _persist(
                                  applyToHome: true,
                                  toast: true,
                                );
                                if (!context.mounted) return;
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
                                  : t.ddayDuoDecorateDone,
                          style: AppTheme.body.copyWith(
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
            ],
          );
        },
      ),
    );
  }

}

enum _DecorateFocus { me, friend, text }

class _CharacterPickRow extends StatelessWidget {
  const _CharacterPickRow({
    required this.me,
    required this.friend,
    required this.meLabel,
    required this.friendLabel,
    required this.selectedMe,
    required this.selectedFriend,
    required this.accent,
    required this.onMe,
    required this.onFriend,
  });

  final AppCharacter me;
  final AppCharacter friend;
  final String meLabel;
  final String friendLabel;
  final bool selectedMe;
  final bool selectedFriend;
  final Color accent;
  final VoidCallback onMe;
  final VoidCallback onFriend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CharacterPick(
            character: me,
            label: meLabel,
            selected: selectedMe,
            accent: accent,
            onTap: onMe,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CharacterPick(
            character: friend,
            label: friendLabel,
            selected: selectedFriend,
            accent: accent,
            onTap: onFriend,
          ),
        ),
      ],
    );
  }
}

class _CharacterPick extends StatelessWidget {
  const _CharacterPick({
    required this.character,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final AppCharacter character;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFF8D6) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? accent : const Color(0xFFE0E0E0),
          width: selected ? 2.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Image.asset(
                character.assetPath,
                width: 28,
                height: 36,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                isAntiAlias: false,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2C3340),
                  ),
                ),
              ),
            ],
          ),
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
          borderRadius: BorderRadius.circular(6),
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
