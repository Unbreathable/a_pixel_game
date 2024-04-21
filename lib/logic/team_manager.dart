import 'package:a_pixel_game/logic/game/game_controller.dart';
import 'package:a_pixel_game/vertical_spacing.dart';
import 'package:get/get.dart';

// Config
const defaultTeam = TeamType.spectator;

class TeamManager extends GetxController {
  final players = <String, Player>{}.obs;
  final teams = <TeamType, List<String>>{}.obs;
  final ownTeam = TeamType.spectator.obs;

  void handleOwnData(String id, String username, int state, dynamic data) {
    GameController.ownId = id;
    GameController.ownName.value = username;
    GameController.loadGameState(GameStateType.values[state], data);
  }

  void handlePlayerJoin(Player player) {
    players[player.id] = player;

    // Add the player to the corresponding team
    if (teams[player.team] == null) {
      teams[player.team] = <String>[player.id];
    } else {
      teams[player.team]!.add(player.id);
      teams.refresh();
    }
  }

  void handlePlayerLeave(String id) {
    if (players[id] == null) return;
    final player = players[id]!;

    // Remove from team
    final team = teams[player.team]!;
    team.removeWhere((element) => element == id);
    teams.refresh();

    // Remove from list
    players.remove(id);
  }

  void handlePlayerTeam(String id, TeamType type) {
    if (players[id] == null) return;
    final player = players[id]!;

    // Remove from team
    final team = teams[player.team]!;
    team.removeWhere((element) => element == id);

    // Add to new team
    player.team = type;
    if (teams[player.team] == null) {
      teams[player.team] = <String>[player.id];
    } else {
      teams[player.team]!.add(player.id);
      sendLog(player.team);
      teams.refresh();
    }
  }

  void handlePlayerUsername(String id, String username) {
    final player = players[id]!;
    player.name.value = username;
  }
}

enum TeamType {
  spectator("Spectator"),
  blue("Blue"),
  red("Red");

  final String name;

  const TeamType(this.name);
}

class Player {
  TeamType team;
  final String id;
  final RxString name;

  Player(this.team, this.id, this.name);
}
