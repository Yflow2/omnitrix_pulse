import 'package:flutter/material.dart';

/// Geometry and measurement helpers for Omnitrix Pulse transitions.
class PulseGeometryUtils {
  PulseGeometryUtils._();

  /// Safely resolves the global bounding [Rect] of a widget by its [GlobalKey].
  /// Returns null if the widget is not mounted or its render object has no size.
  static Rect? getRectFromKey(GlobalKey? key) {
    if (key == null) return null;
    final context = key.currentContext;
    if (context == null || !context.mounted) return null;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null &&
        renderBox.attached &&
        renderBox.hasSize &&
        renderBox.size.width > 0 &&
        renderBox.size.height > 0) {
      try {
        final position = renderBox.localToGlobal(Offset.zero);
        return position & renderBox.size;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Calculates the radius required for a circle centered at [center]
  /// to completely engulf a screen of [screenSize].
  static double calculateMaxRadius(Offset center, Size screenSize) {
    final corners = [
      Offset.zero,
      Offset(screenSize.width, 0),
      Offset(0, screenSize.height),
      Offset(screenSize.width, screenSize.height),
    ];

    double maxDistance = 0.0;
    for (final corner in corners) {
      final distance = (corner - center).distance;
      if (distance > maxDistance) {
        maxDistance = distance;
      }
    }
    return maxDistance + 32.0; // Margin to avoid edge aliasing
  }

  /// Fallback rect when a key cannot be found or measured, centered on screen.
  static Rect fallbackRect(BuildContext context, {double width = 160.0, double height = 48.0}) {
    final size = MediaQuery.sizeOf(context);
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.75),
      width: width,
      height: height,
    );
  }

  /// Resolves an appropriate primary fill color from context or widget tree.
  static Color resolveFillColor(BuildContext context, {Color? customColor}) {
    if (customColor != null) return customColor;
    final theme = Theme.of(context);
    return theme.colorScheme.primary;
  }
}
