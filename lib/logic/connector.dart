import 'dart:convert';

import 'package:a_pixel_game/logic/listeners/game_listeners.dart';
import 'package:a_pixel_game/logic/listeners/player_listeners.dart';
import 'package:a_pixel_game/pages/connect_page.dart';
import 'package:a_pixel_game/theme/transition_container.dart';
import 'package:a_pixel_game/vertical_spacing.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// The connector used for the game
final Connector defaultConnector = Connector();

class ServerAction {
  final String name;
  final Map<String, dynamic> data;

  ServerAction(this.name, this.data);

  factory ServerAction.fromJson(String json) {
    final decoded = jsonDecode(json);
    return ServerAction(decoded["n"], decoded["d"]);
  }

  String toJson() => jsonEncode({
        "n": name,
        "d": data,
      });
}

class Connector {
  // Data
  WebSocketChannel? channel;
  final _listeners = <String, Function(ServerAction)>{};

  Future<bool> connect(String ip) async {
    var port = 54321;

    // Check if a port is included
    final args = ip.split(":");
    if (args.length > 1) {
      ip = args[0];
      port = int.parse(args[1]);
    }

    try {
      channel = WebSocketChannel.connect(Uri.parse("ws://$ip:$port"));
      await channel!.ready;

      // Listen to events streamed from the server
      channel!.stream.listen(
        (data) {
          final action = ServerAction.fromJson(data);
          if (action.name != "game_frame" && action.name != "pong_position") {
            sendLog(action.name);
          }

          final listener = _listeners[action.name];
          if (listener != null) {
            listener.call(action);
          }
        },
        onDone: () {
          Get.find<TransitionController>().modelTransition(const ConnectPage());
          sendLog("disconnect");
        },
      );
    } catch (e) {
      sendLog("error with connection $e");
      return false;
    }

    return true;
  }

  // Listen to a server action based on name
  void listen(String action, Function(ServerAction) handler) {
    _listeners[action] = handler;
  }

  // Send an action to the server
  void sendAction(ServerAction action) {
    if (channel == null) return;

    // Send the action as an encoded JSON
    channel!.sink.add(action.toJson());
  }
}

/// Initialize all listeners and add them to the connector
void initializeListeners() {
  initializePlayerListeners();
  initializeGameListeners();
}
