import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Customer information section widget
/// Displays customer details with contact actions
class CustomerInfoSection extends StatelessWidget {
  final Map<String, dynamic> customerData;
  final VoidCallback onExpand;
  final bool isExpanded;

  const CustomerInfoSection({
    super.key,
    required this.customerData,
    required this.onExpand,
    required this.isExpanded,
  });

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Column(
        children: [
          // Header with customer name and contact actions
          InkWell(
            onTap: onExpand,
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  // Customer avatar
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (customerData["name"] as String)
                            .substring(0, 1)
                            .toUpperCase(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  // Customer name and tier
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerData["name"] as String,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: _getTierColor(
                                theme, customerData["tier"] as String),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            customerData["tier"] as String,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Contact actions
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'phone',
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    onPressed: () =>
                        _makePhoneCall(customerData["phone"] as String),
                    tooltip: 'Appeler',
                  ),
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'message',
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    onPressed: () => _sendSMS(customerData["phone"] as String),
                    tooltip: 'Message',
                  ),
                  CustomIconWidget(
                    iconName: isExpanded ? 'expand_less' : 'expand_more',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          // Expanded details
          if (isExpanded)
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    context,
                    'Téléphone',
                    customerData["phone"] as String,
                  ),
                  SizedBox(height: 1.h),
                  _buildInfoRow(
                    context,
                    'Email',
                    customerData["email"] as String,
                  ),
                  SizedBox(height: 1.h),
                  _buildInfoRow(
                    context,
                    'Adresse',
                    customerData["address"] as String,
                  ),
                  SizedBox(height: 1.h),
                  _buildInfoRow(
                    context,
                    'Conditions de paiement',
                    customerData["paymentTerms"] as String,
                  ),
                  SizedBox(height: 1.h),
                  _buildInfoRow(
                    context,
                    'Crédit disponible',
                    '${customerData["creditLimit"]} CDF',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 35.w,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Color _getTierColor(ThemeData theme, String tier) {
    switch (tier.toLowerCase()) {
      case 'premium':
        return theme.colorScheme.tertiary;
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFC0C0C0);
      default:
        return theme.colorScheme.primary;
    }
  }
}
