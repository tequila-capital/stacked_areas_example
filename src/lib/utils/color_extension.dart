import 'package:flutter/material.dart';

extension ColorExtention on Color {
  Color get foregroundColor =>
      ThemeData.estimateBrightnessForColor(this) == Brightness.light ? Colors.black : Colors.white;

  Color? combineWith(Color other) {
    final colors = [this, other].generateColorsList(3);

    return colors[1];
  }

  Color get inverseColor => Color.fromARGB(255, 255 - red, 255 - green, 255 - blue);
}

// extension MaterialColorExtention on MaterialColor {
//   List<Color?> generateColorsList(int count) {
//     final gradientColors = [shade500, shade100];

//     final stops = [0.0, 1.0];

//     final colors = List<Color?>.generate(count, (index) {
//       final point = (index / (count - 1));

//       return getColorFromGradient(gradientColors, stops, point);
//     });

//     return colors;
//   }
// }

extension ColorListExtension on List<Color> {
  List<Color?> generateColorsList(int count) {
    final stops = List<double>.generate(length, (index) => index / (length - 1)); //[0.0, 1.0];

    final colors = List<Color?>.generate(count, (index) {
      final point = (index / (count - 1));

      return getColorFromGradient(this, stops, point);
    });

    return colors;
  }
}

Color? getColorFromGradient(List<Color> colors, List<double> stops, double t) {
  for (var s = 0; s < stops.length - 1; s++) {
    final leftStop = stops[s], rightStop = stops[s + 1];
    final leftColor = colors[s], rightColor = colors[s + 1];
    if (t <= leftStop) {
      return leftColor;
    } else if (t < rightStop) {
      final sectionT = (t - leftStop) / (rightStop - leftStop);
      return Color.lerp(leftColor, rightColor, sectionT);
    }
  }
  return colors.last;
}
