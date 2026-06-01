import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

class ChartWidget extends StatelessWidget {
  final String title;
  final String chartType;
  final List<dynamic> data;

  const ChartWidget({
    super.key,
    required this.title,
    required this.chartType,
    this.data = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (data.isNotEmpty)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(26),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sync,
                          size: 12.sp,
                          color: Colors.green,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          'Live',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 2.h),
            SizedBox(
              height: 25.h,
              child: data.isEmpty
                  ? Center(
                      child: Text(
                        'No data available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : chartType == 'line'
                      ? _buildLineChart()
                      : _buildBarChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _generateLineSpots(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withAlpha(26),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: _generateBarGroups(),
      ),
    );
  }

  List<FlSpot> _generateLineSpots() {
    if (data.isEmpty) {
      return List.generate(7, (i) => FlSpot(i.toDouble(), (i * 10).toDouble()));
    }

    return data
        .asMap()
        .entries
        .map((entry) {
          final amount = entry.value['amount'] is num
              ? (entry.value['amount'] as num).toDouble()
              : 0.0;
          return FlSpot(entry.key.toDouble(), amount);
        })
        .take(20)
        .toList();
  }

  List<BarChartGroupData> _generateBarGroups() {
    if (data.isEmpty) {
      return List.generate(
        5,
        (i) => BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: (i + 1) * 20.0,
              color: Colors.green,
              width: 12,
              borderRadius: BorderRadius.circular(4.0),
            ),
          ],
        ),
      );
    }

    return data
        .asMap()
        .entries
        .map((entry) {
          final quantity = entry.value['quantity'] is num
              ? (entry.value['quantity'] as num).toDouble()
              : 0.0;
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: quantity,
                color: Colors.green,
                width: 12,
                borderRadius: BorderRadius.circular(4.0),
              ),
            ],
          );
        })
        .take(10)
        .toList();
  }
}
