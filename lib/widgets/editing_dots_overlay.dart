import 'package:flutter/material.dart';

/// Three bouncing "typing" dots above a room member's character while they
/// are decorating the shared widget.
class EditingDotsOverlay extends StatelessWidget {
  const EditingDotsOverlay({
    super.key,
    required this.editing,
    required this.child,
  });

  final bool editing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        child,
        if (editing)
          const Positioned(
            top: -10,
            child: _TypingDots(),
          ),
      ],
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  static const _dot = 5.0;
  static const _lift = 3.0;

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// 0→1→0 hop for dot [i]; each dot starts a third of a beat later.
  double _hop(int i) {
    final t = (_ctrl.value - i * 0.18) % 1.0;
    if (t > 0.5) return 0;
    final p = t / 0.5;
    return 1 - (2 * p - 1) * (2 * p - 1);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4ECF7)),
      ),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Transform.translate(
                offset: Offset(0, -_lift * _hop(i)),
                child: Container(
                  width: _dot,
                  height: _dot,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.55 + 0.45 * _hop(i)),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
