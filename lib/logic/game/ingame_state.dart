import 'dart:math';

import 'package:a_pixel_game/logic/game/game_controller.dart';

class IngameState extends GameState {
  DateTime start;
  int blueHealth;
  int redHealth;

  IngameState(this.start, this.blueHealth, this.redHealth);

  factory IngameState.load(dynamic data) {
    final json = data as Map<String, dynamic>;
    return IngameState(DateTime.fromMillisecondsSinceEpoch(json["start"]), json["blue"], json["red"]);
  }

  @override
  void handleData(data) {
    final json = data as Map<String, dynamic>;
    start = DateTime.fromMillisecondsSinceEpoch(json["start"]);
    blueHealth = max(json["blue"], 0);
    redHealth = max(json["red"], 0);
  }
}
