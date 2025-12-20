import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

class FailedLoginListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> failedLogins;

  const FailedLoginListWidget({
    super.key,
    required this.failedLogins,
  });

  @override
  Widget build(BuildContext context) {
    if (failedLogins.isEmpty) {
      return const Center(child: Text('No failed login attempts found'));
    }

    return ListView.separated(
      padding: EdgeInsets.all(2.w),
      itemCount: failedLogins.length,
      separatorBuilder: (context, index) => SizedBox(height: 1.h),
      itemBuilder: (context, index) {
        final login = failedLogins[index];
        final attemptTime = DateTime.parse(login['attempt_time']);

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.lock_outline, color: Colors.red, size: 20.sp),
            ),
            title: Text(
              login['email'] ?? 'Unknown email',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 0.5.h),
                Text(
                  'IP: ${login['ip_address'] ?? 'Unknown'}',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
                if (login['failure_reason'] != null)
                  Text(
                    'Reason: ${login['failure_reason']}',
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('MMM dd').format(attemptTime),
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                ),
                Text(
                  DateFormat('HH:mm').format(attemptTime),
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
