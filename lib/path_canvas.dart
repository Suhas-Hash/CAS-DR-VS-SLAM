import 'package:flutter/material.dart';
import 'dart:math';

class PathCanvas extends StatelessWidget {
  final List<Offset> drPath;
  final List<Offset> gpsPath;
  final Rect sharedBounds;

  const PathCanvas({
    super.key,
    required this.drPath,
    required this.gpsPath,
    required this.sharedBounds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: CustomPaint(
        painter: PathPainter(
          drPath: drPath,
          gpsPath: gpsPath,
          bounds: sharedBounds,
        ),
        child: Container(), // Ensures the CustomPaint fills the space
      ),
    );
  }
}

class PathPainter extends CustomPainter {
  final List<Offset> drPath;
  final List<Offset> gpsPath;
  final Rect bounds;

  final Paint drPaint = Paint()
    ..color = Colors.orange
    ..strokeWidth = 3.0
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  final Paint gpsPaint = Paint()
    ..color = Colors.green
    ..strokeWidth = 3.0
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  PathPainter({
    required this.drPath,
    required this.gpsPath,
    required this.bounds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Determine scale based on shared bounds
    final double pathWidth = bounds.width;
    final double pathHeight = bounds.height;

    final double scaleX = size.width / pathWidth;
    final double scaleY = size.height / pathHeight;
    final double scale = min(scaleX, scaleY) * 0.9; // Use 90% of screen

    // Calculate offset to center the combined bounds
    final double offsetX =
        (size.width - bounds.width * scale) / 2 - (bounds.left * scale);
    final double offsetY =
        (size.height - bounds.height * scale) / 2 - (bounds.top * scale);

    // --- Draw DR Path (Orange) ---
    if (drPath.length > 1) {
      final Path displayPath = Path();
      displayPath.moveTo(
        drPath.first.dx * scale + offsetX,
        drPath.first.dy * scale + offsetY,
      );
      for (int i = 1; i < drPath.length; i++) {
        displayPath.lineTo(
          drPath[i].dx * scale + offsetX,
          drPath[i].dy * scale + offsetY,
        );
      }
      canvas.drawPath(displayPath, drPaint);
    }

    // --- Draw GPS Path (Green) ---
    if (gpsPath.length > 1) {
      final Path displayPath = Path();
      displayPath.moveTo(
        gpsPath.first.dx * scale + offsetX,
        gpsPath.first.dy * scale + offsetY,
      );
      for (int i = 1; i < gpsPath.length; i++) {
        displayPath.lineTo(
          gpsPath[i].dx * scale + offsetX,
          gpsPath[i].dy * scale + offsetY,
        );
      }
      canvas.drawPath(displayPath, gpsPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PathPainter old) {
    // Repaint if either path or the bounds have changed
    return drPath.length != old.drPath.length ||
        gpsPath.length != old.gpsPath.length ||
        bounds != old.bounds;
  }
}
