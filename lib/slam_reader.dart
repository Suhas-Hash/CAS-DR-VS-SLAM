import 'dart:async';
import 'package:flutter/material.dart';

// SIMULATED: This class pretends to be ARCore/ARKit
class SlamReader {
  /// Outputs a stream of 2D points (Offsets)
  ///
  /// This simulation generates a perfect 10m x 10m square path.
  Stream<Offset> getPathStream() {
    return Stream.periodic(const Duration(milliseconds: 50), (i) {
      // 800 steps for a full 40m loop (10m / side)
      // 200 steps per side
      final double t = (i % 800) / 200.0; // 0.0 -> 4.0

      if (t < 1.0) {
        // Move right (0,0) -> (10,0)
        return Offset(t * 10, 0);
      } else if (t < 2.0) {
        // Move down (10,0) -> (10,10)
        return Offset(10, (t - 1.0) * 10);
      } else if (t < 3.0) {
        // Move left (10,10) -> (0,10)
        return Offset(10 - (t - 2.0) * 10, 10);
      } else {
        // Move up (0,10) -> (0,0)
        return Offset(0, 10 - (t - 3.0) * 10);
      }
    });
  }
}
