import 'package:a_pixel_game/logic/connector.dart';
import 'package:a_pixel_game/logic/data_storage.dart';
import 'package:a_pixel_game/logic/team_manager.dart';
import 'package:get/get.dart';

void initializePlayerListeners() {
  defaultConnector.listen("setup", (action) {
    Get.find<TeamManager>().handleOwnData(action.data["id"], action.data["name"], action.data["state"], action.data["data"]);
  });

  defaultConnector.listen("player_join", (action) {
    Get.find<TeamManager>().handlePlayerJoin(Player(defaultTeam, action.data["id"], (action.data["name"] as String).obs));
  });

  defaultConnector.listen("player_leave", (action) {
    Get.find<TeamManager>().handlePlayerLeave(action.data["id"]);
  });

  defaultConnector.listen("player_team", (action) {
    Get.find<TeamManager>().handlePlayerTeam(action.data["id"], TeamType.values[action.data["team"]]);
  });

  defaultConnector.listen("player_change", (action) {
    Get.find<TeamManager>().handlePlayerUsername(action.data["id"], action.data["name"]);
  });

  defaultConnector.listen("mana_update", (action) {
    DataStorage.currentMana.value = action.data["mana"];
  });
}
