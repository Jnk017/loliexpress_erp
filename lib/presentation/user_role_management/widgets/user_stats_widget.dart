import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';


class UserStatsWidget extends StatelessWidget {
  final Map<String, dynamic> statistics;

  const UserStatsWidget({
    Key? key,
    required this.statistics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalUsers = statistics['total_users'] ?? 0;
    final activeUsers = statistics['active_users'] ?? 0;
    final adminCount = statistics['admin_count'] ?? 0;
    final salesRepCount = statistics['sales_rep_count'] ?? 0;
    final warehouseCount = statistics['warehouse_staff_count'] ?? 0;
    final customerCount = statistics['b2b_customer_count'] ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Statistics',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Users',
                  totalUsers.toString(),
                  Icons.people,
                  const Color(0xFF1976D2),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  'Active Users',
                  activeUsers.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Users by Role',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 2.h),
          _buildRoleStatCard(
            'Administrators',
            adminCount,
            totalUsers,
            Icons.admin_panel_settings,
            Colors.red,
          ),
          SizedBox(height: 2.h),
          _buildRoleStatCard(
            'Sales Representatives',
            salesRepCount,
            totalUsers,
            Icons.business_center,
            Colors.blue,
          ),
          SizedBox(height: 2.h),
          _buildRoleStatCard(
            'Warehouse Staff',
            warehouseCount,
            totalUsers,
            Icons.warehouse,
            Colors.orange,
          ),
          SizedBox(height: 2.h),
          _buildRoleStatCard(
            'B2B Customers',
            customerCount,
            totalUsers,
            Icons.shopping_bag,
            Colors.green,
          ),
          SizedBox(height: 3.h),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: const Color(0xFF1976D2), size: 24.0),
                      SizedBox(width: 2.w),
                      Text(
                        'Quick Info',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  _buildInfoRow('Total System Users', totalUsers.toString()),
                  _buildInfoRow(
                    'Active Rate',
                    '${totalUsers > 0 ? ((activeUsers / totalUsers) * 100).toStringAsFixed(1) : '0'}%',
                  ),
                  _buildInfoRow(
                    'Most Common Role',
                    _getMostCommonRole(
                      adminCount,
                      salesRepCount,
                      warehouseCount,
                      customerCount,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32.0),
            SizedBox(height: 1.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleStatCard(
    String role,
    int count,
    int total,
    IconData icon,
    Color color,
  ) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(icon, color: color, size: 24.0),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        '$count user${count != 1 ? 's' : ''} (${percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: color.withAlpha(51),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6.0,
              borderRadius: BorderRadius.circular(3.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _getMostCommonRole(
    int admin,
    int salesRep,
    int warehouse,
    int customer,
  ) {
    final roles = {
      'Admin': admin,
      'Sales Rep': salesRep,
      'Warehouse': warehouse,
      'Customer': customer,
    };

    var maxCount = 0;
    var mostCommon = 'N/A';

    roles.forEach((role, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommon = role;
      }
    });

    return mostCommon;
  }
}
