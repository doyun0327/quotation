import 'package:flutter/material.dart';
import 'package:quotation/data/character_controller.dart';
import 'package:quotation/data/dday_controller.dart';
import 'package:quotation/data/dday_friend_models.dart';
import 'package:quotation/data/home_widget_sync.dart';
import 'package:quotation/l10n/app_strings.dart';
import 'package:quotation/l10n/locale_controller.dart';
import 'package:quotation/theme/app_colors.dart';
import 'package:quotation/theme/app_palette.dart';
import 'package:quotation/theme/app_theme.dart';
import 'package:quotation/theme/visual_style_controller.dart';
import 'package:quotation/widgets/dday_pixel_icon.dart';

/// In-app editor for the D-Day duo home widget (positions only).
class DdayWidgetDecorateScreen extends StatefulWidget {
  const DdayWidgetDecorateScreen({super.key});

  @override
  State<DdayWidgetDecorateScreen> createState() =>
      _DdayWidgetDecorateScreenState();
}

class _DdayWidgetDecorateScreenState extends State<DdayWidgetDecorateScreen> {
  /// Matches `dday_widget_info.xml` minWidth / minHeight (4×2).
  static const previewWidth = 280.0;
  static const previewHeight = 120.0;
  static const charW = 112.0;
  static const charH = 148.0;

  late double _meX;
  late double _meY;
  late double _friendX;
  late double _friendY;

  @override
  void initState() {
    super.initState();
    _meX = ddayController.duoMeOffsetX.toDouble();
    _meY = ddayController.duoMeOffsetY.toDouble();
    _friendX = ddayController.duoFriendOffsetX.toDouble();
    _friendY = ddayController.duoFriendOffsetY.toDouble();
  }

