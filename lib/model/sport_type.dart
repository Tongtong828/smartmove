import 'package:flutter/material.dart';

enum SportType {
  walking,
  running,
  cycling,
}

extension SportTypeX on SportType {
  String get label {
    switch (this) {
      case SportType.walking:
        return 'Walking';
      case SportType.running:
        return 'Running';
      case SportType.cycling:
        return 'Cycling';
    }
  }

  IconData get icon {
    switch (this) {
      case SportType.walking:
        return Icons.directions_walk;
      case SportType.running:
        return Icons.directions_run;
      case SportType.cycling:
        return Icons.directions_bike;
    }
  }

  String get paceLabel {
    switch (this) {
      case SportType.cycling:
        return 'Speed';
      case SportType.walking:
      case SportType.running:
        return 'Pace';
    }
  }
}