import 'package:flutter/material.dart';

enum BannerType { info, warning, error, success }

class InfoBanner extends StatelessWidget {
  final String message;
  final BannerType type;
  final IconData? icon;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionLabel;

  const InfoBanner({
    super.key,
    required this.message,
    this.type = BannerType.info,
    this.icon,
    this.onDismiss,
    this.onAction,
    this.actionLabel,
  });

  Color _backgroundColor() {
    switch (type) {
      case BannerType.info:
        return const Color(0xFF40C4FF).withOpacity(0.15);
      case BannerType.warning:
        return const Color(0xFFFFC107).withOpacity(0.15);
      case BannerType.error:
        return const Color(0xFFFF5252).withOpacity(0.15);
      case BannerType.success:
        return const Color(0xFF00C896).withOpacity(0.15);
    }
  }

  Color _foregroundColor() {
    switch (type) {
      case BannerType.info:
        return const Color(0xFF40C4FF);
      case BannerType.warning:
        return const Color(0xFFFFC107);
      case BannerType.error:
        return const Color(0xFFFF5252);
      case BannerType.success:
        return const Color(0xFF00C896);
    }
  }

  IconData _defaultIcon() {
    switch (type) {
      case BannerType.info:
        return Icons.info_outline_rounded;
      case BannerType.warning:
        return Icons.warning_amber_rounded;
      case BannerType.error:
        return Icons.error_outline_rounded;
      case BannerType.success:
        return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fgColor = _foregroundColor();
    final bgColor = _backgroundColor();
    final iconData = icon ?? _defaultIcon();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fgColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, color: fgColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: fgColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (onAction != null && actionLabel != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onAction,
                    child: Text(
                      actionLabel!,
                      style: TextStyle(
                        color: fgColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: fgColor.withOpacity(0.7),
              ),
            ),
        ],
      ),
    );
  }
}