  Future<void> _persist({bool toast = false}) async {
    await ddayController.setDuoOffsets(
      meX: _meX.round(),
      meY: _meY.round(),
      friendX: _friendX.round(),
      friendY: _friendY.round(),
    );
    await HomeWidgetSync.syncDday();
    if (toast && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.current.ddayDuoTestUpdatedToast)),
      );
    }
  }

  String _formatDate(DateTime date) {
    if (localeController.isKorean) {
      const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      final w = weekdays[date.weekday - 1];
      return '${date.year}. ${date.month.toString().padLeft(2, '0')}. '
          '${date.day.toString().padLeft(2, '0')} ($w)';
    }
    return '${date.year}. ${date.month.toString().padLeft(2, '0')}. '
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.current;
    final palette = context.palette;
    final item = ddayController.widgetDday;
    final title = item?.title ?? t.ddayDuoDecorateSampleTitle;
    final label = item?.label(korean: localeController.isKorean) ?? 'D-15';
    final date = item != null
        ? _formatDate(item.effectiveDate)
        : '2026. 11. 03 (화)';
    final hasFriend = item?.hasFriend ?? false;
    final friendChar = item?.friendCharacterId;

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
          final live = ddayController.widgetDday;
          final liveHasFriend = live?.hasFriend ?? false;
          final liveFriendId = live?.friendCharacterId;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Text(
                t.ddayDuoDecorateSubtitle,
                style: AppTheme.body.copyWith(
                  fontSize: 13,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                liveHasFriend
                    ? t.ddayInviteFriendCount(
                        live?.friendCount ?? 0,
                        DdayInviteLimits.maxFriends,
                      )
                    : t.ddayDecorateSoloHint,
                style: AppTheme.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.accent,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                t.ddayDuoDecoratePreview,
                style: AppTheme.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: _DuoWidgetPreview(
                  width: previewWidth,
                  height: previewHeight,
                  charW: charW,
                  charH: charH,
                  title: live?.title ?? title,
                  label: live?.label(korean: localeController.isKorean) ?? label,
                  date: live != null
                      ? _formatDate(live.effectiveDate)
                      : date,
                  me: characterController.character,
                  friend: liveHasFriend && liveFriendId != null
                      ? AppCharacter.byId(liveFriendId)
                      : null,
                  meX: _meX,
                  meY: _meY,
                  friendX: _friendX,
                  friendY: _friendY,
                  isPixel: visualStyleController.isPixel,
                  onMePan: liveHasFriend
                      ? (dx, dy) {
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
                      : null,
                  onFriendPan: liveHasFriend
                      ? (dx, dy) {
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
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                liveHasFriend
                    ? t.ddayDuoDecorateDragHint
                    : t.ddayDecorateSoloHint,
                textAlign: TextAlign.center,
                style: AppTheme.body.copyWith(
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
              if (!hasFriend && friendChar == null) ...[
                const SizedBox(height: 12),
                Text(
                  t.ddayDecorateInviteHint,
                  textAlign: TextAlign.center,
                  style: AppTheme.body.copyWith(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () async {
                    await _persist(toast: true);
                    if (!context.mounted) return;
                    Navigator.of(context).maybePop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.accent,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    t.ddayDuoDecorateDone,
                    style: AppTheme.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

typedef _PanDelta = void Function(double dx, double dy);

class _DuoWidgetPreview extends StatelessWidget {
  const _DuoWidgetPreview({
    required this.width,
    required this.height,
    required this.charW,
    required this.charH,
    required this.title,
    required this.label,
    required this.date,
    required this.me,
    required this.friend,
    required this.meX,
    required this.meY,
    required this.friendX,
    required this.friendY,
    required this.isPixel,
    required this.onMePan,
    required this.onFriendPan,
  });

  final double width;
  final double height;
  final double charW;
  final double charH;
  final String title;
  final String label;
  final String date;
  final AppCharacter me;
  final AppCharacter? friend;
  final double meX;
  final double meY;
  final double friendX;
  final double friendY;
  final bool isPixel;
  final _PanDelta? onMePan;
  final _PanDelta? onFriendPan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8C9B4), width: 1.5),
      ),
      clipBehavior: Clip.none,
      child: friend == null
          ? Row(
              children: [
                const SizedBox(width: 8),
                Image.asset(
                  me.assetPath,
                  width: charW * 0.85,
                  height: charH * 0.85,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PreviewTexts(
                    title: title,
                    label: label,
                    date: date,
                    centered: false,
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(
                        child: Container(
                          width: 132,
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFF8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF0E4DA)),
                          ),
                          child: _PreviewTexts(
                            title: title,
                            label: label,
                            date: date,
                            centered: true,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Transform.translate(
                          offset: const Offset(-66, 0),
                          child: isPixel
                              ? const DdayPixelIcon(
                                  kind: DdayIconKind.heart,
                                  size: 18,
                                )
                              : const Icon(
                                  Icons.favorite_rounded,
                                  size: 16,
                                  color: Color(0xFFF5A0B8),
                                ),
                        ),
                      ),
                      Positioned(
                        left: 4 + meX,
                        bottom: meY,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanUpdate: onMePan == null
                              ? null
                              : (d) => onMePan!(d.delta.dx, -d.delta.dy),
                          child: Image.asset(
                            me.assetPath,
                            width: charW,
                            height: charH,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 4 - friendX,
                        bottom: friendY,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanUpdate: onFriendPan == null
                              ? null
                              : (d) =>
                                  onFriendPan!(d.delta.dx, -d.delta.dy),
                          child: Image.asset(
                            friend!.assetPath,
                            width: charW,
                            height: charH,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 26,
                  color: const Color(0xFFCDE9C4),
                  alignment: Alignment.center,
                  child: const Text('❀', style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
    );
  }
}

class _PreviewTexts extends StatelessWidget {
  const _PreviewTexts({
    required this.title,
    required this.label,
    required this.date,
    required this.centered,
  });

  final String title;
  final String label;
  final String date;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final align = centered ? TextAlign.center : TextAlign.start;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: AppTheme.body.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF3A3F4A),
          ),
        ),
        Text(
          label,
          textAlign: align,
          style: AppTheme.body.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFF26B8A),
            height: 1.1,
          ),
        ),
        Text(
          date,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: AppTheme.body.copyWith(
            fontSize: 10,
            color: const Color(0xFF9AA3B2),
          ),
        ),
      ],
    );
  }
}
