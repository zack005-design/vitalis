import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Translucent Stitch-style segmented pill control.
class SegmentedControl<T> extends StatelessWidget {
  final Map<T, String> options;
  final T selectedValue;
  final ValueChanged<T> onValueChanged;

  const SegmentedControl({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF131B2E) : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: options.entries.map((entry) {
          final isSelected = entry.key == selectedValue;

          return Expanded(
            child: Semantics(
              button: true,
              selected: isSelected,
              label: entry.value,
              hint: isSelected ? 'Selected' : 'Double tap to select ${entry.value}',
              child: GestureDetector(
                onTap: () {
                  if (!isSelected) {
                    HapticFeedback.selectionClick();
                    onValueChanged(entry.key);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? const Color(0xFF222A3E) : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontFamily: AppTypography.jetBrainsMonoFontFamily,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? Colors.white : AppColors.primaryBlue)
                            : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
