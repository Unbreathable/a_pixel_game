import 'package:a_pixel_game/logic/game/end_state.dart';
import 'package:a_pixel_game/logic/game/game_controller.dart';
import 'package:a_pixel_game/logic/team_manager.dart';
import 'package:a_pixel_game/theme/duration_renderer.dart';
import 'package:a_pixel_game/theme/transition_container.dart';
import 'package:a_pixel_game/vertical_spacing.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EndPage extends StatefulWidget {
  const EndPage({super.key});

  @override
  State<EndPage> createState() => _EndPageState();
}

class _EndPageState extends State<EndPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.theme.colorScheme.background,
      body: Center(
        child: TransitionContainer(
          tag: "lobby",
          color: Get.theme.colorScheme.onBackground,
          borderRadius: BorderRadius.circular(sectionSpacing),
          width: 400,
          child: Padding(
            padding: const EdgeInsets.all(sectionSpacing),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(() {
                  if (GameController.currentGameState.value != GameStateType.end) {
                    return Text("Waiting for server..", style: Get.theme.textTheme.headlineMedium);
                  }

                  final manager = Get.find<TeamManager>();
                  final state = GameController.currentState as EndState;
                  if (manager.ownTeam.value == TeamType.spectator) {
                    if (state.winner == TeamType.red) {
                      return Text("Team Red won.", style: Get.theme.textTheme.headlineMedium);
                    } else {
                      return Text("Team Blue won.", style: Get.theme.textTheme.headlineMedium);
                    }
                  }

                  if (state.winner == manager.ownTeam.value) {
                    return Text("Victory Royale.", style: Get.theme.textTheme.headlineMedium);
                  } else {
                    return Text("Take the L.", style: Get.theme.textTheme.headlineMedium);
                  }
                }),
                verticalSpacing(sectionSpacing),
                Builder(builder: (context) {
                  final manager = Get.find<TeamManager>();
                  final state = GameController.currentState as EndState;
                  if (manager.ownTeam.value == TeamType.spectator) {
                    if (state.winner == TeamType.red) {
                      return Text("Seems like the communists took over, what a shame.", style: Get.theme.textTheme.bodyLarge);
                    } else {
                      return Text("I don't know what to say about blue, so here is an ad instead: Go to https://liphium.com.", style: Get.theme.textTheme.bodyLarge);
                    }
                  }

                  if (state.winner == manager.ownTeam.value) {
                    return Text(
                      "Well, congratulations for winning. You should be proud, but I'm not giving you anything for it lol",
                      style: Get.theme.textTheme.bodyLarge,
                    );
                  } else {
                    return Text(
                      "Imagine losing, couldn't be me. Or was I the person who just lost? Only future me will know.",
                      style: Get.theme.textTheme.bodyLarge,
                    );
                  }
                }),
                verticalSpacing(defaultSpacing),
                Obx(() {
                  if (GameController.currentGameState.value != GameStateType.end) {
                    return Text(
                      "The server do be kinda slow today..",
                      style: Get.theme.textTheme.bodyLarge,
                    );
                  }

                  final state = GameController.currentState as EndState;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Starting another lobby in ",
                        style: Get.theme.textTheme.labelLarge,
                      ),
                      DurationRenderer(state.countdownEnd, style: Get.theme.textTheme.labelLarge),
                      Text(
                        "..",
                        style: Get.theme.textTheme.labelLarge,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
