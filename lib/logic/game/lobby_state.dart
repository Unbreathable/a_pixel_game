import 'package:a_pixel_game/logic/game/game_controller.dart';
import 'package:get/get.dart';

class LobbyState extends GameState {
  final countdown = false.obs;
  final countdownEnd = DateTime.now().obs;

  LobbyState(bool countdown, DateTime countdownEnd) {
    this.countdown.value = countdown;
    this.countdownEnd.value = countdownEnd;
  }

  factory LobbyState.load(dynamic data) {
    final json = data as Map<String, dynamic>;
    return LobbyState(json["started"], DateTime.fromMillisecondsSinceEpoch(json["count"]));
  }

  @override
  void handleData(data) {
    final json = data as Map<String, dynamic>;
    countdown.value = json["started"];
    countdownEnd.value = DateTime.fromMillisecondsSinceEpoch(json["count"]);
  }
}
