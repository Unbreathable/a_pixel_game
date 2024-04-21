import 'package:a_pixel_game/theme/dark_metal_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeManager extends GetxController {
  final currentTheme = darkMetalTheme.obs;

  final brightness = Brightness.dark.obs;

  // Changes the color theme
  void changeTheme(ThemeData theme) {
    currentTheme.value = theme;
  }

  // Changes the brightness (light or dark)
  void changeBrightness(Brightness value) {
    brightness.value = value;
  }
}

class CustomTheme {
  // Theme properties
  final String name;
  final ThemeData light;
  final ThemeData dark;

  const CustomTheme(this.name, this.light, this.dark);

  ThemeData getData(Brightness brightness) => brightness == Brightness.light ? light : dark;
}
