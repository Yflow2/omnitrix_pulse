import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../omni_transition.dart';

export 'transition_hero_controller.dart';

/// A widget that marks its child for cross-screen fluid liquid-morph transitions.
///
/// On trigger, the source button shrinks into a circle, drops to the bottom,
/// and expands to cover the screen (1200ms). While covered, an optional loader
/// is displayed and an optional authentication [process] is awaited (default 2s delay).
/// - If [process] succeeds (returns true or completes), it navigates to the next page
///   and morphs directly into the target button!
/// - If [process] fails (returns false or throws), [onFail] is called and the animation
///   reverses back into the source button without navigating!
class TransitionHero extends StatefulWidget {
  /// Unique identifier linking this widget to its destination counterpart.
  final Object tag;

  /// The widget subtree (e.g. ElevatedButton).
  final Widget child;

  /// Optional destination route to navigate to when triggered.
  final Route<dynamic>? route;

  /// Optional transition configuration.
  final PulseConfig? config;

  /// Shorthand fill color for the morphing liquid effect.
  final Color? fillColor;

  /// Initial corner radius of the button (defaults to 12.0).
  final double? buttonRadius;

  /// Duration for the screen-covering phase (defaults to 1200ms).
  final Duration? duration;

  /// Duration to wait while covered with loader (defaults to 2 seconds).
  final Duration? coveredDelay;

  /// Optional process/authentication task awaited while the screen is 100% covered.
  /// Return `true` on success, or `false` on failure to trigger [onFail] and reverse.
  final FutureOr<bool?> Function()? process;

  /// Optional callback invoked when [process] returns false or throws.
  final VoidCallback? onFail;

  /// Optional loader animation widget displayed in center while covered.
  final Widget? loader;

  /// When true, intercepts system back gestures and [Navigator.maybePop] to trigger
  /// a smooth [OmnitrixPulse.pop] animation. Defaults to false.
  final bool handlePop;

  const TransitionHero({
    super.key,
    required this.tag,
    required this.child,
    this.route,
    this.config,
    this.fillColor,
    this.buttonRadius,
    this.duration,
    this.coveredDelay,
    this.process,
    this.onFail,
    this.loader,
    this.handlePop = false,
  });

  /// Finds the [TransitionHeroState] associated with a given [tag] on the current route.
  static TransitionHeroState? of(BuildContext context, Object tag) {
    final route = ModalRoute.of(context);
    return PulseRegistry.instance.getHero(route, tag);
  }

  @override
  State<TransitionHero> createState() => TransitionHeroState();
}

class TransitionHeroState extends State<TransitionHero> {
  final GlobalKey _contentKey = GlobalKey();
  final TransitionHeroController controller = TransitionHeroController();
  Route<dynamic>? _route;

  GlobalKey get contentKey => _contentKey;
  Object get tag => widget.tag;
  Widget get child => widget.child;
  bool get isFlying => controller.isFlying.value;

  PulseConfig get config {
    final base = widget.config ?? const PulseConfig();
    return base.copyWith(
      fillColor: widget.fillColor ?? base.fillColor,
      buttonRadius: widget.buttonRadius ?? base.buttonRadius,
      duration: widget.duration ?? base.duration,
      coveredDelay: widget.coveredDelay ?? base.coveredDelay,
      process: widget.process ?? base.process,
      onFail: widget.onFail ?? base.onFail,
      loader: widget.loader ?? base.loader,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newRoute = ModalRoute.of(context);
    if (newRoute != _route) {
      if (_route != null) {
        PulseRegistry.instance.unregister(_route!, widget.tag, this);
      }
      _route = newRoute;
      if (_route != null) {
        PulseRegistry.instance.register(_route!, widget.tag, this);
      }
    }
  }

  @override
  void didUpdateWidget(covariant TransitionHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tag != oldWidget.tag && _route != null) {
      PulseRegistry.instance.unregister(_route!, oldWidget.tag, this);
      PulseRegistry.instance.register(_route!, widget.tag, this);
    }
  }

  @override
  void dispose() {
    if (_route != null) {
      PulseRegistry.instance.unregister(_route!, widget.tag, this);
    }
    controller.dispose();
    super.dispose();
  }

  /// Sets whether the hero is currently airborne (in flight) via GetX controller.
  void setFlying(bool flying) {
    controller.setFlying(flying);
  }

  /// Measures and returns the global bounding rectangle of the child widget.
  Rect? getBoundingRect() {
    return PulseGeometryUtils.getRectFromKey(_contentKey);
  }

  bool _isPopping = false;

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    Widget content = Obx(
      () => KeyedSubtree(
        key: _contentKey,
        child: Opacity(
          opacity: controller.isFlying.value ? 0.0 : 1.0,
          child: widget.child,
        ),
      ),
    );

    if (widget.handlePop && canPop) {
      content = PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop || _isPopping) return;
          _isPopping = true;
          OmniTransition.pop(context, tag: widget.tag, result: result).whenComplete(() {
            _isPopping = false;
          });
        },
        child: content,
      );
    }

    return content;
  }
}
