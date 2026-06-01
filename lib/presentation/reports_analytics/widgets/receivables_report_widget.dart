import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/purchase_service.dart';

class ReceivablesReportWidget extends StatefulWidget {
  const ReceivablesReportWidget({super.key});

  @override
  State<ReceivablesReportWidget> createState() =>
      _ReceivablesReportWidgetState();
}

class _ReceivablesReportWidgetState extends State<ReceivablesReportWidget> {
  bool _isLoading = true;
  Map<String, dynamic>? _summary;
  String? _errorMessage;
  _SortMode _sortMode = _SortMode.amount;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final summary = await PurchaseService.instance.getReceivablesSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getAgingColor(String? bracket) {
    switch (bracket) {
      case '0-30 jours':
        return Colors.green;
      case '31-60 jours':
        return Colors.orange;
      case '61-90 jours':
        return Colors.red;
      case '90+ jours':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }

  int _getDaysFromBracket(String? bracket) {
    switch (bracket) {
      case '0-30 jours':
        return 15;
      case '31-60 jours':
        return 45;
      case '61-90 jours':
        return 75;
      case '90+ jours':
        return 100;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
            SizedBox(height: 1.h),
            Text('Erreur: $_errorMessage', textAlign: TextAlign.center),
            SizedBox(height: 1.h),
            ElevatedButton(
                onPressed: _loadData, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    if (_summary == null) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(),
            SizedBox(height: 2.h),
            _buildAgingBreakdown(),
            SizedBox(height: 2.h),
            _buildDetailList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalCDF = (_summary!['total_cdf'] as num?)?.toDouble() ?? 0;
    final totalUSD = (_summary!['total_usd'] as num?)?.toDouble() ?? 0;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total créances CDF',
            value: 'FC ${totalCDF.toStringAsFixed(0)}',
            icon: Icons.account_balance_wallet,
            color: Colors.blue,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _SummaryCard(
            title: 'Total créances USD',
            value: '\$${totalUSD.toStringAsFixed(2)}',
            icon: Icons.attach_money,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildAgingBreakdown() {
    final bracket030 = (_summary!['bracket_0_30'] as num?)?.toInt() ?? 0;
    final bracket3160 = (_summary!['bracket_31_60'] as num?)?.toInt() ?? 0;
    final bracket6190 = (_summary!['bracket_61_90'] as num?)?.toInt() ?? 0;
    final bracket90Plus = (_summary!['bracket_90_plus'] as num?)?.toInt() ?? 0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Répartition par ancienneté',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _AgingRow(
              label: '0-30 jours',
              count: bracket030,
              color: Colors.green,
            ),
            _AgingRow(
              label: '31-60 jours',
              count: bracket3160,
              color: Colors.orange,
            ),
            _AgingRow(
              label: '61-90 jours',
              count: bracket6190,
              color: Colors.red,
            ),
            _AgingRow(
              label: '90+ jours',
              count: bracket90Plus,
              color: Colors.red.shade900,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailList() {
    final details = _summary!['details'] as List<dynamic>? ?? [];
    if (details.isEmpty) {
      return const Center(child: Text('Aucune créance en cours'));
    }

    final sortedDetails = List<Map<String, dynamic>>.from(
      details.map((d) => Map<String, dynamic>.from(d)),
    );

    if (_sortMode == _SortMode.amount) {
      sortedDetails.sort((a, b) {
        final amountA = (a['total_amount'] as num?)?.toDouble() ?? 0;
        final amountB = (b['total_amount'] as num?)?.toDouble() ?? 0;
        return amountB.compareTo(amountA);
      });
    } else {
      sortedDetails.sort((a, b) {
        final daysA = _getDaysFromBracket(a['aging_bracket'] as String?);
        final daysB = _getDaysFromBracket(b['aging_bracket'] as String?);
        return daysB.compareTo(daysA);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Détails par client',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
            PopupMenuButton<_SortMode>(
              icon: const Icon(Icons.sort, size: 20),
              onSelected: (mode) => setState(() => _sortMode = mode),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _SortMode.amount,
                  child: Row(
                    children: [
                      Icon(
                        Icons.check,
                        size: 16,
                        color: _sortMode == _SortMode.amount
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                      ),
                      SizedBox(width: 2.w),
                      const Text('Par montant'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _SortMode.days,
                  child: Row(
                    children: [
                      Icon(
                        Icons.check,
                        size: 16,
                        color: _sortMode == _SortMode.days
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                      ),
                      SizedBox(width: 2.w),
                      const Text('Par ancienneté'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 1.h),
        ...sortedDetails.map((item) => _buildDetailCard(item)),
      ],
    );
  }

  Widget _buildDetailCard(Map<String, dynamic> item) {
    final customerName = item['company_name'] ?? 'Inconnu';
    final amount = (item['total_amount'] as num?)?.toDouble() ?? 0;
    final currency = item['currency'] ?? 'CDF';
    final bracket = item['aging_bracket'] as String?;
    final color = _getAgingColor(bracket);

    final formattedAmount = currency == 'USD'
        ? '\$${amount.toStringAsFixed(2)}'
        : 'FC ${amount.toStringAsFixed(0)}';

    return Card(
      margin: EdgeInsets.only(bottom: 1.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(Icons.person, color: color, size: 20),
        ),
        title: Text(
          customerName,
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          bracket ?? 'N/A',
          style: TextStyle(fontSize: 10.sp, color: color),
        ),
        trailing: Text(
          formattedAmount,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgingRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _AgingRow({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.8.h),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 11.sp),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _SortMode { amount, days }
