import 'package:collection/collection.dart';

import 'data_position_result.dart';
import 'date_position_result.dart';

class StackedPosition {
  StackedPosition({
    this.date,
    this.legend,
    this.allocation,
    this.start,
    //this.end,
  });

  final DateTime? date;

  final String? legend;

  final double? allocation;

  final double? start;

  //final double? end;

  static List<DatePosition<StackedPosition>>? fromDatePositionList(
      List<DatePositionResult>? positions, List<String>? Function(List<DatePositionResult>? data) getLegends) {
    if (positions == null || positions.isEmpty) {
      return null;
    }

    final result = <DatePosition<StackedPosition>>[];

    final legends = getLegends(positions);

    final dates = positions.map((d) => d.date!).toList();

    final summariesByDate = positions
        .map((d) => DatePositionResult(date: d.date, positions: [
              DataPositionResult(
                  price: d.positions.map<double>((p) => (p.shares ?? 0) * (p.price ?? 0)).reduce((a, b) => a + b))
            ]))
        .toList();

    for (int index = 0; index < dates.length; index++) {
      var start = 0.0;

      final datePosition = DatePosition<StackedPosition>(
        date: dates[index],
      );

      final dataPositions = positions[index].positions;
      final summary = summariesByDate[index];

      for (final legend in legends!) {
        final legendPosition = dataPositions.firstWhereOrNull((p) => p.ticker == legend);

        final allocation =
            (legendPosition?.shares ?? 0) * (legendPosition?.price ?? 0) / (summary.positions.firstOrNull?.price ?? 1);

        datePosition.positions.add(StackedPosition(
          date: dates[index],
          legend: legend,
          allocation: allocation,
          start: start,
        ));

        start += allocation;
      }

      result.add(datePosition);
    }

    return result;
  }
}
