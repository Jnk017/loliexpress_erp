import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RiskScoreCardWidget extends StatelessWidget {
  final Map<String, dynamic> userRisk;

  const RiskScoreCardWidget({
    super.key,
    required this.userRisk,
  });

  Color _getRiskColor(double score) {
    if (score >= 80) return Colors.red;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.amber;
    return Colors.green;
  }

  String _getRiskLevel(double score) {
    if (score >= 80) return 'Critical Risk';
    if (score >= 60) return 'High Risk';
    if (score >= 40) return 'Medium Risk';
    return 'Low Risk';
  }

  Widget _buildScoreBar(String label, double score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500)),
            Text('${score.toStringAsFixed(0)}/100',
                style: TextStyle(fontSize: 10.sp, color: Colors.grey[600])),
          ],
        ),
        SizedBox(height: 0.5.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: color.withAlpha(51),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final overallScore = (userRisk['overall_score'] ?? 0.0).toDouble();
    final transactionScore = (userRisk['transaction_score'] ?? 0.0).toDouble();
    final accessScore = (userRisk['access_score'] ?? 0.0).toDouble();
    final inventoryScore = (userRisk['inventory_score'] ?? 0.0).toDouble();

    final riskColor = _getRiskColor(overallScore);
    final riskLevel = _getRiskLevel(overallScore);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: riskColor.withAlpha(77), width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20.sp,
                  backgroundColor: riskColor.withAlpha(26),
                  child: Text(
                    userRisk['user']?['full_name']
                            ?.substring(0, 1)
                            .toUpperCase() ??
                        'U',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: riskColor,
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userRisk['user']?['full_name'] ?? 'Unknown User',
                        style: TextStyle(
                            fontSize: 14.sp, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        userRisk['user']?['email'] ?? '',
                        style:
                            TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: riskColor.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${overallScore.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: riskColor,
                        ),
                      ),
                      Text(
                        '/100',
                        style:
                            TextStyle(fontSize: 9.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: riskColor.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: riskColor, size: 16.sp),
                  SizedBox(width: 2.w),
                  Text(
                    riskLevel,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: riskColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Risk Breakdown',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            _buildScoreBar('Transaction Risk', transactionScore, Colors.blue),
            SizedBox(height: 1.5.h),
            _buildScoreBar('Access Risk', accessScore, Colors.purple),
            SizedBox(height: 1.5.h),
            _buildScoreBar('Inventory Risk', inventoryScore, Colors.teal),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(Icons.access_time, size: 12.sp, color: Colors.grey),
                SizedBox(width: 1.w),
                Text(
                  'Last updated: ${userRisk['last_calculated_at'] != null ? DateTime.parse(userRisk['last_calculated_at']).toString().substring(0, 16) : 'Unknown'}',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
