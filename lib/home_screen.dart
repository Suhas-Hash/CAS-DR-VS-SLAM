import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:slam_demo/providers.dart';
import 'package:slam_demo/widgets/path_canvas.dart';
import 'dart:math';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // Helper to calculate total path distance (in meters)
  double getPathDistance(List<Offset> path) {
    double distance = 0;
    for (int i = 0; i < path.length - 1; i++) {
      distance += (path[i + 1] - path[i]).distance;
    }
    return distance;
  }

  // Helper to get shared bounds so both paths use the same scale
  Rect getSharedBounds(List<Offset> p1, List<Offset> p2) {
    final allPoints = [...p1, ...p2];
    if (allPoints.length < 2) return Rect.fromLTWH(-1, -1, 2, 2);

    double minX = allPoints.map((p) => p.dx).reduce(min);
    double maxX = allPoints.map((p) => p.dx).reduce(max);
    double minY = allPoints.map((p) => p.dy).reduce(min);
    double maxY = allPoints.map((p) => p.dy).reduce(max);

    // Add 10% padding
    double paddingX = (maxX - minX).abs() * 0.1;
    double paddingY = (maxY - minY).abs() * 0.1;
    double padding = max(max(paddingX, paddingY), 1.0); // Ensure min padding

    return Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the states
    final pathState = ref.watch(pathControllerProvider);
    final controller = ref.read(pathControllerProvider.notifier);

    // Show a loading/error screen while waiting for GPS
    final initialGps = ref.watch(locationStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('IMU (DR) vs. GPS'),
      ),
      body: Column(
        children: [
          // 1. The Canvas (Main View)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: initialGps.when(
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Waiting for first GPS fix...'),
                      Text('Please go outdoors for best results.'),
                    ],
                  ),
                ),
                error: (err, stack) => Center(
                  child: Text('Error: ${err.toString()}',
                      textAlign: TextAlign.center),
                ),
                data: (_) {
                  // GPS is active, show the canvas
                  final sharedBounds =
                      getSharedBounds(pathState.gpsPath, pathState.drPath);
                  return PathCanvas(
                    drPath: pathState.drPath,
                    gpsPath: pathState.gpsPath,
                    sharedBounds: sharedBounds,
                  );
                },
              ),
            ),
          ),

          // 2. Basic Metrics
          _buildMetricsBar(pathState),

          // 3. Basic Controls
          _buildControlBar(pathState.isRunning, controller),
        ],
      ),
    );
  }

  Widget _buildMetricsBar(PathState pathState) {
    // Calculate metrics
    final double drDist = getPathDistance(pathState.drPath);
    final double gpsDist = getPathDistance(pathState.gpsPath);
    double drift = 0;
    if (pathState.drPath.isNotEmpty && pathState.gpsPath.isNotEmpty) {
      drift = (pathState.drPath.last - pathState.gpsPath.last).distance;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF2C2C2E),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text('IMU Dist: ${drDist.toStringAsFixed(1)}m',
              style: const TextStyle(color: Colors.orange)),
          Text('GPS Dist: ${gpsDist.toStringAsFixed(1)}m',
              style: const TextStyle(color: Colors.green)),
          Text(
            'Drift: ${drift.toStringAsFixed(2)}m',
            style: const TextStyle(
                color: Colors.redAccent, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar(bool isRunning, PathController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: const Color(0xFF2C2C2E).withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
            iconSize: 32,
            color: Colors.white,
            onPressed: () {
              isRunning ? controller.stop() : controller.start();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            iconSize: 32,
            color: Colors.white,
            onPressed: controller.reset,
          ),
        ],
      ),
    );
  }
}
