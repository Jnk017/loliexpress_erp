import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

class DateRangeSelectorWidget extends StatelessWidget {
  final DateTimeRange? selectedDateRange;
  final Function(DateTimeRange?) onDateRangeChanged;

  const DateRangeSelectorWidget({
    super.key,
    required this.selectedDateRange,
    required this.onDateRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withAlpha(13),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.date_range,
            color: Theme.of(context).primaryColor,
            size: 5.w,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: InkWell(
              onTap: () => _selectDateRange(context),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 3.w,
                  vertical: 1.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedDateRange != null
                            ? '${DateFormat('MMM dd, yyyy').format(selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(selectedDateRange!.end)}'
                            : 'All time',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: selectedDateRange != null
                              ? Colors.black87
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (selectedDateRange != null) ...[
            SizedBox(width: 2.w),
            IconButton(
              icon: Icon(
                Icons.clear,
                color: Colors.grey[600],
                size: 5.w,
              ),
              onPressed: () => onDateRangeChanged(null),
              tooltip: 'Clear date filter',
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateRangeChanged(picked);
    }
  }
}
