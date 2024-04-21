import 'package:a_pixel_game/logic/connector.dart';
import 'package:a_pixel_game/logic/data_storage.dart';
import 'package:a_pixel_game/logic/game/game_controller.dart';

void initializeGameListeners() {
  defaultConnector.listen("game_new", (action) {
    GameController.loadGameState(GameStateType.values[action.data["state"]], action.data["data"]);
  });

  defaultConnector.listen("game_update", (action) {
    GameController.updateGameState(action.data["data"]);
  });

  defaultConnector.listen("line_failed", (action) {
    DataStorage.cancelLine();
  });

  defaultConnector.listen("line_finished", (action) {
    DataStorage.finishLine();
  });

  defaultConnector.listen("game_frame", (action) {
    DataStorage.newFrame(action.data["frame"]);
  });
}
