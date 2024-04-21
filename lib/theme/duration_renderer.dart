import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class DurationRenderer extends StatelessWidget {
  final DateTime end;
  final current = const Duration(seconds: 0).obs;
  final TextStyle? style;

  DurationRenderer(this.end, {this.style, super.key});

  @override
  Widget build(BuildContext context) {
    current.value = end.difference(DateTime.now());
    Timer.periodic(const Duration(seconds: 1), (timer) => current.value = end.difference(DateTime.now()));

    return RepaintBoundary(child: Obx(() {
      final duration = current.value;
      final hours = duration.inHours;
      final minutes = duration.inMinutes - (hours * 60);
      final seconds = duration.inSeconds - (minutes * 60) - (hours * 60 * 60);

      return Text((max(seconds, 0)).toString(), style: style);
    }));
  }
}

class StartRenderer extends StatelessWidget {
  final DateTime start;
  final current = const Duration(seconds: 0).obs;
  final TextStyle? style;

  StartRenderer(this.start, {this.style, super.key});

  @override
  Widget build(BuildContext context) {
    current.value = DateTime.now().difference(start);
    Timer.periodic(const Duration(seconds: 1), (timer) => current.value = DateTime.now().difference(start));

    return RepaintBoundary(child: Obx(() {
      final duration = current.value;
      final hours = duration.inHours;
      final minutes = duration.inMinutes - (hours * 60);
      final seconds = duration.inSeconds - (minutes * 60) - (hours * 60 * 60);

      if (hours > 0) {
        return Text("${hours.toString().padLeft(2, "0")}:${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}", style: style);
      }
      return Text("${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}", style: style);
    }));
  }
}
