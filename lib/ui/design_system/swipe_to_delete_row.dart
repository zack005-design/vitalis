import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// Swipe-left-to-delete row wrapper backed by an explicit confirm/undo step.
class SwipeToDeleteRow extends StatelessWidget {
  final Widget child;
  final Key itemKey;
  final String title;
  final VoidCallback onDelete;
  final VoidCallback? onUndo;
  final String undoLabel;

  const SwipeToDeleteRow({
    super.key,
    required this.child,
    required this.itemKey,
    required this.title,
    required this.onDelete,
    this.onUndo,
    this.undoLabel = "Undo",
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: itemKey,
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        onDelete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "$title"'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: onUndo != null
                ? SnackBarAction(
                    label: undoLabel,
                    textColor: AppColors.calorieAccent,
                    onPressed: onUndo!,
                  )
                : null,
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.destructive,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
      child: child,
    );
  }
}
