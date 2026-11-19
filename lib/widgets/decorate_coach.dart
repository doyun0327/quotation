import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quotation/theme/app_theme.dart';

/// One coach mark of the first-time decorator tutorial.
///
/// Dims the screen and cuts a softly pulsing hole around [target], with a
/// hint card beside it. Touches pass through the dim layer, so the person
/// does the real thing (tap, slide, type) and the screen moves the tutorial
/// on; only the card's buttons are its own.
class DecorateCoach extends StatefulWidget {
  const DecorateCoach({
    super.key,
    required this.target,
    required this.step,
    required this.total,
    required this.title,
    required this.body,
    required this.skipLabel,
    required this.onSkip,
    required this.accent,
    this.doneLabel,
    this.onDone,
  });

  final GlobalKey target;

  /// 0-based; [total] dots, the ones up to [step] filled.
  final int step;
  final int total;
  final String title;
  final String body;
  final String skipLabel;
  final VoidCallback onSkip;
  final Color accent;

  /// A button on the card: "다음" for a step with nothing to do here, or the
  /// last card's button that ends the tutorial.
  final String? doneLabel;
  final VoidCallback? onDone;

  @override
  State<DecorateCoach> createState() => _DecorateCoachState();
}

class _DecorateCoachState extends State<DecorateCoach>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// Where the target is right now, in this layer's coordinates. Read every
  /// frame (the pulse rebuilds), so scrolling and the keyboard are followed.
  Rect? _targetRect() {
    final target = widget.target.currentContext?.findRenderObject();
    final layer = context.findRenderObject();
    if (target is! RenderBox || layer is! RenderBox) return null;
    if (!target.attached || !layer.attached || !target.hasSize) return null;
    final topLeft = layer.globalToLocal(target.localToGlobal(Offset.zero));
    return topLeft & target.size;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, box) {
            final rect = _targetRect();
            final grow = 6 + 4 * Curves.easeInOut.transform(_pulse.value);
            final hole = rect?.inflate(grow);
            final keyboard = MediaQuery.viewInsetsOf(context).bottom;
            final visibleBottom = box.maxHeight - keyboard;
            final cardW = math.min(box.maxWidth - 32, 360.0);
            // Below the hole when there is room, otherwise above it.
            final below =
                hole == null ||
                hole.bottom + 170 < visibleBottom ||
                hole.top < 190;
            return Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _HolePainter(hole: hole, ring: widget.accent),
                    ),
                  ),
                ),
                Positioned(
                  left: (box.maxWidth - cardW) / 2,
                  width: cardW,
                  top: hole == null
                      ? box.maxHeight * 0.35
                      : (below ? hole.bottom + 12 : null),
                  bottom: hole != null && !below
                      ? box.maxHeight - hole.top + 12
                      : null,
                  child: _card(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _card() {
    const ink = Color(0xFF2C3340);
    return Material(
      color: Colors.white,
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 0; i < widget.total; i++)
                  Container(
                    width: i == widget.step ? 16 : 7,
                    height: 7,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: i <= widget.step
                          ? widget.accent
                          : widget.accent.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.title,
              style: AppTheme.body.copyWith(
                fontFamily: 'Galmuri',
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: widget.accent,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                widget.body,
                style: AppTheme.body.copyWith(
                  fontFamily: 'Galmuri',
                  fontSize: 13,
                  height: 1.4,
                  color: ink,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Skip stays on every card but the last ("다음" cards too).
                if (widget.onDone == null || widget.step < widget.total - 1)
                  TextButton(
                    onPressed: widget.onSkip,
                    child: Text(
                      widget.skipLabel,
                      style: AppTheme.body.copyWith(
                        fontFamily: 'Galmuri',
                        fontSize: 12,
                        color: const Color(0xFF8A94A6),
                      ),
                    ),
                  ),
                if (widget.onDone != null)
                  TextButton(
                    onPressed: widget.onDone,
                    child: Text(
                      widget.doneLabel ?? 'OK',
                      style: AppTheme.body.copyWith(
                        fontFamily: 'Galmuri',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: widget.accent,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HolePainter extends CustomPainter {
  const _HolePainter({required this.hole, required this.ring});

  final Rect? hole;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Offset.zero & size;
    final dim = Paint()..color = const Color(0x8C000000);
    final target = hole;
    if (target == null) {
      canvas.drawRect(screen, dim);
      return;
    }
    final cut = RRect.fromRectAndRadius(target, const Radius.circular(14));
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(screen)
        ..addRRect(cut),
      dim,
    );
    canvas.drawRRect(
      cut,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_HolePainter old) => old.hole != hole || old.ring != ring;
}
