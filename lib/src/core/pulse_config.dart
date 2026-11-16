import 'dart:async';
import 'package:flutter/material.dart';

/// Configuration options for page-to-page fluid liquid-morph transitions.
class PulseConfig {
  /// Duration for the screen-covering animation (Phase 1, default: 1200ms).
  final Duration duration;

  /// Duration for revealing and morphing into the target button (Phase 2, default: 1000ms).
  final Duration revealDuration;

  /// Optional duration for the reverse pop transition (defaults to [duration]).
  final Duration? reverseDuration;

  /// Duration to wait while the screen is 100% covered (default: 2 seconds).
  final Duration coveredDelay;

  /// Optional async process/authentication task executed while the screen is 100% covered.
  /// Return `true` or complete normally on success; return `false` or throw to trigger [onFail].
  final FutureOr<bool?> Function()? process;

  /// Optional callback invoked when [process] returns `false` or throws.
  /// When this occurs, navigation is cancelled and the animation reverses back to the source button.
  final VoidCallback? onFail;

  /// Optional loader animation widget displayed in the center while covered.
  /// If null, a clean circular progress indicator is shown during the delay/process.
  final Widget? loader;

  /// Whether to show a loader while covered.
  final bool showLoader;

  /// Solid fill color of the morphing liquid bubble.
  final Color? fillColor;

  /// Starting corner radius of the button before shrinking into a circle (default: 12.0).
  final double buttonRadius;

  /// Diameter of the small dropped circle (default: 28.0).
  final double circleSize;

  /// Optional content builder for the button as it shrinks.
  final Widget Function(BuildContext context, double textOpacity)? buttonContentBuilder;

  /// Easing curve for animations.
  final Curve curve;

  const PulseConfig({
    this.duration = const Duration(milliseconds: 1200),
    this.revealDuration = const Duration(milliseconds: 1000),
    this.reverseDuration,
    this.coveredDelay = const Duration(seconds: 2),
    this.process,
    this.onFail,
    this.loader,
    this.showLoader = true,
    this.fillColor,
    this.buttonRadius = 12.0,
    this.circleSize = 28.0,
    this.buttonContentBuilder,
    this.curve = Curves.easeInOutCubic,
  });

  PulseConfig copyWith({
    Duration? duration,
    Duration? revealDuration,
    Duration? reverseDuration,
    Duration? coveredDelay,
    FutureOr<bool?> Function()? process,
    VoidCallback? onFail,
    Widget? loader,
    bool? showLoader,
    Color? fillColor,
    double? buttonRadius,
    double? circleSize,
    Widget Function(BuildContext context, double textOpacity)? buttonContentBuilder,
    Curve? curve,
  }) {
    return PulseConfig(
      duration: duration ?? this.duration,
      revealDuration: revealDuration ?? this.revealDuration,
      reverseDuration: reverseDuration ?? this.reverseDuration,
      coveredDelay: coveredDelay ?? this.coveredDelay,
      process: process ?? this.process,
      onFail: onFail ?? this.onFail,
      loader: loader ?? this.loader,
      showLoader: showLoader ?? this.showLoader,
      fillColor: fillColor ?? this.fillColor,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      circleSize: circleSize ?? this.circleSize,
      buttonContentBuilder: buttonContentBuilder ?? this.buttonContentBuilder,
      curve: curve ?? this.curve,
    );
  }
}
