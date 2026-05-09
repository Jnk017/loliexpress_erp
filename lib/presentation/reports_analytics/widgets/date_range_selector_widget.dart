import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class DateRangeSelectorWidget extends StatelessWidget {
  final String selectedRange;
  final Function(String) onRangeChanged;

  const DateRangeSelectorWidget({
    Key? key,
    required this.selectedRange,
    required this.onRangeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ranges = [
      'Aujourd\'hui',
      'Cette semaine',
      'Ce mois',
      'Ce trimestre',
      'Cette année',
      'Personnalisé',
    ];

    return Container(
      height: 5.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ranges.length,
        itemBuilder: (context, index) {
          final range = ranges[index];
          final isSelected = range == selectedRange;

          return Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: ChoiceChip(
              label: Text(range),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  if (range == 'Personnalisé') {
                    _showCustomDatePicker(context);
                  } else {
                    onRangeChanged(range);
                  }
                }
              },
              selectedColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 12.sp,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCustomDatePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(Duration(days: 30)),
        end: DateTime.now(),
      ),
    );

    if (picked != null) {
      onRangeChanged(
        'Custom: ${picked.start.day}/${picked.start.month} - ${picked.end.day}/${picked.end.month}',
      );
    }
  }
}
