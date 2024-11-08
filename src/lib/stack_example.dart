import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:matrix2d/matrix2d.dart';
import 'package:flutter/services.dart';

import 'package:fl_chart_stack/model/date_position_result.dart';
import 'package:fl_chart_stack/model/stacked_position.dart';
import 'package:fl_chart_stack/utils/color_extension.dart';

class StackExample extends StatelessWidget {
  const StackExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stack Example")),
      body: FutureBuilder(
          future: rootBundle.loadStructuredData('assets/data/positions.json', (data) {
            final jsonData = jsonDecode(data);

            return Future.value(DatePositionResult.listFromJson(jsonData));
          }),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return StackedPositionsChart(positions: snapshot.data);
            }

            return const Center(child: CircularProgressIndicator());
          }),
    );
  }
}

class StackedPositionsChart extends StatefulWidget {
  const StackedPositionsChart({
    required this.positions,
    super.key,
  });

  final List<DatePositionResult>? positions;

  @override
  State<StackedPositionsChart> createState() => _StackedPositionsChartState();

  static List<String>? getTickersLegends(List<DatePositionResult>? data) {
    return data?.map((d) => d.positions.map((p) => p.ticker ?? '').toList()).toList().expand((t) => t).toSet().toList()
      ?..sort((a, b) => a == 'CASH' || a == '' ? 0 : (a).compareTo((b)));
  }
}

class _StackedPositionsChartState extends State<StackedPositionsChart> {
  final stackedBarsData = <LineChartBarData>[];
  final unstackedBarsData = <LineChartBarData>[];
  final betweenBarsData = <BetweenBarsData>[];

  bool stacked = true;

  @override
  void initState() {
    getChartData();

    super.initState();
  }

  void getChartData() {
    final effectivePositions = widget.positions?.take(20).toList();

    final tickerLegends = StackedPositionsChart.getTickersLegends(effectivePositions);

    final lenght = ((tickerLegends?.length ?? 0).toDouble() / Colors.primaries.length).ceil();

    final colors = Colors.primaries.generateColorsList(Colors.primaries.length * lenght);

    final length = Colors.primaries.length;

    final colorSlices = colors.slices(length).toList();

    final transposedColors = colorSlices.transpose.expand((c) => c).toList();

    final allocationsData = StackedPosition.fromDatePositionList(
      effectivePositions,
      (_) => tickerLegends,
    );

    for (int i = 0; i < (tickerLegends?.length ?? 0); i++) {
      final currentLegend = tickerLegends![i];
      final currentColor = transposedColors[i];

      final allocationsByLegend =
          allocationsData?.map((d) => d.positions.firstWhereOrNull((p) => p.legend == currentLegend)).toList();

      stackedBarsData.add(
        LineChartBarData(
          spots: allocationsByLegend!
              .map((i) => FlSpot(i!.date!.millisecondsSinceEpoch.toDouble(), i.allocation! + i.start!))
              .toList(),
          color: currentColor,
          dotData: const FlDotData(show: false),
          barWidth: 0.25,
          belowBarData: i == 0 ? BarAreaData(show: true, color: currentColor.withAlpha(128), applyCutOffY: true) : null,
        ),
      );

      unstackedBarsData.add(
        LineChartBarData(
          spots: allocationsByLegend
              .map((i) => FlSpot(i!.date!.millisecondsSinceEpoch.toDouble(), i.allocation!))
              .toList(),
          color: currentColor,
          dotData: const FlDotData(show: false),
          barWidth: 1.0,
          //belowBarData: i == 0 ? BarAreaData(show: true, color: currentColor.withAlpha(128), applyCutOffY: true) : null,
        ),
      );

      if (i < (tickerLegends.length - 1)) {
        betweenBarsData
            .add(BetweenBarsData(fromIndex: i, toIndex: i + 1, color: transposedColors[i + 1]?.withAlpha(128)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chartTitlesStyle = Theme.of(context).textTheme.labelSmall;

    return Column(
      children: [
        SwitchListTile(
          title: const Text('Stacked'),
          value: stacked,
          onChanged: (value) => setState(() {
            stacked = value;
          }),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(8.0),
            child: LineChart(
              LineChartData(
                  lineBarsData: stacked ? stackedBarsData : unstackedBarsData,
                  betweenBarsData: stacked ? betweenBarsData : [],
                  minY: 0.0,
                  maxY: stacked ? 1.0 : null,
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 80,
                        interval: 0.1,
                        getTitlesWidget: (value, meta) => Container(
                          margin: const EdgeInsets.only(left: 8),
                          child: Text('${(value * 100.0).toStringAsFixed(2)} %', style: chartTitlesStyle),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: const Duration(days: 1).inMilliseconds.toDouble() * 4,
                        minIncluded: false,
                        maxIncluded: false,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);

                          final title =
                              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

                          return Text(
                            title,
                            style: chartTitlesStyle,
                            textAlign: TextAlign.right,
                          );
                        },
                      ),
                    ),
                  )),
            ),
          ),
        ),
      ],
    );
  }
}
