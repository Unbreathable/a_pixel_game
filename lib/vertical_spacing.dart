import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

// The best logging framework
void sendLog(Object? object) {
  print(object);
}

const noTextHeight = TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
);

Widget verticalSpacing(double height) {
  return SizedBox(height: height);
}

Widget horizontalSpacing(double width) {
  return SizedBox(width: width);
}

const defaultSpacing = 8.0;
const elementSpacing = defaultSpacing * 0.5;
const elementSpacing2 = elementSpacing * 1.5;
const sectionSpacing = defaultSpacing * 2;
const modelBorderRadius = defaultSpacing * 1.5;
const modelPadding = defaultSpacing * 2;
const dialogBorderRadius = defaultSpacing * 1.5;
const dialogPadding = defaultSpacing * 1.5;
const scaleAnimationCurve = ElasticOutCurve(1.1);

String formatDay(DateTime time) {
  final now = DateTime.now();

  if (time.day == now.day) {
    return "time.today".tr;
  } else if (time.day == now.day - 1) {
    return "time.yesterday".tr;
  } else {
    return "time".trParams({"day": time.day.toString().padLeft(2, "0"), "month": time.month.toString().padLeft(2, "0"), "year": time.year.toString()});
  }
}

String formatMessageTime(DateTime time) {
  return "message.time".trParams({"hour": time.hour.toString().padLeft(2, "0"), "minute": time.minute.toString().padLeft(2, "0")});
}

class ExpandEffect extends CustomEffect {
  ExpandEffect({super.curve, super.duration, Axis? axis, Alignment? alignment, super.delay})
      : super(builder: (context, value, child) {
          return ClipRect(
            child: Align(
              alignment: alignment ?? Alignment.topCenter,
              heightFactor: axis == Axis.vertical ? max(value, 0.0) : null,
              widthFactor: axis == Axis.horizontal ? max(value, 0.0) : null,
              child: child,
            ),
          );
        });
}

class ReverseExpandEffect extends CustomEffect {
  ReverseExpandEffect({super.curve, super.duration, Axis? axis, Alignment? alignment, super.delay})
      : super(
          builder: (context, value, child) {
            return ClipRect(
              child: Align(
                alignment: alignment ?? Alignment.topCenter,
                heightFactor: axis == Axis.vertical ? max(1 - value, 0.0) : null,
                widthFactor: axis == Axis.horizontal ? max(1 - value, 0.0) : null,
                child: child,
              ),
            );
          },
        );
}
