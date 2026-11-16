## 1.0.0

* Initial release of `omni_transition`.
* Fluid, tag-based liquid-morph page transitions inspired by Flutter's Hero widget.
* Seamless forward navigation with `OmniTransition.navigate(...)`.
* Seamless reverse navigation with `OmniTransition.pop(...)` and automatic system back gesture interception via `TransitionHero(handlePop: true)`.
* Zero-blink frame transitions with dynamic target child resolution and subpixel precision handoff.
* In-transit authentication/process support with optional centered loader and failure fallback (`onFail`).
* Automatic navigation observer support with `OmniTransitionObserver()`.
* State management powered by GetX with 0 `setState()` calls.
