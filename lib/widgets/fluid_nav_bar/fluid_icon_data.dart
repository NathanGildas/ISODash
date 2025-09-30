import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class FluidFillIconData {
  final List<ui.Path> paths;
  FluidFillIconData(this.paths);
}

class FluidFillIcons {
  // Dashboard icon - squares arrangement
  static final dashboard = FluidFillIconData([
    ui.Path()..addRRect(RRect.fromLTRBXY(-12, -12, -2, -2, 2, 2)),
    ui.Path()..addRRect(RRect.fromLTRBXY(2, -12, 12, -2, 2, 2)),
    ui.Path()..addRRect(RRect.fromLTRBXY(-12, 2, -2, 12, 2, 2)),
    ui.Path()..addRRect(RRect.fromLTRBXY(2, 2, 12, 12, 2, 2)),
  ]);

  // Evolution icon - trending up arrow with line
  static final evolution = FluidFillIconData([
    ui.Path()..moveTo(-12, 8)..lineTo(-4, 2)..lineTo(4, -4)..lineTo(12, -10),
    ui.Path()..moveTo(6, -10)..lineTo(12, -10)..lineTo(12, -4),
  ]);

  // Export icon - download arrow with line
  static final export = FluidFillIconData([
    ui.Path()..moveTo(0, -12)..lineTo(0, 8),
    ui.Path()..moveTo(-6, 2)..lineTo(0, 8)..lineTo(6, 2),
    ui.Path()..moveTo(-10, 12)..lineTo(10, 12),
  ]);

  // Diagnostic icon - medical cross with pulse line
  static final diagnostic = FluidFillIconData([
    ui.Path()..addRect(Rect.fromCenter(center: Offset.zero, width: 20, height: 6)),
    ui.Path()..addRect(Rect.fromCenter(center: Offset.zero, width: 6, height: 20)),
    ui.Path()..moveTo(-12, 6)..lineTo(-8, 6)..lineTo(-6, -2)..lineTo(-4, 10)..lineTo(-2, -6)..lineTo(0, 6)..lineTo(4, 6),
  ]);

  // API icon - connection nodes
  static final api = FluidFillIconData([
    ui.Path()..addOval(Rect.fromCenter(center: Offset(-8, -8), width: 6, height: 6)),
    ui.Path()..addOval(Rect.fromCenter(center: Offset(8, -8), width: 6, height: 6)),
    ui.Path()..addOval(Rect.fromCenter(center: Offset(0, 8), width: 6, height: 6)),
    ui.Path()..moveTo(-8, -8)..lineTo(8, -8),
    ui.Path()..moveTo(-4, -4)..lineTo(0, 8),
    ui.Path()..moveTo(4, -4)..lineTo(0, 8),
  ]);

  // Settings icon - gear
  static final settings = FluidFillIconData([
    ui.Path()..addOval(Rect.fromCenter(center: Offset.zero, width: 6, height: 6)),
    ui.Path()..addRect(Rect.fromCenter(center: Offset(0, -12), width: 4, height: 6)),
    ui.Path()..addRect(Rect.fromCenter(center: Offset(0, 12), width: 4, height: 6)),
    ui.Path()..addRect(Rect.fromCenter(center: Offset(-12, 0), width: 6, height: 4)),
    ui.Path()..addRect(Rect.fromCenter(center: Offset(12, 0), width: 6, height: 4)),
    ui.Path()..addRect(Rect.fromCenter(center: Offset(-8, -8), width: 4, height: 4)),
    ui.Path()..addRect(Rect.fromCenter(center: Offset(8, -8), width: 4, height: 4)),
    ui.Path()..addRect(Rect.fromCenter(center: Offset(-8, 8), width: 4, height: 4)),
    ui.Path()..addRect(Rect.fromCenter(center: Offset(8, 8), width: 4, height: 4)),
  ]);
}