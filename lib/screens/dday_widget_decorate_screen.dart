import 'package:flutter/material.dart';
import 'package:quotation/data/auth_controller.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/dday_friend_models.dart';
import 'package:quotation/data/home_widget_sync.dart';
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

  /// Quick picks (first = transparent). Full palette via "더 고르기".
  static const _bgQuick = <int>[
    0x00000000, // transparent
    0xFFFFF3E8,
    0xFFFFE4EC,
    0xFFE8F5E9,
    0xFFE3F2FD,
    0xFFFFF8E1,
    0xFFF3E5F5,
    0xFFFFFFFF,
  ];

  static const _textQuick = <int>[
    0xFFF26B8A,
    0xFFE85A7A,
    0xFFFF6F00,
    0xFF2C3340,
    0xFF5B6B8C,
    0xFF3D8B6E,
    0xFF5B7CFA,
    0xFF9C27B0,
    0xFF00BCD4,
    0xFFFFFFFF,
  ];

  late double _meX;
  late double _meY;
  late double _friendX;
  late double _friendY;
  late double _textX;
  late double _textY;
  late int _charScale;
  late int _textScale;
  late int _bgColor;
  late int _textColor;
  late TogetherWidgetSize _widgetSize;
  bool _dragging = false;
  bool _savingCheer = false;
  bool _loggingIn = false;

  final _cheerCtrl = TextEditingController();

  static const _shape = TogetherWidgetShape.square;

  @override
  void initState() {
    super.initState();
    final id = widget.roomId;
    _meX = ddayController.meOffsetXForRoom(id).toDouble();
    _meY = ddayController.meOffsetYForRoom(id).toDouble();
    _friendX = ddayController.friendOffsetXForRoom(id).toDouble();
    _friendY = ddayController.friendOffsetYForRoom(id).toDouble();
    _textX = ddayController.textOffsetXForRoom(id).toDouble();
    _textY = ddayController.textOffsetYForRoom(id).toDouble();
    _charScale = ddayController.charScaleForRoom(id);
    _textScale = ddayController.textScaleForRoom(id);
    // Bake legacy opacity % into ARGB once (slider removed).
    final rawBg = ddayController.bgColorForRoom(id);
    final legacyOp = ddayController.bgOpacityForRoom(id);
    if ((rawBg & 0xFF000000) != 0 && legacyOp < 100) {
      final c = Color(rawBg).withValues(alpha: (legacyOp / 100).clamp(0.0, 1.0));
      _bgColor = _colorToArgb(c);
    } else {
      _bgColor = rawBg;
    }
    _textColor = ddayController.textColorForRoom(id);
    _widgetSize = ddayController.widgetSizeForRoom(id);
    final rooms = ddayController.items.where((e) => e.id == id);
    _cheerCtrl.text =
        rooms.isEmpty ? '' : (rooms.first.latestCheer?.trim() ?? '');
    _cheerCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _cheerCtrl.dispose();
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

    final needsLogin = !authController.isSignedIn ||
        authController.user?.firebaseLinked != true;
    if (needsLogin) {
      setState(() => _loggingIn = true);
      final ok = await authController.ensureFirebaseSession();
      if (!mounted) return false;
      setState(() => _loggingIn = false);
      if (!ok) {
        final message = authController.lastError == 'canceled'
            ? t.googleLoginCanceled
            : t.togetherCheerNeedLogin;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return false;
      }
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
      charScale: _charScale,
      textScale: _textScale,
      bgColor: _bgColor,
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

  void _clampMe(double dx, double dy) {
    setState(() {
      _meX = (_meX + dx).clamp(
        DdayController.duoOffsetMinX.toDouble(),
        DdayController.duoOffsetMaxX.toDouble(),
      );
      _meY = (_meY + dy).clamp(
        DdayController.duoOffsetMinY.toDouble(),
        DdayController.duoOffsetMaxY.toDouble(),
      );
    });
    _persist();
  }

  void _clampFriend(double dx, double dy) {
    setState(() {
      _friendX = (_friendX + dx).clamp(
        DdayController.duoOffsetMinX.toDouble(),
        DdayController.duoOffsetMaxX.toDouble(),
      );
      _friendY = (_friendY + dy).clamp(
        DdayController.duoOffsetMinY.toDouble(),
        DdayController.duoOffsetMaxY.toDouble(),
      );
    });
    _persist();
  }

  void _clampText(double dx, double dy) {
    setState(() {
      _textX = (_textX + dx).clamp(
        DdayController.textOffsetMinX.toDouble(),
        DdayController.textOffsetMaxX.toDouble(),
      );
      _textY = (_textY + dy).clamp(
        DdayController.textOffsetMinY.toDouble(),
        DdayController.textOffsetMaxY.toDouble(),
      );
    });
    _persist();
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
          final cellDp = TogetherWidgetSize.cellDpForWidth(
            MediaQuery.sizeOf(context).width,
          );
          final previewSize = TogetherWidgetPreview.sizeForShape(
            _shape,
            _widgetSize,
            cellDp,
          );
          final isPixel = visualStyleController.isPixel;
          final charBase = _widgetSize.charFactor;

          // Preview is pinned above the scroll area so dragging never scrolls the page.
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: [
                    if (liveHasFriend) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          t.ddayInviteFriendCount(
                            live?.friendCount ?? 0,
                            DdayInviteLimits.maxFriends,
                          ),
                          style: AppTheme.body.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: palette.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    // No FittedBox — must stay exact Android widget dp (70×n−30).
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Center(
                        child: TogetherWidgetPreview(
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
                          charScale: _charScale,
                          textScale: _textScale,
                          bgColor: _bgColor,
                          bgOpacity: 100,
                          textColor: _textColor,
                          shape: _shape,
                          onMePan: _clampMe,
                          onFriendPan: liveHasFriend ? _clampFriend : null,
                          onTextPan: _clampText,
                          onDragStart: () => _setDragging(true),
                          onDragEnd: () => _setDragging(false),
                        ),
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
                      t.ddayDecorateSizeLabel,
                      style: AppTheme.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: palette.accent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final size in TogetherWidgetSize.values)
                          ChoiceChip(
                            label: Text(t.ddayDecorateSizeName(size.id)),
                            selected: _widgetSize == size,
                            onSelected: (_) {
                              setState(() => _widgetSize = size);
                              _persist();
                            },
                          ),
                      ],
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
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final c in _bgQuick)
                          _ColorDot(
                            argb: c,
                            selected: _isSameColor(_bgColor, c),
                            transparent: (c & 0xFF000000) == 0,
                            accent: palette.accent,
                            onTap: () {
                              setState(() => _bgColor = c);
                              _persist();
                            },
                          ),
                        _MoreColorsButton(
                          accent: palette.accent,
                          label: t.ddayDecorateMoreColors,
                          onTap: () async {
                            final picked = await showColorPaletteSheet(
                              context,
                              initialArgb: _bgColor,
                              allowTransparent: true,
                              title: t.ddayDecorateBgLabel,
                            );
                            if (picked == null || !mounted) return;
                            setState(() => _bgColor = picked);
                            _persist();
                          },
                        ),
                      ],
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
                      t.ddayDecorateCharScaleLabel,
                      style: AppTheme.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: palette.accent,
                      ),
                    ),
                    Slider(
                      value: _charScale.toDouble(),
                      min: DdayController.scaleMin.toDouble(),
                      max: DdayController.scaleMax.toDouble(),
                      divisions:
                          DdayController.scaleMax - DdayController.scaleMin,
                      label: '$_charScale%',
                      onChanged: (v) {
                        setState(() => _charScale = v.round());
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

  static bool _isSameColor(int a, int b) {
    final aClear = (a & 0xFF000000) == 0;
    final bClear = (b & 0xFF000000) == 0;
    if (aClear || bClear) return aClear && bClear;
    return (a & 0x00FFFFFF) == (b & 0x00FFFFFF);
  }

  static int _colorToArgb(Color c) {
    final a = (c.a * 255.0).round() & 0xff;
    final r = (c.r * 255.0).round() & 0xff;
    final g = (c.g * 255.0).round() & 0xff;
    final b = (c.b * 255.0).round() & 0xff;
    return (a << 24) | (r << 16) | (g << 8) | b;
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
          boxShadow: !transparent && (argb & 0x00FFFFFF) == 0x00FFFFFF
              ? const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 2),
                ]
              : null,
        ),
        child: transparent
            ? ClipOval(
                child: CustomPaint(painter: _MiniCheckerPainter()),
              )
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
