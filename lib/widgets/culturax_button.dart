import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Primary gold button.
class CulturaXButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final bool loading;

  const CulturaXButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = loading
        ? const SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppColors.bg)))
        : icon != null
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 18), const SizedBox(width: 8),
                Text(label, style: AppTextStyles.button),
              ])
            : Text(label, style: AppTextStyles.button);

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.bg,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
        child: child,
      ),
    );
  }
}

/// Outlined secondary button.
class CulturaXOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final Color? color;

  const CulturaXOutlinedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.gold;
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: c,
          side: BorderSide(color: c, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
        child: icon != null
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 18, color: c), const SizedBox(width: 8),
                Text(label, style: AppTextStyles.buttonOutline.copyWith(color: c)),
              ])
            : Text(label, style: AppTextStyles.buttonOutline.copyWith(color: c)),
      ),
    );
  }
}
