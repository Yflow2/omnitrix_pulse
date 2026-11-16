import 'package:flutter/material.dart';
import '../hero/transition_hero.dart';

/// Registry holding active [TransitionHero] widgets grouped by [Route].
class PulseRegistry {
  PulseRegistry._();

  static final PulseRegistry instance = PulseRegistry._();

  final Map<Route<dynamic>, Map<Object, TransitionHeroState>> _routeHeroes = {};
  final Set<Route<dynamic>> _handledRoutes = <Route<dynamic>>{};

  /// Marks a [route] as being actively handled programmatically (e.g. by [OmnitrixPulse.navigate]),
  /// preventing [OmnitrixPulseObserver] from triggering duplicate transitions.
  void markRouteHandled(Route<dynamic> route) {
    _handledRoutes.add(route);
  }

  /// Unmarks a [route] once its programmatic transition has finished.
  void unmarkRouteHandled(Route<dynamic> route) {
    _handledRoutes.remove(route);
  }

  /// Checks if a [route] is already being handled programmatically.
  bool isRouteHandled(Route<dynamic> route) {
    return _handledRoutes.contains(route);
  }

  /// Registers a [TransitionHeroState] under its route and tag.
  void register(Route<dynamic> route, Object tag, TransitionHeroState state) {
    final heroes = _routeHeroes.putIfAbsent(route, () => <Object, TransitionHeroState>{});
    heroes[tag] = state;
  }

  /// Deregisters a [TransitionHeroState].
  void unregister(Route<dynamic> route, Object tag, TransitionHeroState state) {
    final heroes = _routeHeroes[route];
    if (heroes != null) {
      if (heroes[tag] == state) {
        heroes.remove(tag);
      }
      if (heroes.isEmpty) {
        _routeHeroes.remove(route);
      }
    }
  }

  /// Retrieves a registered [TransitionHeroState] by tag on a specific [Route].
  TransitionHeroState? getHero(Route<dynamic>? route, Object tag) {
    if (route == null) return null;
    return _routeHeroes[route]?[tag];
  }

  /// Retrieves all registered [TransitionHeroState]s on a specific [Route].
  Map<Object, TransitionHeroState> getAllHeroes(Route<dynamic>? route) {
    if (route == null) return const {};
    return Map.unmodifiable(_routeHeroes[route] ?? const {});
  }

  /// Finds a registered [TransitionHeroState] across any route matching [tag],
  /// optionally excluding a specific [excludeRoute].
  TransitionHeroState? findHero(Object tag, {Route<dynamic>? excludeRoute}) {
    for (final entry in _routeHeroes.entries) {
      if (entry.key != excludeRoute && entry.value.containsKey(tag)) {
        final hero = entry.value[tag];
        if (hero != null && hero.mounted) {
          return hero;
        }
      }
    }
    return null;
  }

  /// Clears all registrations for a route when disposed.
  void removeRoute(Route<dynamic> route) {
    _routeHeroes.remove(route);
  }

  /// For testing/debugging: returns current registered route count.
  int get activeRoutesCount => _routeHeroes.length;
}
