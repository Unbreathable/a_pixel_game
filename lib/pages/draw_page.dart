import 'dart:async';

import 'package:a_pixel_game/logic/data_storage.dart';
import 'package:a_pixel_game/logic/game/game_controller.dart';
import 'package:a_pixel_game/logic/game/ingame_state.dart';
import 'package:a_pixel_game/logic/team_manager.dart';
import 'package:a_pixel_game/theme/duration_renderer.dart';
import 'package:a_pixel_game/vertical_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

// Config
const xSize = 32;
const ySize = 16;
const frameRate = 50;
const drawingAreaBlueStart = 2;
const drawingAreaBlueEnd = 11;
const drawingAreaRedStart = 22;
const drawingAreaRedEnd = 31;

class DrawPage extends StatefulWidget {
  const DrawPage({super.key});

  @override
  State<DrawPage> createState() => _DrawPageState();
}

class _DrawPageState extends State<DrawPage> {
  final GlobalKey key = GlobalKey();
  final updater = false.obs;
  PixelPosition? mousePos;

  @override
  void initState() {
    super.initState();
    DataStorage.initialize(xSize, ySize);
    Timer.periodic((1000 / frameRate).ms, (timer) {
      updater.value = !updater.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.theme.colorScheme.primaryContainer,
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              key: key,
              aspectRatio: xSize / ySize,
              child: ClipRect(
                child: Listener(
                  onPointerDown: (event) {
                    final ownTeam = Get.find<TeamManager>().ownTeam.value;
                    if (ownTeam == TeamType.spectator) {
                      return;
                    }

                    DataStorage.startLine(getPixelPos(event.localPosition));
                  },
                  onPointerMove: (event) {
                    final ownTeam = Get.find<TeamManager>().ownTeam.value;
                    if (ownTeam == TeamType.spectator) {
                      return;
                    }

                    if (!DataStorage.lineAllowed) {
                      return;
                    }
                    final pos = getPixelPos(event.localPosition);
                    mousePos = pos;
                    DataStorage.addToLine(pos);
                  },
                  onPointerUp: (event) {
                    final ownTeam = Get.find<TeamManager>().ownTeam.value;
                    if (ownTeam == TeamType.spectator) {
                      return;
                    }

                    if (!DataStorage.lineAllowed) {
                      return;
                    }
                    DataStorage.endLine();
                  },
                  child: RepaintBoundary(
                    child: Obx(() {
                      updater.value;
                      return CustomPaint(
                        painter: GamePainter(mousePos ?? PixelPosition.zero),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(defaultSpacing),
              child: Container(
                decoration: BoxDecoration(
                  color: Get.theme.colorScheme.background.withAlpha(200),
                  borderRadius: BorderRadius.circular(sectionSpacing),
                  border: Border.all(color: Colors.white.withAlpha(25)),
                ),
                padding: const EdgeInsets.all(defaultSpacing),
                width: 200 + defaultSpacing * 2,
                height: 40,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: RepaintBoundary(
                    child: Obx(
                      () => AnimatedContainer(
                        curve: Curves.ease,
                        duration: 250.ms,
                        decoration: BoxDecoration(
                          color: Get.theme.colorScheme.onPrimary.withAlpha(200),
                          borderRadius: BorderRadius.circular(defaultSpacing),
                        ),
                        width: 200 * (DataStorage.currentMana.value / DataStorage.maxMana),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(defaultSpacing),
              child: Container(
                decoration: BoxDecoration(
                  color: Get.theme.colorScheme.background.withAlpha(200),
                  borderRadius: BorderRadius.circular(sectionSpacing),
                  border: Border.all(color: Colors.white.withAlpha(25)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: sectionSpacing, vertical: defaultSpacing),
                child: StartRenderer(
                  (GameController.currentState as IngameState).start,
                  style: Get.theme.textTheme.headlineMedium,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  PixelPosition getPixelPos(Offset localPos) {
    final pixelSize = key.currentContext!.size!.width / xSize;
    final pixelX = (localPos.dx / pixelSize).floor();
    final pixelY = (localPos.dy / pixelSize).floor();
    return PixelPosition(pixelX + 1, pixelY + 1);
  }
}

class GamePainter extends CustomPainter {
  final PixelPosition mousePos;

  GamePainter(this.mousePos);

  @override
  void paint(Canvas canvas, Size size) {
    final pixelSize = size.width / xSize;
    final rect = Rect.fromLTWH(0, 0, pixelSize + 1, pixelSize + 1); // Increase size by 1 to overlap
    final paint = Paint();
    final ownTeam = Get.find<TeamManager>().ownTeam.value;

    for (int x = 1; x <= xSize; x++) {
      for (int y = 1; y <= ySize; y++) {
        final pixel = DataStorage.grid[x]![y]!;
        if (pixel.type == PixelType.air && !DataStorage.line.contains(pixel.position)) {
          paint.color = (x + y) % 2 == 0 ? Get.theme.colorScheme.background : Get.theme.colorScheme.onBackground;
          if (x >= drawingAreaBlueStart && x <= drawingAreaBlueEnd && ownTeam == TeamType.blue) {
            paint.color = addBlueTint(paint.color);
          } else if (x >= drawingAreaRedStart && x <= drawingAreaRedEnd && ownTeam == TeamType.red) {
            paint.color = addRedTint(paint.color);
          }
          canvas.drawRect(rect.shift(Offset((x - 1) * pixelSize, (y - 1) * pixelSize)), paint);
          continue;
        }

        paint.color = DataStorage.line.contains(pixel.position) ? Colors.white : pixel.type.getColor();
        canvas.drawRect(rect.shift(Offset((x - 1) * pixelSize, (y - 1) * pixelSize)), paint);
      }
    }

    //drawCrosshair(canvas, pixelSize);

    // Draw the goals
    if (GameController.currentState is! IngameState) {
      return;
    }
    final state = GameController.currentState as IngameState;
    final blueGoalBg = Paint()..color = Get.theme.colorScheme.primary;
    final blueGoalHealth = Paint()..color = Get.theme.colorScheme.onPrimary;
    final redGoalBg = Paint()..color = Get.theme.colorScheme.errorContainer;
    final redGoalHealth = Paint()..color = Get.theme.colorScheme.error;

    // Draw goal for team blue
    var healthPercentage = state.blueHealth.toDouble() / 100.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, pixelSize, size.height), blueGoalBg);
    canvas.drawRect(Rect.fromLTWH(0, (size.height / 2) - (size.height / 2) * healthPercentage, pixelSize, size.height * healthPercentage), blueGoalHealth);

    // Draw goal for team red
    healthPercentage = state.redHealth.toDouble() / 100.0;
    canvas.drawRect(Rect.fromLTWH(size.width - pixelSize, 0, pixelSize, size.height), redGoalBg);
    canvas.drawRect(Rect.fromLTWH(size.width - pixelSize, (size.height / 2) - (size.height / 2) * healthPercentage, pixelSize, size.height * healthPercentage), redGoalHealth);
  }

  Color addBlueTint(Color color) {
    final newBlue = (color.blue + 15).clamp(0, 255);
    return Color.fromRGBO(color.red, color.green, newBlue, 1);
  }

  Color addRedTint(Color color) {
    final newRed = (color.red + 15).clamp(0, 255);
    return Color.fromRGBO(newRed, color.green, color.blue, 1);
  }

  /*
  void drawCrosshair(Canvas canvas, double pixelSize) {
    // Compute the hovered pixel
    final hoveredRect = Rect.fromLTWH(
      (mousePos.x * pixelSize).roundToDouble(),
      (mousePos.y * pixelSize).roundToDouble(),
      pixelSize.roundToDouble(),
      pixelSize.roundToDouble(),
    );
    pixelSize = pixelSize.roundToDouble();

    // Compute all needed values
    var crosshairStrokeWidth = (pixelSize / 8).roundToDouble();
    crosshairStrokeWidth = crosshairStrokeWidth % 2 != 0 ? crosshairStrokeWidth + 1 : crosshairStrokeWidth;
    final strokeOffset = (crosshairStrokeWidth / 2).roundToDouble();
    final paint = Paint()
      ..color = Get.theme.colorScheme.primary
      ..strokeWidth = crosshairStrokeWidth;
    final gapSize = (pixelSize / 8).roundToDouble();

    // Draw the top left corner
    canvas.drawLine(hoveredRect.topLeft + Offset(0, strokeOffset), hoveredRect.topCenter - Offset(gapSize, -strokeOffset), paint); // top line
    canvas.drawLine(hoveredRect.topLeft + Offset(strokeOffset, 0), hoveredRect.centerLeft + Offset(strokeOffset, -gapSize), paint); // line towards bottom

    // Draw the bottom left corner
    canvas.drawLine(hoveredRect.bottomLeft - Offset(0, strokeOffset), hoveredRect.bottomCenter - Offset(gapSize, strokeOffset), paint); // bottom line
    canvas.drawLine(hoveredRect.bottomLeft + Offset(strokeOffset, 0), hoveredRect.centerLeft + Offset(strokeOffset, gapSize), paint); // line towards top

    // Draw the top right corner
    canvas.drawLine(hoveredRect.topRight + Offset(0, strokeOffset), hoveredRect.topCenter + Offset(gapSize, strokeOffset), paint); // top line
    canvas.drawLine(hoveredRect.topRight - Offset(strokeOffset, 0), hoveredRect.centerRight - Offset(strokeOffset, gapSize), paint); // line towards bottom

    // Draw the bottom right corner
    canvas.drawLine(hoveredRect.bottomRight - Offset(0, strokeOffset), hoveredRect.bottomCenter + Offset(gapSize, -strokeOffset), paint); // bottom line
    canvas.drawLine(hoveredRect.bottomRight - Offset(strokeOffset, 0), hoveredRect.centerRight + Offset(-strokeOffset, gapSize), paint); // line towards top
  }
  */

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
