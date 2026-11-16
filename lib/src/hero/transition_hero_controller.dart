import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

/// GetX controller managing the visibility and flight state of a [TransitionHero].
class TransitionHeroController extends GetxController {
  final RxBool isFlying = false.obs;

  void setFlying(bool value) {
    if (isFlying.value == value) return;

    final phase = WidgetsBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks || phase == SchedulerPhase.midFrameMicrotasks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isFlying.value != value) {
          isFlying.value = value;
        }
      });
    } else {
      isFlying.value = value;
    }
  }
}
