import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Color? backgroundColor;
  final Border? border;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 24.0,
    this.blur = 12.0,
    this.opacity = 0.45,
    this.backgroundColor,
    this.border,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Default colors based on theme if not provided
    final defaultBgColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: opacity) // Slate 800
        : Colors.white.withValues(alpha: 0.8);

    final defaultBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.3);

    // Web Crash Fix: BackdropFilter can be unstable on some web renderers (HTML).
    // We disable blur on web and use a more opaque background for readability/stability.
    if (kIsWeb) {
      return Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          // Use higher opacity on web since there is no blur
          color:
              backgroundColor ??
              (isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.95)),
          border: border ?? Border.all(color: defaultBorderColor),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: child,
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor ?? defaultBgColor,
              border: border ?? Border.all(color: defaultBorderColor),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
