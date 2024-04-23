import 'package:a_pixel_game/logic/connector.dart';
import 'package:a_pixel_game/logic/game/end_state.dart';
import 'package:a_pixel_game/logic/game/ingame_state.dart';
import 'package:a_pixel_game/logic/game/lobby_state.dart';
import 'package:a_pixel_game/logic/team_manager.dart';
import 'package:a_pixel_game/pages/draw_page.dart';
import 'package:a_pixel_game/pages/end_page.dart';
import 'package:a_pixel_game/pages/lobby_page.dart';
import 'package:a_pixel_game/theme/transition_container.dart';
import 'package:get/get.dart';

class GameController {
  // Player data
  static String ownId = "";
  static var ownName = "".obs;

  // Current game state
  static final currentGameState = GameStateType.lobby.obs;
  static late GameState currentState;

  static void loadGameState(GameStateType type, dynamic data) {
    currentGameState.value = type;
    switch (currentGameState.value) {
      // Load lobby state
      case GameStateType.lobby:
        currentState = LobbyState.load(data);
        Get.find<TransitionController>().modelTransition(const LobbyPage());
        break;

      // Load ingame state
      case GameStateType.ingame:
        currentState = IngameState.load(data);
        Get.offAll(const DrawPage(), transition: Transition.fade);
        break;

      // Load end state
      case GameStateType.end:
        currentState = EndState.load(data);
        Get.find<TransitionController>().modelTransition(const EndPage());
        break;
    }
  }

  static void updateGameState(dynamic data) {
    currentState.handleData(data);
  }

  static void joinTeam(TeamType type) {
    Get.find<TeamManager>().ownTeam.value = type;
    defaultConnector.sendAction(ServerAction("team_join", <String, dynamic>{
      "team": type.index,
    }));
  }

  static void changeUsername(String text) {
    if (text.trim() == "") {
      text = "I'm stupid and tried exploits.";
    }
    defaultConnector.sendAction(ServerAction("change", <String, dynamic>{
      "name": text,
    }));
  }
}

enum GameStateType {
  lobby,
  ingame,
  end;
}

abstract class GameState {
  void handleData(dynamic data);
}
