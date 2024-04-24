import 'package:a_pixel_game/logic/connector.dart';
import 'package:a_pixel_game/vertical_spacing.dart';
import 'package:get/get.dart';

class SettingManager {
  // Setting names
  static const gameMode = "mode";
  static const gameSpeed = "mode.speed";
  static const manaRegenSpeed = "mana.speed";

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
