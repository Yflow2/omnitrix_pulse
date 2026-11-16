import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/pulse_config.dart';
import 'fluid_route_overlay_controller.dart';

export 'fluid_route_overlay_controller.dart';

/// Overlay widget coordinating the fluid liquid-morph transition from one widget
/// (e.g. Login button) to another (e.g. Confirm button) powered by a GetX controller.
class FluidRouteOverlayWidget extends StatelessWidget {
  final Rect startRect;
  final Rect? targetRect;
  final Rect? Function()? getTargetRect;
  final PulseConfig config;
  final Color fillColor;
  final Color? targetFillColor;
  final double startRadius;
  final double targetRadius;
  final Widget? startChild;
  final Widget? targetChild;
  final Widget? Function()? getTargetChild;
  final VoidCallback? onNavigate;
  final VoidCallback onComplete;
  final bool isPop;

  const FluidRouteOverlayWidget({
    super.key,
    required this.startRect,
    this.targetRect,
    this.getTargetRect,
    required this.config,
    required this.fillColor,
    this.targetFillColor,
    this.startRadius = 12.0,
    this.targetRadius = 12.0,
    this.startChild,
    this.targetChild,
    this.getTargetChild,
    this.onNavigate,
    required this.onComplete,
    this.isPop = false,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FluidRouteOverlayController>(
      init: FluidRouteOverlayController(
        startRect: startRect,
        targetRect: targetRect,
        getTargetRect: getTargetRect,
        config: config,
        onNavigate: onNavigate,
        onComplete: onComplete,
        isPop: isPop,
      ),
      builder: (controller) {
        return Obx(() {
          final isPhase2 = controller.isPhase2.value;
          final isLoading = controller.isLoading.value;
          final activeController =
              isPhase2 ? controller.phase2Controller : controller.phase1Controller;
          final resolvedTargetRect = controller.resolvedTargetRect.value;

          return AnimatedBuilder(
            animation: activeController,
            builder: (context, _) {
              final animValue = activeController.value;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final screenHeight = constraints.maxHeight;

                  final circleSize = config.circleSize;
                  final screenBottomCenter = Offset(
                    screenWidth / 2,
                    screenHeight - circleSize / 2 - 4.0,
                  );

                  final maxRadius = math.sqrt(
                    math.pow(screenWidth / 2, 2) + math.pow(screenBottomCenter.dy, 2),
                  );
                  final maxDiameter = 2 * maxRadius + 40.0;

                  final Rect animatedRect;
                  final double currentRadius;
                  final double startTextOpacity;
                  final double targetTextOpacity;
                  final Color currentColor;

                  final targetRectVal = isPhase2
                      ? (getTargetRect?.call() ??
                          resolvedTargetRect ??
                          Rect.fromCenter(
                            center: Offset(screenWidth / 2, screenHeight * 0.8),
                            width: startRect.width,
                            height: startRect.height,
                          ))
                      : (resolvedTargetRect ??
                          Rect.fromCenter(
                            center: Offset(screenWidth / 2, screenHeight * 0.8),
                            width: startRect.width,
                            height: startRect.height,
                          ));

                  final resolvedTargetColor = targetFillColor ?? fillColor;

                  if (!isPhase2) {
                    // --- PHASE 1: Button 1 -> Cover Screen (1200ms) ---
                    final t = animValue;
                    currentColor = Color.lerp(fillColor, resolvedTargetColor, t * 0.5)!;
                    targetTextOpacity = 0.0;

                    if (t < 0.25) {
                      // Stage 1: Shrink from startRect into small circle
                      final shrinkProgress =
                          config.curve.transform((t / 0.25).clamp(0.0, 1.0));
                      final smallCircleRect = Rect.fromCircle(
                        center: startRect.center,
                        radius: circleSize / 2,
                      );
                      animatedRect =
                          Rect.lerp(startRect, smallCircleRect, shrinkProgress)!;
                      currentRadius = startRadius +
                          (circleSize / 2 - startRadius) * shrinkProgress;
                      startTextOpacity =
                          (1.0 - (shrinkProgress * 2.5)).clamp(0.0, 1.0);
                    } else if (t < 0.50) {
                      // Stage 2: Move circle from startRect.center to screen bottom center
                      final moveProgress =
                          config.curve.transform(((t - 0.25) / 0.25).clamp(0.0, 1.0));
                      final movingCenter = Offset.lerp(
                          startRect.center, screenBottomCenter, moveProgress)!;
                      animatedRect = Rect.fromCircle(
                          center: movingCenter, radius: circleSize / 2);
                      currentRadius = circleSize / 2;
                      startTextOpacity = 0.0;
                    } else {
                      // Stage 3: Expand circle from bottom center to cover full screen
                      final expandProgress =
                          config.curve.transform(((t - 0.50) / 0.50).clamp(0.0, 1.0));
                      final diameter =
                          circleSize + (maxDiameter - circleSize) * expandProgress;
                      animatedRect = Rect.fromCircle(
                          center: screenBottomCenter, radius: diameter / 2);
                      currentRadius = diameter / 2;
                      startTextOpacity = 0.0;
                    }
                  } else {
                    // --- PHASE 2: Cover Screen -> Target Button ---
                    final t = animValue;
                    currentColor = Color.lerp(
                        fillColor, resolvedTargetColor, 0.5 + t * 0.5)!;
                    startTextOpacity = 0.0;

                    if (t < 0.60) {
                      // Stage 1: Liquid cover contracts smoothly from full screen directly to targetRectVal.center
                      final contractProgress =
                          config.curve.transform((t / 0.60).clamp(0.0, 1.0));
                      final diameter =
                          maxDiameter - (maxDiameter - circleSize) * contractProgress;
                      final movingCenter = Offset.lerp(
                          screenBottomCenter, targetRectVal.center, contractProgress)!;
                      animatedRect = Rect.fromCircle(
                          center: movingCenter, radius: diameter / 2);
                      currentRadius = diameter / 2;
                      targetTextOpacity = 0.0;
                    } else {
                      // Stage 2: Circle at targetRectVal.center smoothly expands into targetRectVal
                      final expandProgress =
                          config.curve.transform(((t - 0.60) / 0.40).clamp(0.0, 1.0));
                      final smallCircleRect = Rect.fromCircle(
                        center: targetRectVal.center,
                        radius: circleSize / 2,
                      );
                      animatedRect =
                          Rect.lerp(smallCircleRect, targetRectVal, expandProgress)!;
                      currentRadius = circleSize / 2 +
                          (targetRadius - circleSize / 2) * expandProgress;
                      targetTextOpacity =
                          ((expandProgress - 0.10) / 0.90).clamp(0.0, 1.0);
                    }
                  }

                  final activeTargetChild = targetChild ?? getTargetChild?.call();
                  Widget? content;
                  if (startTextOpacity > 0.05 && startChild != null) {
                    content = Opacity(opacity: startTextOpacity, child: startChild);
                  } else if (targetTextOpacity > 0.05 && activeTargetChild != null) {
                    content = Opacity(opacity: targetTextOpacity, child: activeTargetChild);
                  }

                  final isDarkBg =
                      ThemeData.estimateBrightnessForColor(currentColor) ==
                          Brightness.dark;
                  final defaultLoaderColor =
                      isDarkBg ? Colors.white : Colors.black;

                  final Widget activeLoader = config.loader ??
                      SizedBox(
                        width: 42,
                        height: 42,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.5,
                          valueColor: AlwaysStoppedAnimation<Color>(defaultLoaderColor),
                        ),
                      );

                  return Material(
                    type: MaterialType.transparency,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned.fromRect(
                          rect: animatedRect,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: currentColor,
                              borderRadius: BorderRadius.circular(currentRadius),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(currentRadius),
                              child: content,
                            ),
                          ),
                        ),
                        if (config.showLoader)
                          IgnorePointer(
                            ignoring: !isLoading,
                            child: AnimatedOpacity(
                              opacity: isLoading ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              child: Center(child: activeLoader),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        });
      },
    );
  }
}
