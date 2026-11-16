## 1.0.1

* Fix: Guard against ancestor `RenderBox was not laid out: RenderFractionalTranslation ... hasSize` assertion error during route layout passes.
* Fix: Prevent `Looking up a deactivated widget's ancestor is unsafe` by capturing `NavigatorState` prior to async animation and process delays.
* Improved target rect stability and phase-aware geometry resolution during liquid transitions.

## 1.0.0

* Initial release of `omni_transition`.
* Fluid, tag-based liquid-morph page transitions inspired by Flutter's Hero widget.
* Seamless forward navigation with `OmniTransition.navigate(...)`.
* Seamless reverse navigation with `OmniTransition.pop(...)` and automatic system back gesture interception via `TransitionHero(handlePop: true)`.
* Zero-blink frame transitions with dynamic target child resolution and subpixel precision handoff.
* In-transit authentication/process support with optional centered loader and failure fallback (`onFail`).
* Automatic navigation observer support with `OmniTransitionObserver()`.
* State management powered by GetX with 0 `setState()` calls.
