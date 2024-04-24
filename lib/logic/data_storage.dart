import 'package:a_pixel_game/logic/connector.dart';
import 'package:a_pixel_game/logic/team_manager.dart';
import 'package:a_pixel_game/pages/draw_page.dart';
import 'package:a_pixel_game/vertical_spacing.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DataStorage {
  // X -> Y -> Pixel
  static final grid = <int, Map<int, Pixel>>{};

  // Current line
  static bool lineAllowed = false;
  static var line = <PixelPosition>[];

  static const double maxMana = 20;
  static final currentMana = maxMana.obs;

  /// Initialize the entire grid with empty pixels
  static void initialize(int xWidth, int yWidth) {
    currentMana.value = maxMana;
    for (int x = 1; x <= 32; x++) {
      grid[x] = <int, Pixel>{};
      for (int y = 1; y <= 16; y++) {
        grid[x]![y] = Pixel(PixelPosition(x, y), PixelType.air);
      }
    }
  }

  static void newFrame(dynamic data) {
    final frameGrid = data as Map<String, dynamic>;
    grid.clear();
    for (int x = 1; x <= 32; x++) {
      final row = (frameGrid[x.toString()] ?? <String, dynamic>{}) as Map<String, dynamic>;
      grid[x] = <int, Pixel>{};
      for (int y = 1; y <= 16; y++) {
        if (row[y.toString()] != null) {
          grid[x]![y] = Pixel.fromJson(row[y.toString()]);
        } else {
          grid[x]![y] = Pixel(PixelPosition(x, y), PixelType.air);
        }
      }
    }
  }

  /// Start drawing a line
  static void startLine(PixelPosition pos) {
    if (currentMana.value <= 2) {
      lineAllowed = false;
      return;
    }

    line = <PixelPosition>[pos];
    lineAllowed = true;

    if (!checkPosition(pos)) {
      line.clear();
      lineAllowed = false;
      return;
    }

    defaultConnector.sendAction(ServerAction("start_line", <String, dynamic>{
      "x": pos.x,
      "y": pos.y,
    }));
  }

  /// Add a point to the line
  static void addToLine(PixelPosition pos) {
    if (currentMana.value <= 1) {
      return;
    }

    if (!line.contains(pos) && checkPosition(pos)) {
      line.add(pos);

      defaultConnector.sendAction(ServerAction("line_add", <String, dynamic>{
        "x": pos.x,
        "y": pos.y,
      }));
    }
  }

  /// End the line off
  static void endLine() {
    defaultConnector.sendAction(ServerAction("end_line", <String, dynamic>{}));
  }

  /// Cancel current line (called by the server)
  static void cancelLine() {
    line.clear();
    lineAllowed = false;
  }

  /// Finish current line (called by the server)
  static void finishLine() {
    line.clear();
    lineAllowed = false;
  }

  static bool checkPosition(PixelPosition position) {
    final pixel = grid[position.x]?[position.y];
    if (pixel != null && pixel.type != PixelType.air) {
      sendLog("pixel exists");
      return false;
    }

    final team = Get.find<TeamManager>().ownTeam.value;
    sendLog(team);
    if (team == TeamType.blue && (position.x < drawingAreaBlueStart || position.x > drawingAreaBlueEnd)) {
      return false;
    }
    if (team == TeamType.red && (position.x < drawingAreaRedStart || position.x > drawingAreaRedEnd)) {
      return false;
    }
    if (position.y <= 0 || position.y > 16) {
      return false;
    }

    return true;
  }
}

enum PixelType {
  air,
  blue,
  red,
  collided;

  Color getColor() {
    switch (this) {
      case air:
        return Colors.transparent;
      case blue:
        return const Color.fromARGB(255, 172, 227, 255);
      case red:
        return const Color.fromARGB(255, 255, 172, 172);
      case collided:
        return Colors.white;
    }
  }
}

class Pixel {
  final PixelPosition position;
  final PixelType type;

  Pixel(this.position, this.type);

  factory Pixel.fromJson(Map<String, dynamic> json) {
    return Pixel(PixelPosition(json["x"], json["y"]), PixelType.values[json["t"]]);
  }
}

class PixelPosition {
  static PixelPosition zero = PixelPosition(0, 0);

  final int x;
  final int y;

  PixelPosition(this.x, this.y);

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    return other is PixelPosition && other.x == x && other.y == y;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}
