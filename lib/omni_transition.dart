library omni_transition;

import 'dart:async';
import 'package:flutter/material.dart';
import 'src/core/pulse_config.dart';
import 'src/core/pulse_registry.dart';
import 'src/hero/transition_hero.dart';
import 'src/observer/omnitrix_pulse_observer.dart';
import 'src/transitions/fluid_route_overlay.dart';
import 'src/utils/geometry_utils.dart';

// Exports
export 'src/core/pulse_config.dart';
export 'src/core/pulse_registry.dart';
export 'src/hero/transition_hero.dart';
export 'src/hero/transition_hero_controller.dart';
export 'src/observer/omnitrix_pulse_observer.dart';
export 'src/transitions/fluid_route_overlay_controller.dart';
export 'src/utils/geometry_utils.dart';

/// Backward compatibility aliases
typedef OmnitrixPulse = OmniTransition;
typedef OmnitrixPulseObserver = OmniTransitionObserver;

/// Primary utility class for OmniTransition fluid liquid-morph page transitions.
class OmniTransition {
  OmniTransition._();

  /// Programmatically triggers a fluid liquid-morph transition:
  /// 1. The source button shrinks into a circle and covers the whole screen (default: 1200ms).
  /// 2. While 100% covered, displays [loader] and awaits [process] (e.g. authentication).
  ///    - If [process] returns `false` or throws: invokes [onFail] and reverses back to the source button!
  ///    - If [process] succeeds: navigates to [route] and morphs directly into the target button!
  ///
  /// Example:
  /// ```dart
  /// OmniTransition.navigate(
  ///   context,
  ///   tag: 'login_transition',
  ///   route: MaterialPageRoute(builder: (_) => const OtpScreen()),
  ///   process: () async => await authenticateUser(),
  ///   onFail: () => showErrorMessage(),
  /// );
  /// ```
  static Future<T?> navigate<T extends Object?>(
    BuildContext context, {
    required Route<T> route,
    Object? tag,
    FutureOr<bool?> Function()? process,
    VoidCallback? onFail,
    Widget? loader,
    Duration? duration,
    Duration? coveredDelay,
    PulseConfig? config,
    GlobalKey? triggerKey,
    Color? fillColor,
    Color? targetFillColor,
  }) async {
    final currentRoute = ModalRoute.of(context);
    Rect? triggerRect;
    Widget? sourceChild;
    TransitionHeroState? sourceHero;

    if (tag != null && currentRoute != null) {
      sourceHero = PulseRegistry.instance.getHero(currentRoute, tag);
      if (sourceHero != null && sourceHero.mounted) {
        triggerRect = sourceHero.getBoundingRect();
        sourceChild = sourceHero.child;
      }
    }

    if (triggerRect == null && triggerKey != null) {
      triggerRect = PulseGeometryUtils.getRectFromKey(triggerKey);
    }

    if (triggerRect == null && context.mounted) {
      triggerRect = PulseGeometryUtils.fallbackRect(context);
    }

    final effectiveConfig = (config ?? sourceHero?.config ?? const PulseConfig()).copyWith(
      process: process,
      onFail: onFail,
      loader: loader,
      duration: duration,
      coveredDelay: coveredDelay,
      fillColor: fillColor,
    );

    final overlay = Overlay.of(context, rootOverlay: true);
    final resolvedColor = effectiveConfig.fillColor ??
        PulseGeometryUtils.resolveFillColor(context);

    // Mark route as handled so OmniTransitionObserver does not trigger a duplicate flight
    PulseRegistry.instance.markRouteHandled(route);

    // Hide source hero during flight
    sourceHero?.setFlying(true);

    late final OverlayEntry entry;
    final navFuture = Completer<T?>();

    void cleanup() {
      PulseRegistry.instance.unmarkRouteHandled(route);
      sourceHero?.setFlying(false);
      if (tag != null) {
        final destHero = PulseRegistry.instance.getHero(route, tag);
        destHero?.setFlying(false);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (entry.mounted) {
          entry.remove();
        }
      });
    }

