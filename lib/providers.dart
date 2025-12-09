import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // We only use the LatLng class
import 'package:location/location.dart';
import 'package:slam_demo/algorithms/dr_engine.dart';
import 'package:slam_demo/utils/coord_converter.dart';

// --- Location (GPS) Provider ---
final locationProvider = Provider((ref) => Location());

// Provides a live stream of GPS locations
final locationStreamProvider = StreamProvider<LocationData>((ref) async* {
  final location = ref.watch(locationProvider);

  // Request permissions and service
  var serviceEnabled = await location.serviceEnabled();
  if (!serviceEnabled) {
    serviceEnabled = await location.requestService();
    if (!serviceEnabled) {
      throw 'Location service not enabled';
    }
  }

  var permissionGranted = await location.hasPermission();
  if (permissionGranted == PermissionStatus.denied) {
    permissionGranted = await location.requestPermission();
    if (permissionGranted != PermissionStatus.granted) {
      throw 'Location permission not granted';
    }
  }

  // Configure high-accuracy tracking for the demo
  await location.changeSettings(
    accuracy: LocationAccuracy.high,
    interval: 1000, // 1 second
    distanceFilter: 1, // 1 meter
  );

  yield* location.onLocationChanged;
});

// --- Path State Management ---

@immutable
class PathState {
  final List<Offset> gpsPath; // Ground Truth (in meters)
  final List<Offset> drPath; // IMU Path (in meters)
  final bool isRunning;
  final LatLng? startPoint; // Our (0,0) reference

  const PathState({
    this.gpsPath = const [Offset.zero],
    this.drPath = const [Offset.zero],
    this.isRunning = false,
    this.startPoint,
  });

  PathState copyWith({
    List<Offset>? gpsPath,
    List<Offset>? drPath,
    bool? isRunning,
    LatLng? startPoint,
  }) {
    return PathState(
      gpsPath: gpsPath ?? this.gpsPath,
      drPath: drPath ?? this.drPath,
      isRunning: isRunning ?? this.isRunning,
      startPoint: startPoint ?? this.startPoint,
    );
  }
}

class PathController extends StateNotifier<PathState> {
  final Ref _ref;
  StreamSubscription? _gpsSub;

  PathController(this._ref) : super(const PathState()) {
    // Listen to the DR engine's (x, y) meter path
    _ref.listen(drEngineProvider, (previous, next) {
      if (!state.isRunning) return;
      // The DR path is already in meters, just update it
      state = state.copyWith(drPath: next.path);
    });
  }

  void start() {
    if (state.isRunning) return;

    // Subscribe to the GPS stream
    _gpsSub =
        _ref.read(locationStreamProvider.stream).listen((LocationData locData) {
      if (locData.latitude == null || locData.longitude == null) return;

      final newGpsLatLng = LatLng(locData.latitude!, locData.longitude!);

      if (state.startPoint == null) {
        // This is the FIRST point. Set it as our (0,0) origin.
        _ref.read(drEngineProvider.notifier).start(); // Start the IMU engine!
        state = state.copyWith(
          isRunning: true,
          startPoint: newGpsLatLng,
          gpsPath: [Offset.zero],
          drPath: [Offset.zero], // Start both paths at (0,0)
        );
      } else {
        // Convert new GPS point to (x, y) meters relative to the start
        final newGpsOffset =
            CoordConverter.latLngToMeters(state.startPoint!, newGpsLatLng);
        state = state.copyWith(
          gpsPath: [...state.gpsPath, newGpsOffset],
        );
      }
    });
  }

  void stop() {
    _gpsSub?.cancel();
    _ref.read(drEngineProvider.notifier).stop();
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    stop();
    _ref.read(drEngineProvider.notifier).reset();
    state = const PathState(); // Reset to initial empty state
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    super.dispose();
  }
}

// Public provider for our controller
final pathControllerProvider = StateNotifierProvider<PathController, PathState>(
  (ref) => PathController(ref),
);
