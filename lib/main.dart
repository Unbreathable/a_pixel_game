import 'package:a_pixel_game/logic/connector.dart';
import 'package:a_pixel_game/logic/setting_manager.dart';
import 'package:a_pixel_game/logic/team_manager.dart';
import 'package:a_pixel_game/pages/connect_page.dart';
import 'package:a_pixel_game/theme/theme_manager.dart';
import 'package:a_pixel_game/theme/transition_container.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  Get.put(TransitionController());
  Get.put(ThemeManager());
  Get.put(TeamManager());
  SettingManager.init();
  initializeListeners();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetX<ThemeManager>(builder: (manager) {
      return GetMaterialApp(
        title: 'a_pixel_game',
        theme: manager.currentTheme.value,
        locale: Get.deviceLocale,
        fallbackLocale: const Locale("en", "US"),
        home: const ConnectPage(),
        debugShowCheckedModeBanner: false,
      );
    });
  }
}
