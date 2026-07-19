import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../utils/haptics.dart';

/// Read-only star display.
class StarDisplay extends StatelessWidget {
  final double rating;
  final double size;
  const StarDisplay({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.round();
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: AppColors.star,
        );
      }),
    );
  }
}

/// Interactive star input with a satisfying tap bounce.
class StarInput extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;
  const StarInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 40,
  });

  @override
  State<StarInput> createState() => _StarInputState();
}

class _StarInputState extends State<StarInput> {
  int? _tapped;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final star = i + 1;
        final filled = star <= widget.value;
        final icon = Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: widget.size,
          color: filled ? AppColors.star : AppColors.textSecondary,
        );
        return GestureDetector(
          onTap: () {
            Haptics.light();
            setState(() => _tapped = star);
            widget.onChanged(star);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _tapped == star
                ? icon.animate().scale(
                      duration: 260.ms,
                      curve: Curves.easeOutBack,
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1, 1),
                    )
                : icon,
          ),
        );
      }),
    );
  }
}
