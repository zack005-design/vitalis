import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Reusable iOS-styled text input field.
class AppTextField extends StatelessWidget {
  final String label;
  final String? placeholder;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool autofocus;

  const AppTextField({
    super.key,
    required this.label,
    this.placeholder,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.prefixIcon,
    this.suffix,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF171F33) : const Color(0xFFEFEFF4);
    final border = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: AppTypography.subhead(isDark).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            autofocus: autofocus,
            style: AppTypography.body(isDark),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: placeholder,
              hintStyle: AppTypography.body(isDark).copyWith(
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                  : null,
              suffixIcon: suffix,
            ),
          ),
        ),
      ],
    );
  }
}
