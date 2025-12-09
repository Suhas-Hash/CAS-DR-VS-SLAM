import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // We only use the LatLng class

class CoordConverter {
  /// Converts a new LatLng point to an (x, y) meter Offset
  /// relative to a starting LatLng point.
  static Offset latLngToMeters(LatLng start, LatLng current) {
    // Calculate the distance (in meters)
    final double distance = Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      current.latitude,
      current.longitude,
    );

    // Calculate the bearing (in degrees)
    final double bearing = Geolocator.bearingBetween(
      start.latitude,
      start.longitude,
      current.latitude,
      current.longitude,
    );

    // Convert bearing from degrees to radians
    final double bearingRad = bearing * (pi / 180.0);

    // Calculate x (East/West) and y (North/South)
    // Note: We use -cos because bearing 0 is North, but in our
    // canvas +y is down. We flip y to make North "up".
    final double x = distance * sin(bearingRad);
    final double y = -distance * cos(bearingRad);

    return Offset(x, y);
  }
}
