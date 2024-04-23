import 'package:a_pixel_game/logic/game/game_controller.dart';
import 'package:a_pixel_game/logic/game/lobby_state.dart';
import 'package:a_pixel_game/logic/team_manager.dart';
import 'package:a_pixel_game/theme/buttons.dart';
import 'package:a_pixel_game/theme/duration_renderer.dart';
import 'package:a_pixel_game/theme/list_selection.dart';
import 'package:a_pixel_game/theme/textfield.dart';
import 'package:a_pixel_game/theme/transition_container.dart';
import 'package:a_pixel_game/theme/window_base.dart';
import 'package:a_pixel_game/vertical_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

final showQrCode = false.obs;

class LobbyPage extends StatefulWidget {
  const LobbyPage({super.key});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.theme.colorScheme.background,
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: TransitionContainer(
                tag: "lobby",
                color: Get.theme.colorScheme.onBackground,
                borderRadius: BorderRadius.circular(sectionSpacing),
                width: 800,
                child: Padding(
                  padding: const EdgeInsets.all(sectionSpacing),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(() {
                        final manager = Get.find<TeamManager>();
                        final spectators = manager.teams[TeamType.spectator]?.length ?? 0;
                        final players = (manager.teams[TeamType.blue]?.length ?? 0) + (manager.teams[TeamType.red]?.length ?? 0);

                        if (GameController.currentGameState.value != GameStateType.lobby) {
                          return Text("Waiting for server..", style: Get.theme.textTheme.headlineMedium);
                        }
                        final lobbyState = GameController.currentState as LobbyState;
                        if (lobbyState.countdown.value) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("$players players, starting in ", style: Get.theme.textTheme.headlineMedium),
                              DurationRenderer(lobbyState.countdownEnd.value, style: Get.theme.textTheme.headlineMedium),
                              Text(".. ($spectators watching)", style: Get.theme.textTheme.headlineMedium),
                            ],
                          );
                        }

                        if (players >= 2) {
                          return Text("$players players, $spectators spectating..", style: Get.theme.textTheme.headlineMedium);
                        }

                        return Text("$players/2 players, $spectators spectating..", style: Get.theme.textTheme.headlineMedium);
                      }),
                      verticalSpacing(sectionSpacing),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 400,
                              child: Material(
                                color: Get.theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(sectionSpacing),
                                child: InkWell(
                                  onTap: () {
                                    if (Get.find<TeamManager>().ownTeam.value == TeamType.blue) {
                                      GameController.joinTeam(TeamType.spectator);
                                    } else {
                                      GameController.joinTeam(TeamType.blue);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(sectionSpacing),
                                  child: Center(
                                    child: Obx(() {
                                      final manager = Get.find<TeamManager>();
                                      final team = manager.teams[TeamType.blue];
                                      if (team == null || team.isEmpty) {
                                        return Padding(
                                          padding: const EdgeInsets.all(sectionSpacing * 3),
                                          child: Text(
                                            "Click to join the team.",
                                            textAlign: TextAlign.center,
                                            style: Get.theme.textTheme.headlineMedium!,
                                          ),
                                        );
                                      }

                                      return ListView.builder(
                                        itemCount: team.length,
                                        shrinkWrap: true,
                                        itemBuilder: (context, index) {
                                          return Center(
                                            child: Padding(
                                              padding: EdgeInsets.only(bottom: index != 0 ? defaultSpacing : 0),
                                              child: Obx(
                                                () => Text(
                                                  manager.players[team[index]]!.name.value,
                                                  style: Get.theme.textTheme.headlineMedium!.copyWith(color: Get.theme.colorScheme.onPrimary),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          horizontalSpacing(sectionSpacing),
                          Expanded(
                            child: SizedBox(
                              height: 400,
                              child: Material(
                                color: Get.theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(sectionSpacing),
                                child: InkWell(
                                  onTap: () {
                                    if (Get.find<TeamManager>().ownTeam.value == TeamType.red) {
                                      GameController.joinTeam(TeamType.spectator);
                                    } else {
                                      GameController.joinTeam(TeamType.red);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(sectionSpacing),
                                  child: Center(
                                    child: Obx(() {
                                      final manager = Get.find<TeamManager>();
                                      final team = manager.teams[TeamType.red];
                                      if (team == null || team.isEmpty) {
                                        return Padding(
                                          padding: const EdgeInsets.all(sectionSpacing * 3),
                                          child: Text(
                                            "Click to join the team.",
                                            textAlign: TextAlign.center,
                                            style: Get.theme.textTheme.headlineMedium!,
                                          ),
                                        );
                                      }

                                      return ListView.builder(
                                        itemCount: team.length,
                                        shrinkWrap: true,
                                        itemBuilder: (context, index) {
                                          return Center(
                                            child: Padding(
                                              padding: EdgeInsets.only(bottom: index != 0 ? defaultSpacing : 0),
                                              child: Obx(
                                                () => Text(
                                                  manager.players[team[index]]!.name.value,
                                                  style: Get.theme.textTheme.headlineMedium!.copyWith(color: Get.theme.colorScheme.error),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      verticalSpacing(sectionSpacing),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          LPElevatedButton(
                            onTap: () => Get.dialog(const SettingsWindow()),
                            child: Padding(
                              padding: const EdgeInsets.all(elementSpacing),
                              child: Center(
                                child: Text("Settings", style: Get.theme.textTheme.labelLarge),
                              ),
                            ),
                          ),
                          Obx(() {
                            final manager = Get.find<TeamManager>();
                            final team = manager.teams[TeamType.spectator];
                            if (team == null || team.contains(GameController.ownId)) {
                              bool qrCode = showQrCode.value;
                              return LPElevatedButton(
                                onTap: () => showQrCode.value = !showQrCode.value,
                                child: Padding(
                                  padding: const EdgeInsets.all(elementSpacing),
                                  child: Center(
                                    child: Text(qrCode ? "Hide QR Code" : "Show QR Code", style: Get.theme.textTheme.labelLarge),
                                  ),
                                ),
                              );
                            }

                            return LPElevatedButton(
                              onTap: () => GameController.joinTeam(TeamType.spectator),
                              child: Padding(
                                padding: const EdgeInsets.all(elementSpacing),
                                child: Center(
                                  child: Text("Leave team", style: Get.theme.textTheme.labelLarge),
                                ),
                              ),
                            );
                          }),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
            Obx(() {
              if (showQrCode.value) {
                return Padding(
                  padding: const EdgeInsets.only(left: sectionSpacing),
                  child: Container(
                    padding: const EdgeInsets.all(sectionSpacing),
                    decoration: BoxDecoration(
                      color: Get.theme.colorScheme.onBackground,
                      borderRadius: BorderRadius.circular(sectionSpacing),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Scan to join the game!", style: Get.theme.textTheme.labelLarge),
                        verticalSpacing(sectionSpacing),
                        SizedBox(
                          width: 200,
                          child: PrettyQrView.data(
                            data: "http://${Uri.base.host}",
                            decoration: PrettyQrDecoration(
                              shape: PrettyQrRoundedSymbol(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(0),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox();
            })
          ],
        ),
      ),
    );
  }
}

class SettingsWindow extends StatefulWidget {
  const SettingsWindow({super.key});

  @override
  State<SettingsWindow> createState() => _SettingsWindowState();
}

class _SettingsWindowState extends State<SettingsWindow> {
  final _nameController = TextEditingController();

  // Game mode setting
  final selectedGameMode = 0.obs;
  final gameModes = <SelectableItem>[
    const SelectableItem("Vanilla", Icons.sports_score),
    const SelectableItem("Overdrive", Icons.electric_bolt),
    const SelectableItem("Pong (literally)", Icons.sports_soccer, experimental: true),
    const SelectableItem("Escape", Icons.directions_run, experimental: true),
  ];

  // Mana setting
  final selectedManaRegen = 1.obs;
  final manaRegenMode = <SelectableItem>[
    const SelectableItem("Slow af", Icons.fast_rewind),
    const SelectableItem("Vanilla", Icons.play_arrow),
    const SelectableItem("Fast", Icons.fast_forward),
    const SelectableItem("Overdrive", Icons.electric_bolt, experimental: true),
  ];

  @override
  void initState() {
    _nameController.text = GameController.ownName.value;
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DialogBase(
      maxWidth: 500,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Game settings", style: Get.theme.textTheme.headlineMedium),
            verticalSpacing(sectionSpacing),
            Text("Change your username", style: Get.theme.textTheme.bodyLarge),
            verticalSpacing(defaultSpacing),
            LPTextField(
              hintText: "Your username",
              controller: _nameController,
              maxLength: 20,
              onSubmit: (text) {
                GameController.changeUsername(text);
              },
              onEditFinished: () {
                GameController.changeUsername(_nameController.text);
              },
            ),
            verticalSpacing(sectionSpacing),

            // Mana flow selection
            Text("Choose how fast mana regenerates", style: Get.theme.textTheme.bodyLarge),
            verticalSpacing(defaultSpacing),
            ListSelection(selected: selectedManaRegen, items: manaRegenMode),
            verticalSpacing(sectionSpacing),

            // Game mode selection
            Text("Choose a gamemode", style: Get.theme.textTheme.bodyLarge),
            verticalSpacing(defaultSpacing),
            ListSelection(selected: selectedGameMode, items: gameModes),
          ],
        ),
      ),
    );
  }
}
