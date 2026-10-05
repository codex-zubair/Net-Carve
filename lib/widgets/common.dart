import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// A small heading used above groups of content.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textFaint,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// A copy-to-clipboard text value shown in monospace.
class CopyText extends StatelessWidget {
  const CopyText({
    super.key,
    required this.value,
    this.display,
    this.size = 14,
    this.color = AppColors.text,
    this.bold = false,
  });

  final String value;
  final String? display;
  final double size;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final shown = display ?? value;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              width: 280,
              duration: const Duration(milliseconds: 900),
              backgroundColor: AppColors.surfaceTop,
              content: Row(
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Copied  $value',
                      style: AppTheme.mono(size: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                shown,
                style: AppTheme.mono(
                  size: size,
                  color: color,
                  weight: bold ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.copy_rounded,
              size: 13,
              color: AppColors.textFaint,
            ),
          ],
        ),
      ),
    );
  }
}

/// A label/value row used inside result cards.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = AppColors.text,
    this.valueSize = 14,
    this.copyable = true,
  });

  final String label;
  final String value;
  final Color valueColor;
  final double valueSize;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: copyable
                  ? CopyText(value: value, color: valueColor, size: valueSize)
                  : Text(
                      value,
                      style: AppTheme.mono(size: valueSize, color: valueColor),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A pill badge, e.g. "Private" or "Class C".
class InfoBadge extends StatelessWidget {
  const InfoBadge(this.text, {super.key, this.color = AppColors.accent});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// A surface card with a consistent look.
class PanelCard extends StatelessWidget {
  const PanelCard({super.key, required this.child, this.padding = 16});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: child,
    );
  }
}

/// Formats large integers with thin separators for readability.
String formatCount(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
