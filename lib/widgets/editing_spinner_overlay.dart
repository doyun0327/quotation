import 'package:flutter/material.dart';

/// Small spinner over a room member's character while they are decorating
/// the shared widget.
class EditingSpinnerOverlay extends StatelessWidget {
  const EditingSpinnerOverlay({
    super.key,
    required this.editing,
    required this.child,
  });

  final bool editing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: editing ? 0.45 : 1,
          child: child,
        ),
        if (editing)
          Container(
            width: 26,
            height: 26,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE4ECF7)),
            ),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
      ],
    );
  }
}
