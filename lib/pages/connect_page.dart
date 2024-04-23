import 'package:a_pixel_game/logic/connector.dart';
import 'package:a_pixel_game/logic/team_manager.dart';
import 'package:a_pixel_game/theme/buttons.dart';
import 'package:a_pixel_game/theme/error_container.dart';
import 'package:a_pixel_game/theme/textfield.dart';
import 'package:a_pixel_game/theme/transition_container.dart';
import 'package:a_pixel_game/vertical_spacing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final _loading = false.obs;
  final _error = "".obs;
  final _address = TextEditingController();

  @override
  void initState() {
    if (kIsWeb) {
      _address.text = Uri.base.host;
    } else {
      _address.text = "localhost";
    }
    super.initState();
  }

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
                Text("Connect to a server.", style: Get.theme.textTheme.headlineMedium),
                verticalSpacing(defaultSpacing),
                Text(
                  "We couldn't find a server on your local network. Please try entering the server address below.",
                  style: Get.theme.textTheme.bodyMedium,
                ),
                verticalSpacing(sectionSpacing),
                LPTextField(
                  controller: _address,
                  hintText: "Server address",
                ),
                verticalSpacing(defaultSpacing),
                AnimatedErrorContainer(
                  padding: const EdgeInsets.only(bottom: defaultSpacing),
                  message: _error,
                  expand: true,
                ),
                LPElevatedLoadingButton(
                  loading: _loading,
                  onTap: () async {
                    if (_loading.value) return;

                    // Reset everything
                    Get.find<TeamManager>().players.clear();
                    Get.find<TeamManager>().teams.clear();
                    Get.find<TeamManager>().ownTeam.value = TeamType.spectator;

                    _loading.value = true;
                    final result = await defaultConnector.connect(_address.text);

                    // Show error
                    if (!result) {
                      _error.value = "Couldn't connect to the server.";
                      _loading.value = false;
                      return;
                    }

                    // Instructions should be received from the server from here..
                    _error.value = "";
                  },
                  label: "Connect",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
