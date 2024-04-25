import 'package:a_pixel_game/logic/connector.dart';
import 'package:a_pixel_game/theme/list_selection.dart';
import 'package:a_pixel_game/vertical_spacing.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingManager {
  // Setting names
  static const gameMode = "mode";
  static const gameSpeed = "mode.speed";
  static const manaRegenSpeed = "mana.speed";

  // Game mode setting
  static final gameModes = <SelectableItem>[
    const SelectableItem("Painters", Icons.brush),
    const SelectableItem("Bouncers", Icons.sports_soccer),
    const SelectableItem("Party", Icons.celebration),
  ];

  // Game speed setting
  static final gameSpeeds = <SelectableItem>[
    const SelectableItem("Slow af", Icons.fast_rewind),
    const SelectableItem("Vanilla", Icons.play_arrow),
    const SelectableItem("Fast", Icons.fast_forward),
    const SelectableItem("Overdrive", Icons.electric_bolt),
  ];

  // Mana setting
  static final manaRegenMode = <SelectableItem>[
    const SelectableItem("Slow af", Icons.fast_rewind),
    const SelectableItem("Vanilla", Icons.play_arrow),
    const SelectableItem("Fast", Icons.fast_forward),
    const SelectableItem("Overdrive", Icons.electric_bolt),
    const SelectableItem("Unlimited", Icons.all_inclusive),
  ];

  static Map<String, Setting> settingMap = <String, Setting>{};

  static void init() {
    settingMap[gameMode] = Setting<int>(gameMode, 0);
    settingMap[gameSpeed] = Setting<int>(gameSpeed, 1);
    settingMap[manaRegenSpeed] = Setting<int>(manaRegenSpeed, 1);
  }

  static void setValue(String name, dynamic value) {
    if (settingMap[name] != null) {
      sendLog("already there");
      settingMap[name]!.value.value = value;
      return;
    }
    settingMap[name] = Setting(name, value);
  }

  static void updateValue(String name, dynamic value) {
    defaultConnector.sendAction(ServerAction("update_setting", <String, dynamic>{
      "id": name,
      "value": value,
    }));
  }
}

class Setting<T> {
  final String name;
  late final Rx<T> value;

  Setting(this.name, T value) {
    this.value = Rx<T>(value);
  }
}
