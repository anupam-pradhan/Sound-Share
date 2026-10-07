import 'package:flutter/material.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';

/// Shared card look so every surface on a screen has the same radius, border and depth.
class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  static Color borderColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2B293E)
          : AppColors.cardBorder;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.22)
                : AppColors.purple.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Small uppercase section heading with an optional trailing action.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: AppTextStyles.labelMedium.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Compact text action used in section headers ("Output", "Scan").
class SectionAction extends StatelessWidget {
  const SectionAction({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.leading,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  /// Custom leading widget (e.g. a spinner) shown instead of [icon].
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null)
              leading!
            else if (icon != null)
              Icon(icon, size: 16, color: AppColors.purple),
            if (leading != null || icon != null) const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.buttonMedium.copyWith(
                fontSize: 13,
                color: AppColors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
