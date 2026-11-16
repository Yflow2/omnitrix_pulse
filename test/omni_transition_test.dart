import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_transition/omni_transition.dart';
import 'package:omni_transition/src/transitions/fluid_route_overlay.dart';

void main() {
  group('PulseRegistry Tests', () {
    testWidgets('registers and unregisters TransitionHero properly', (tester) async {
      final registry = PulseRegistry.instance;

      final testWidget = MaterialApp(
        home: Scaffold(
          body: TransitionHero(
            tag: 'test_tag_1',
            child: Container(key: const ValueKey('hero_box'), width: 100, height: 50),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      expect(registry.activeRoutesCount, equals(1));

      // Rebuild without the hero
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(registry.activeRoutesCount, equals(0));
    });
  });

  group('TransitionHero Widget Tests', () {
    testWidgets('renders child and toggles flying mode', (tester) async {
      late TransitionHeroState heroState;

      final testWidget = MaterialApp(
        home: Scaffold(
          body: TransitionHero(
            tag: 'login_btn',
            child: Builder(
              builder: (context) {
                heroState = context.findAncestorStateOfType<TransitionHeroState>()!;
                return const Text('Login');
              },
            ),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);

      // Trigger flying mode
      heroState.setFlying(true);
      await tester.pump();

      // Child is wrapped in Opacity(0) when flying
      final opacityFinder = find.byType(Opacity);
      expect(opacityFinder, findsOneWidget);
      final Opacity opacityWidget = tester.widget(opacityFinder);
      expect(opacityWidget.opacity, equals(0.0));

      // Restore
      heroState.setFlying(false);
      await tester.pump();
      expect(find.text('Login'), findsOneWidget);
    });
  });

  group('Button-to-Button Page Navigation with Authentication & onFail', () {
    testWidgets(
        'covers screen, authenticates successfully, and navigates to target button',
        (tester) async {
      bool processRan = false;

      final app = MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: TransitionHero(
                  tag: 'login_transition',
                  child: ElevatedButton(
                    onPressed: () {
                      OmniTransition.navigate(
                        context,
                        tag: 'login_transition',
                        route: MaterialPageRoute(
                          builder: (_) => Scaffold(
                            body: Center(
                              child: TransitionHero(
                                tag: 'login_transition',
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Confirm & Go Back'),
                                ),
                              ),
                            ),
                          ),
                        ),
                        duration: const Duration(milliseconds: 1200),
                        coveredDelay: const Duration(seconds: 2),
                        process: () async {
                          processRan = true;
                          return true; // Success!
                        },
                        loader: const Text('Authenticating...'),
                      );
                    },
                    child: const Text('Login'),
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);

      // Tap Login button
      await tester.tap(find.text('Login'));
      await tester.pump();
      await tester.pump();

      // Phase 1: 1200ms screen covering
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));

      // Screen is 100% covered. Process ran and loader is visible
      expect(processRan, isTrue);
      expect(find.text('Authenticating...'), findsOneWidget);
      // Destination page is NOT navigated to yet!
      expect(find.text('Confirm & Go Back'), findsNothing);

      // Await 2s covered delay
      await tester.pump(const Duration(seconds: 2));

      // Loader fade out & route mount
      await tester.pump(const Duration(milliseconds: 250));

      // Phase 2: Liquid cover reveals and shrinks into target button
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      expect(find.text('Confirm & Go Back'), findsOneWidget);
    });

    testWidgets(
        'when authentication fails, calls onFail, reverses, and DOES NOT navigate',
        (tester) async {
      bool onFailCalled = false;

      final app = MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: TransitionHero(
                  tag: 'fail_test',
                  child: ElevatedButton(
                    onPressed: () {
                      OmniTransition.navigate(
                        context,
                        tag: 'fail_test',
                        route: MaterialPageRoute(
                          builder: (_) => const Scaffold(
                            body: Text('Should Never Appear'),
                          ),
                        ),
                        duration: const Duration(milliseconds: 1200),
                        coveredDelay: const Duration(seconds: 2),
                        process: () async {
                          return false; // Authentication FAILED!
                        },
                        onFail: () {
                          onFailCalled = true;
                        },
                        loader: const Text('Checking...'),
                      );
                    },
                    child: const Text('Submit'),
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit'));
      await tester.pump();
      await tester.pump();

      // Phase 1: 1200ms screen covering
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));

      // onFail should be called!
      expect(onFailCalled, isTrue);

      // Reverses back to starting button
      await tester.pump(const Duration(milliseconds: 1400));
      await tester.pumpAndSettle();

      // Screen remains on initial page; destination page was NEVER pushed!
      expect(find.text('Submit'), findsOneWidget);
      expect(find.text('Should Never Appear'), findsNothing);
    });

    testWidgets(
        'does NOT cover screen twice when OmnitrixPulseObserver is attached to MaterialApp',
        (tester) async {
      bool authenticated = false;

      final app = MaterialApp(
        navigatorObservers: [
          OmniTransitionObserver(),
        ],
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: TransitionHero(
                  tag: 'login_transition',
                  child: ElevatedButton(
                    onPressed: () {
                      OmniTransition.navigate(
                        context,
                        tag: 'login_transition',
                        route: MaterialPageRoute(
                          builder: (_) => Scaffold(
                            body: Center(
                              child: TransitionHero(
                                tag: 'login_transition',
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Confirm & Go Back'),
                                ),
                              ),
                            ),
                          ),
                        ),
                        duration: const Duration(milliseconds: 1200),
                        coveredDelay: const Duration(seconds: 2),
                        process: () async {
                          authenticated = true;
                          return true;
                        },
                        loader: const Text('Authenticating...'),
                      );
                    },
                    child: const Text('Login'),
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Login'));
      await tester.pump();
      await tester.pump();

      // Exactly ONE FluidRouteOverlayWidget should be active
      expect(find.byType(FluidRouteOverlayWidget), findsOneWidget);

      // Advance through Phase 1 covering (1200ms)
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));

      expect(authenticated, isTrue);
      expect(find.byType(FluidRouteOverlayWidget), findsOneWidget);

      // Advance through 2s covered delay
      await tester.pump(const Duration(seconds: 2));

      // Route mounted in background
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 50));

      // Critical check: Still exactly ONE overlay widget (OmnitrixPulseObserver did NOT create a duplicate!)
      expect(find.byType(FluidRouteOverlayWidget), findsOneWidget);

      // Advance through Phase 2 reveal (1000ms)
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      // Overlay completed and cleaned up
      expect(find.byType(FluidRouteOverlayWidget), findsNothing);
      expect(find.text('Confirm & Go Back'), findsOneWidget);
    });

    testWidgets(
        'OmnitrixPulse.pop animates from target button and covers screen BEFORE popping route, and does NOT run twice with OmnitrixPulseObserver',
        (tester) async {
      final app = MaterialApp(
        navigatorObservers: [
          OmniTransitionObserver(),
        ],
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: TransitionHero(
                  tag: 'pop_test_tag',
                  child: ElevatedButton(
                    onPressed: () {
                      OmniTransition.navigate(
                        context,
                        tag: 'pop_test_tag',
                        route: MaterialPageRoute(
                          builder: (otpContext) => Scaffold(
                            body: Center(
                              child: TransitionHero(
                                tag: 'pop_test_tag',
                                child: ElevatedButton(
                                  onPressed: () => OmniTransition.pop(
                                    otpContext,
                                    duration: const Duration(milliseconds: 1200),
                                    revealDuration: const Duration(milliseconds: 1200),
                                  ),
                                  child: const Text('Confirm & Go Back'),
                                ),
                              ),
                            ),
                          ),
                        ),
                        duration: const Duration(milliseconds: 200),
                        coveredDelay: Duration.zero,
                      );
                    },
                    child: const Text('Login'),
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Navigate forward
      await tester.tap(find.text('Login'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      expect(find.text('Confirm & Go Back'), findsOneWidget);

      // Tap Confirm & Go Back (triggers OmnitrixPulse.pop)
      await tester.tap(find.text('Confirm & Go Back'));
      await tester.pump();
      await tester.pump();

      // Exactly ONE FluidRouteOverlayWidget is created on the current screen
      expect(find.byType(FluidRouteOverlayWidget), findsOneWidget);

      // Halfway through covering (600ms of 1200ms):
      await tester.pump(const Duration(milliseconds: 600));
      // Route has NOT popped yet because screen is still covering!
      expect(find.text('Confirm & Go Back'), findsOneWidget);

      // Finish covering (1200ms total):
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 1));

      // Post-cover layout delay
      await tester.pump(const Duration(milliseconds: 150));

      // Check: Still exactly ONE overlay (OmnitrixPulseObserver did NOT launch a duplicate on pop!)
      expect(find.byType(FluidRouteOverlayWidget), findsOneWidget);

      // Phase 2 reveal (1200ms)
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();

      // Cleaned up and back on Login screen!
      expect(find.byType(FluidRouteOverlayWidget), findsNothing);
      expect(find.text('Login'), findsOneWidget);
    });
  });
}