    entry = OverlayEntry(
      builder: (ctx) => FluidRouteOverlayWidget(
        startRect: triggerRect!,
        getTargetRect: () {
          if (tag != null) {
            final destHero = PulseRegistry.instance.getHero(route, tag);
            destHero?.setFlying(true);
            return destHero?.getBoundingRect();
          }
          return null;
        },
        getTargetChild: () {
          if (tag != null) {
            final destHero = PulseRegistry.instance.getHero(route, tag);
            return destHero?.child;
          }
          return null;
        },
        config: effectiveConfig,
        fillColor: resolvedColor,
        targetFillColor: targetFillColor,
        startChild: sourceChild,
        targetChild: tag != null ? PulseRegistry.instance.getHero(route, tag)?.child : null,
        onNavigate: () {
          // Hide destination hero as soon as it mounts so it can reveal cleanly
          if (tag != null) {
            final destHero = PulseRegistry.instance.getHero(route, tag);
            destHero?.setFlying(true);
          }
          Navigator.push<T>(context, route).then((val) {
            if (!navFuture.isCompleted) {
              navFuture.complete(val);
            }
          });
        },
        onComplete: cleanup,
      ),
    );

    overlay.insert(entry);
    return navFuture.future;
  }

  /// Programmatically triggers a fluid reverse liquid-morph transition on back navigation:
  /// 1. The destination button on the current screen shrinks into a circle and covers the screen.
  /// 2. Once 100% covered, [Navigator.pop] is called in the background.
  /// 3. The liquid overlay shrinks down and morphs smoothly into the source button on the revealed screen!
  ///
  /// Example:
  /// ```dart
  /// ElevatedButton(
  ///   onPressed: () => OmniTransition.pop(context),
  ///   child: const Text('Confirm & Go Back'),
  /// )
  /// ```
  static Future<void> pop<T extends Object?>(
    BuildContext context, {
    Object? tag,
    T? result,
    Duration duration = const Duration(milliseconds: 1200),
    Duration revealDuration = const Duration(milliseconds: 1200),
    Curve curve = Curves.easeInOutCubic,
    Color? fillColor,
    Color? targetFillColor,
  }) async {
    final currentRoute = ModalRoute.of(context);
    if (currentRoute == null) {
      Navigator.pop(context, result);
      return;
    }

    TransitionHeroState? currentHero;
    Object? effectiveTag = tag;

    if (effectiveTag != null) {
      currentHero = PulseRegistry.instance.getHero(currentRoute, effectiveTag);
    } else {
      final heroes = PulseRegistry.instance.getAllHeroes(currentRoute);
      if (heroes.isNotEmpty) {
        effectiveTag = heroes.keys.first;
        currentHero = heroes[effectiveTag];
      }
    }

    if (currentHero == null || !currentHero.mounted) {
      Navigator.pop(context, result);
      return;
    }

    final startRect = currentHero.getBoundingRect() ?? PulseGeometryUtils.fallbackRect(context);
    final startChild = currentHero.child;
    final resolvedColor = fillColor ??
        currentHero.config.fillColor ??
        PulseGeometryUtils.resolveFillColor(context);

    // Mark route as handled so observer does not trigger duplicate flight
    PulseRegistry.instance.markRouteHandled(currentRoute);
    currentHero.setFlying(true);

    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    TransitionHeroState? targetHero;

    void cleanup() {
      PulseRegistry.instance.unmarkRouteHandled(currentRoute);
      currentHero?.setFlying(false);
      targetHero?.setFlying(false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (entry.mounted) {
          entry.remove();
        }
      });
    }

    entry = OverlayEntry(
      builder: (ctx) => FluidRouteOverlayWidget(
        startRect: startRect,
        getTargetRect: () {
          if (effectiveTag != null) {
            targetHero = PulseRegistry.instance.findHero(effectiveTag, excludeRoute: currentRoute);
            if (targetHero != null && targetHero!.mounted) {
              targetHero!.setFlying(true);
              return targetHero!.getBoundingRect();
            }
          }
          return null;
        },
        getTargetChild: () {
          if (effectiveTag != null) {
            targetHero = PulseRegistry.instance.findHero(effectiveTag, excludeRoute: currentRoute);
            return targetHero?.child;
          }
          return null;
        },
        config: PulseConfig(
          duration: duration,
          revealDuration: revealDuration,
          curve: curve,
          showLoader: false,
          coveredDelay: Duration.zero,
        ),
        fillColor: resolvedColor,
        targetFillColor: targetFillColor ?? targetHero?.config.fillColor ?? resolvedColor,
        startChild: startChild,
        targetChild: effectiveTag != null
            ? PulseRegistry.instance.findHero(effectiveTag, excludeRoute: currentRoute)?.child
            : null,
        onNavigate: () {
          // Screen is 100% covered! Pop the route now in the background
          Navigator.pop(context, result);
        },
        onComplete: cleanup,
        isPop: true,
      ),
    );

    overlay.insert(entry);
  }
}
