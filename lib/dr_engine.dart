import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simple class to hold our DR state
class DrState {
  // NOTE: The path is in METERS (x, y) relative to the start point
  final List<Offset> path;
  final double heading; // in radians

  DrState({this.path = const [Offset.zero], this.heading = 0.0});

  DrState copyWith({List<Offset>? path, double? heading}) {
    return DrState(
      path: path ?? this.path,
      heading: heading ?? this.heading,
    );
  }
}

class DrEngine extends StateNotifier<DrState> {
  StreamSubscription? _gyroSub;
  StreamSubscription? _accelSub;

  // --- Tuning Parameters ---
  final double _stepLength = 0.7; // Assume a fixed step length (in meters)
  final double _stepThreshold =
      11.5; // Acceleration magnitude threshold for a step
  final double _gyroDriftCorrection =
      0.0005; // Small factor to correct gyro drift
  // -------------------------

  bool _isStepDetecting = false;
  double _lastGyroTime = 0;

  DrEngine() : super(DrState());

  void start() {
    stop(); // Ensure no duplicates
    _lastGyroTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

    // 1. Listen to Gyroscope for Heading
    _gyroSub = gyroscopeEvents.listen((GyroscopeEvent event) {
      final double now = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final double dt = now - _lastGyroTime;
      _lastGyroTime = now;

      // Integrate Z-axis (yaw) rotation.
      double newHeading = state.heading - (event.z - _gyroDriftCorrection) * dt;
      newHeading = newHeading % (2 * pi);

      state = state.copyWith(heading: newHeading);
    });

    // 2. Listen to Accelerometer for Step Detection
    _accelSub = accelerometerEvents.listen((AccelerometerEvent event) {
      double magnitude =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      // Simple peak detection for a "step"
      if (magnitude > _stepThreshold && !_isStepDetecting) {
        _isStepDetecting = true;
        _onStepDetected();
      } else if (magnitude < 9.0) {
        // Reset threshold
        _isStepDetecting = false;
      }
    });
  }

  void _onStepDetected() {
    final Offset lastPosition = state.path.last;

    // Calculate new position (in meters) based on heading
    // x = east/west, y = north/south
    final Offset newPosition = Offset(
      lastPosition.dx + _stepLength * sin(state.heading),
      lastPosition.dy + _stepLength * cos(state.heading),
    );

    state = state.copyWith(path: [...state.path, newPosition]);
  }

  void stop() {
    _gyroSub?.cancel();
    _accelSub?.cancel();
  }

  void reset() {
    state = DrState();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

// Provider for our DR engine
final drEngineProvider = StateNotifierProvider<DrEngine, DrState>(
  (ref) => DrEngine(),
);
