import 'package:a_pixel_game/logic/game/game_controller.dart';
import 'package:a_pixel_game/logic/team_manager.dart';

class EndState extends GameState {
  TeamType winner;
  DateTime countdownEnd;

  EndState(this.winner, this.countdownEnd);

  factory EndState.load(dynamic data) {
    final json = data as Map<String, dynamic>;
    return EndState(TeamType.values[json["team"]], DateTime.fromMillisecondsSinceEpoch(json["count"]));
  }

  @override
  void handleData(data) {
    // There should never be any
  }
}
