import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/pulse_config.dart';

/// GetX controller managing animation sequences and visual state of the fluid transition overlay.
class FluidRouteOverlayController extends GetxController with GetTickerProviderStateMixin {
  final Rect startRect;
  final Rect? targetRect;
  final Rect? Function()? getTargetRect;
  final PulseConfig config;
  final VoidCallback? onNavigate;
  final VoidCallback onComplete;
  final bool isPop;

  late final AnimationController phase1Controller;
  late final AnimationController phase2Controller;

  final RxBool isPhase2 = false.obs;
  final RxBool isLoading = false.obs;
  final Rx<Rect?> resolvedTargetRect = Rx<Rect?>(null);

  Timer? _activeTimer;
  bool _isDisposed = false;

  FluidRouteOverlayController({
    required this.startRect,
    this.targetRect,
    this.getTargetRect,
    required this.config,
    this.onNavigate,
    required this.onComplete,
    this.isPop = false,
  });

  @override
  void onInit() {
    super.onInit();

    // Phase 1: Shrinks button to circle, drops to bottom, expands to cover screen
    phase1Controller = AnimationController(
      vsync: this,
      duration: config.duration,
      reverseDuration: config.reverseDuration ?? config.duration,
    );

    // Phase 2: Shrinks from full-screen cover into target button
    phase2Controller = AnimationController(
      vsync: this,
      duration: config.revealDuration,
      reverseDuration: config.reverseDuration ?? config.revealDuration,
    );

    if (!isPop) {
      resolvedTargetRect.value = targetRect;
    }
    runSequence();
  }

  AnimationController get activeController =>
      isPhase2.value ? phase2Controller : phase1Controller;

  Future<void> _safeDelay(Duration duration) {
    if (duration <= Duration.zero || _isDisposed) return Future.value();
    final completer = Completer<void>();
    _activeTimer = Timer(duration, () {
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  Future<void> runSequence() async {
    if (isPop) {
      // Pop (reverse) transition
      await phase1Controller.forward();
      if (_isDisposed) return;

      // Pop the route now behind the solid liquid curtain
      if (onNavigate != null) {
        onNavigate!.call();
      }

      await _safeDelay(const Duration(milliseconds: 350));
      if (_isDisposed) return;

      resolvedTargetRect.value = getTargetRect?.call() ?? resolvedTargetRect.value ?? startRect;
      isPhase2.value = true;

      await phase2Controller.forward();
      if (!_isDisposed) onComplete();
      return;
    }

    // Forward transition
    await phase1Controller.forward();
    if (_isDisposed) return;

    if (!_isDisposed && config.showLoader) {
      isLoading.value = true;
    }

    var success = true;
    if (config.process != null) {
      try {
        final result = await config.process!();
        if (result == false) {
          success = false;
        }
      } catch (_) {
        success = false;
      }
    }

    if (!success) {
      config.onFail?.call();
      if (!_isDisposed) {
        isLoading.value = false;
      }
      await _safeDelay(const Duration(milliseconds: 100));
      if (_isDisposed) return;

      await phase1Controller.reverse();
      if (!_isDisposed) onComplete();
      return;
    }

    if (config.coveredDelay > Duration.zero) {
      await _safeDelay(config.coveredDelay);
      if (_isDisposed) return;
    }

    if (!_isDisposed && isLoading.value) {
      isLoading.value = false;
      await _safeDelay(const Duration(milliseconds: 120));
      if (_isDisposed) return;
    }

    if (onNavigate != null) {
      onNavigate!.call();
      await _safeDelay(const Duration(milliseconds: 350));
      if (_isDisposed) return;
    }

    resolvedTargetRect.value = getTargetRect?.call() ?? resolvedTargetRect.value ?? startRect;
    isPhase2.value = true;

    await phase2Controller.forward();
    if (!_isDisposed) {
      onComplete();
    }
  }

  @override
  void onClose() {
    _isDisposed = true;
    _activeTimer?.cancel();
    _activeTimer = null;
    phase1Controller.dispose();
    phase2Controller.dispose();
    super.onClose();
  }
}
