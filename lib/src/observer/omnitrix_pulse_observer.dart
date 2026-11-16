import 'package:flutter/material.dart';
import '../core/pulse_config.dart';
import '../core/pulse_registry.dart';
import '../hero/transition_hero.dart';
import '../transitions/fluid_route_overlay.dart';
import '../utils/geometry_utils.dart';

/// NavigatorObserver that automatically detects matching [TransitionHero] widgets
/// across routes and coordinates the fluid liquid-morph transition from the source widget
/// to the destination widget.
///
/// Add to your [MaterialApp]:
/// ```dart
/// MaterialApp(
///   navigatorObservers: [
///     OmniTransitionObserver(),
///   ],
///   home: const LoginScreen(),
/// );
/// ```
class OmniTransitionObserver extends NavigatorObserver {
  final PulseConfig defaultConfig;

  OmniTransitionObserver({
    this.defaultConfig = const PulseConfig(),
  });

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (PulseRegistry.instance.isRouteHandled(route)) {
      // Route is already handled programmatically by OmnitrixPulse.navigate.
      // Ignore to prevent covering the screen twice!
      return;
    }
    if (previousRoute != null) {
      _coordinateFlight(
        fromRoute: previousRoute,
        toRoute: route,
        isPop: false,
      );
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (PulseRegistry.instance.isRouteHandled(route)) {
      // Route pop is already handled programmatically by OmnitrixPulse.pop.
      // Ignore to prevent animating back twice!
      return;
    }
    if (previousRoute != null) {
      _coordinateFlight(
        fromRoute: route,
        toRoute: previousRoute,
        isPop: true,
      );
    }
  }

  void _coordinateFlight({
    required Route<dynamic> fromRoute,
    required Route<dynamic> toRoute,
    required bool isPop,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final overlay = navigator?.overlay;
      if (overlay == null) return;

      final fromHeroes = PulseRegistry.instance.getAllHeroes(fromRoute);
      final toHeroes = PulseRegistry.instance.getAllHeroes(toRoute);

      if (fromHeroes.isEmpty || toHeroes.isEmpty) return;

      // Find first matching tag
      for (final tag in fromHeroes.keys) {
        if (!toHeroes.containsKey(tag)) continue;

        final fromHeroState = fromHeroes[tag];
        final toHeroState = toHeroes[tag];

        if (fromHeroState == null || toHeroState == null) continue;
        if (!fromHeroState.mounted || !toHeroState.mounted) continue;

        final fromRect = fromHeroState.getBoundingRect();
        final toRect = toHeroState.getBoundingRect();

        if (fromRect == null || toRect == null) continue;

        _launchFlight(
          overlay: overlay,
          fromHero: fromHeroState,
          toHero: toHeroState,
          fromRect: fromRect,
          toRect: toRect,
          isPop: isPop,
        );
        break;
      }
    });
  }

  void _launchFlight({
    required OverlayState overlay,
    required TransitionHeroState fromHero,
    required TransitionHeroState toHero,
    required Rect fromRect,
    required Rect toRect,
    required bool isPop,
  }) {
    final config = fromHero.config;

    fromHero.setFlying(true);
    toHero.setFlying(true);

    final startColor = config.fillColor ?? PulseGeometryUtils.resolveFillColor(overlay.context);
    final targetColor = toHero.config.fillColor ?? startColor;

    late final OverlayEntry entry;

    void cleanup() {
      fromHero.setFlying(false);
      toHero.setFlying(false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (entry.mounted) {
          entry.remove();
        }
      });
    }

    entry = OverlayEntry(
      builder: (ctx) => FluidRouteOverlayWidget(
        startRect: fromRect,
        targetRect: toRect,
        getTargetRect: () => toHero.mounted ? toHero.getBoundingRect() : null,
        getTargetChild: () => toHero.mounted ? toHero.child : null,
        config: config,
        fillColor: startColor,
        targetFillColor: targetColor,
        startRadius: fromHero.config.buttonRadius,
        targetRadius: toHero.config.buttonRadius,
        startChild: fromHero.child,
        targetChild: toHero.child,
        onComplete: cleanup,
        isPop: isPop,
      ),
    );

    overlay.insert(entry);
  }
}

/// Backward compatibility alias
typedef OmnitrixPulseObserver = OmniTransitionObserver;

