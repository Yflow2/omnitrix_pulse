# OmniTransition

A high-performance, fluid liquid-morph page transition package for Flutter, inspired by native `Hero` animations. Powered by GetX with **0 `setState()`** calls.

[![Pub Version](https://img.shields.io/pub/v/omni_transition)](https://pub.dev/packages/omni_transition)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

---

## ✨ Features

- 💧 **Liquid-Morph Fluidity**: The source button shrinks into a circle, drops to the bottom, and expands radially to cover 100% of the screen, then reveals the new screen by contracting directly into the target button.
- ⚡ **Zero-Blink Transitions**: Pixel-perfect handoffs with dynamic child rendering and post-frame overlay synchronization. No flickers or blank frames.
- 🔒 **In-Transit Authentication & Delays**: Await an asynchronous authentication task (`process`) while the screen is 100% covered with a customizable loader.
- ↩️ **Graceful Failure Handling (`onFail`)**: If authentication fails, navigation is cancelled and the liquid animation reverses smoothly back into the source button.
- 🔙 **Seamless Back Navigation (`OmniTransition.pop`)**: The destination button covers the screen before popping the route behind the curtain, then reveals the source screen and button.
- 📱 **System Back Interception**: `TransitionHero(handlePop: true)` intercepts Android hardware back buttons and predictive back edge swipes using `PopScope`.
- 🚀 **GetX Driven**: Completely reactive state management with **zero `setState()`** invocations.

---

## 📦 Installation

Add `omni_transition` to your `pubspec.yaml`:

```yaml
dependencies:
  omni_transition: ^1.0.0
```

Then run:

```bash
flutter pub get
```

---

## 🚀 Quick Start

### 1. Register the Observer in `MaterialApp` or `GetMaterialApp`

```dart
import 'package:flutter/material.dart';
import 'package:omni_transition/omni_transition.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OmniTransition Demo',
      navigatorObservers: [
        OmniTransitionObserver(),
      ],
      home: const LoginScreen(),
    );
  }
}
```

---

### 2. Wrap Widgets on Source and Destination Screens

**Source Screen (e.g. Login):**

```dart
TransitionHero(
  tag: 'login_transition',
  fillColor: const Color(0xFF00FF7F),
  child: ElevatedButton(
    onPressed: () {
      OmniTransition.navigate(
        context,
        tag: 'login_transition',
        route: MaterialPageRoute(builder: (_) => const OtpScreen()),
        duration: const Duration(milliseconds: 1200),
        coveredDelay: const Duration(seconds: 2),
        process: () async {
          // Await your authentication or API call
          final success = await authService.verifyCredentials();
          return success; // Return true to navigate, false to abort & reverse
        },
        onFail: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication failed!')),
          );
        },
        loader: const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
        ),
      );
    },
    child: const Text('Login'),
  ),
)
```

**Destination Screen (e.g. OTP Verification):**

```dart
TransitionHero(
  tag: 'login_transition',
  fillColor: const Color(0xFF00FF7F),
  handlePop: true, // Intercepts system back gestures automatically
  child: ElevatedButton(
    onPressed: () => OmniTransition.pop(context),
    child: const Text('Confirm & Go Back'),
  ),
)
```

---

## 🛠️ API Reference

### `OmniTransition.navigate(...)`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `context` | `BuildContext` | *required* | The build context. |
| `route` | `Route<T>` | *required* | Destination route to push upon successful transition. |
| `tag` | `Object?` | `null` | Matching identifier between source and target `TransitionHero`. |
| `process` | `FutureOr<bool?> Function()?` | `null` | Async task (e.g. login/OTP) executed while screen is 100% covered. Returns `false` or throws to trigger `onFail`. |
| `onFail` | `VoidCallback?` | `null` | Callback invoked when `process` fails; aborts navigation and reverses liquid back to source button. |
| `coveredDelay` | `Duration?` | `2s` | Delay to wait while screen is 100% covered with loader. |
| `duration` | `Duration?` | `1200ms` | Duration for the button-to-cover animation. |
| `loader` | `Widget?` | Circular indicator | Optional custom loading widget shown in the center while covered. |
| `fillColor` | `Color?` | Theme color | Custom color for the morphing liquid bubble. |

### `OmniTransition.pop(...)`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `context` | `BuildContext` | *required* | The build context. |
| `tag` | `Object?` | First hero tag | Matching tag to return to on the previous screen. |
| `result` | `T?` | `null` | Optional result passed back to `Navigator.pop`. |
| `duration` | `Duration` | `1200ms` | Duration for the reverse screen cover. |
| `revealDuration` | `Duration` | `1200ms` | Duration for revealing the source button. |

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
