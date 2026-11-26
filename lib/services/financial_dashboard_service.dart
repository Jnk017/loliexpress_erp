import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FinancialDashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream controllers for real-time updates
  final StreamController<Map<String, dynamic>> _financialMetricsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _receivablesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  // Realtime subscriptions
  RealtimeChannel? _paymentsChannel;
  RealtimeChannel? _invoicesChannel;
  RealtimeChannel? _expensesChannel;
  RealtimeChannel? _auditLogsChannel;

  Stream<Map<String, dynamic>> get financialMetricsStream =>
      _financialMetricsController.stream;
  Stream<List<Map<String, dynamic>>> get receivablesStream =>
      _receivablesController.stream;

  /// Initialize real-time subscriptions for financial data
  Future<void> initializeRealtimeSubscriptions() async {
    // Subscribe to payments table
    _paymentsChannel = _supabase
        .channel('payments_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'payments',
          callback: (payload) => _handlePaymentChange(payload),
        )
        .subscribe();

    // Subscribe to invoices table
    _invoicesChannel = _supabase
        .channel('invoices_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'invoices',
          callback: (payload) => _handleInvoiceChange(payload),
        )
        .subscribe();

    // Subscribe to expenses table
    _expensesChannel = _supabase
        .channel('expenses_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'expenses',
          callback: (payload) => _handleExpenseChange(payload),
        )
        .subscribe();

    // Subscribe to audit_logs for financial transactions
    _auditLogsChannel = _supabase
        .channel('audit_logs_financial')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'audit_logs',
          callback: (payload) => _handleAuditLogChange(payload),
        )
        .subscribe();
  }

  /// Handle payment changes and refresh metrics
  void _handlePaymentChange(PostgresChangePayload payload) async {
    debugPrint('Payment change detected: ${payload.eventType}');
    await refreshFinancialMetrics();
    await refreshReceivables();
  }

  /// Handle invoice changes and refresh metrics
  void _handleInvoiceChange(PostgresChangePayload payload) async {
    debugPrint('Invoice change detected: ${payload.eventType}');
    await refreshFinancialMetrics();
    await refreshReceivables();
  }

  /// Handle expense changes and refresh metrics
  void _handleExpenseChange(PostgresChangePayload payload) async {
    debugPrint('Expense change detected: ${payload.eventType}');
    await refreshFinancialMetrics();
  }

  /// Handle audit log changes for financial transactions
  void _handleAuditLogChange(PostgresChangePayload payload) async {
    final tableName = payload.newRecord['table_name'] as String?;

    // Check if the audit log is for a financial table
    if (tableName != null &&
        ['payments', 'invoices', 'expenses', 'sales_orders']
            .contains(tableName)) {
      debugPrint('Financial audit log detected for table: $tableName');
      await refreshFinancialMetrics();
      await refreshReceivables();
    }
  }

  Future<List<List<Map<String, dynamic>>>> getTreasuryAccounts() => Future.wait([
    _supabase.from('cash_registers').select('name,currency,current_balance')
        .eq('is_active', true).order('name'),
    _supabase.from('bank_accounts').select('account_name,currency,current_balance,account_channel')
        .eq('is_active', true).order('account_name'),
  ]);

  /// Read actual treasury balances without mixing currencies.
  Future<Map<String, dynamic>> getCashPosition() async {
    try {
      final response = await getTreasuryAccounts();
      Map<String, num> totals(List<Map<String, dynamic>> rows) {
        final sums = <String, num>{'CDF': 0, 'USD': 0};
        for (final row in rows) {
          final currency = row['currency'] as String;
          sums[currency] = (sums[currency] ?? 0) + (row['current_balance'] as num);
        }
        return sums;
      }
      return {
        'cash': totals(response[0]),
        'bank': totals(response[1].where((row) => row['account_channel'] == 'bank_transfer').toList()),
        'mobileMoney': totals(response[1].where((row) => row['account_channel'] == 'mobile_money').toList()),
      };
    } catch (_) {
      return {'unavailable': true};
    }
  }

  Map<String, dynamic> _currencyMetrics(
    List<Map<String, dynamic>> rows,
    String amountColumn,
  ) {
    final sums = <String, num>{'CDF': 0, 'USD': 0};
    for (final row in rows) {
      final currency = row['currency'];
      if (sums.containsKey(currency)) {
        sums[currency as String] = sums[currency]! + (row[amountColumn] as num? ?? 0);
      }
    }
    return {
      'amount': sums['CDF'],
      'amountUsd': sums['USD'],
      'currency': 'CDF',
      'change': 0,
      'trend': 'neutral',
    };
  }

  Future<Map<String, dynamic>> getDailyRevenue() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final rows = await _supabase.from('sales_orders')
        .select('total_amount,currency')
        .gte('order_date', startOfDay.toIso8601String())
        .eq('order_status', 'delivered');
    return _currencyMetrics(rows, 'total_amount');
  }

  Future<Map<String, dynamic>> getOutstandingReceivables() async {
    final rows = await _supabase.from('invoice_open_balances')
        .select('outstanding_amount,currency');
    return _currencyMetrics(rows, 'outstanding_amount');
  }

  Future<Map<String, dynamic>> getMonthlyExpenses() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final rows = await _supabase.from('expenses')
        .select('amount,currency')
        .gte('paid_at', startOfMonth.toIso8601String())
        .inFilter('status', ['paid', 'executed']);
    return _currencyMetrics(rows, 'amount');
  }

  /// Fetch accounts receivable list
  Future<List<Map<String, dynamic>>> getAccountsReceivable() async {
    try {
      final response = await _supabase.from('invoices').select('''
            id,
            invoice_number,
            total_amount,
            amount_paid,
            currency,
            item_amount_credited,
            delivery_fee_credited,
            due_date,
            payment_status,
            customer_id,
            customers (
              company_name,
              email
            )
          ''').inFilter('payment_status', [
        'pending',
        'partial'
      ]).order('due_date', ascending: true);

      return response.map((invoice) {
        final customer = invoice['customers'] as Map<String, dynamic>?;
        final totalAmount = (invoice['total_amount'] as num?)?.toDouble() ?? 0;
        final amountPaid = (invoice['amount_paid'] as num?)?.toDouble() ?? 0;
        final credit = (invoice['item_amount_credited'] as num? ?? 0) +
            (invoice['delivery_fee_credited'] as num? ?? 0);
        final dueDate = DateTime.tryParse(invoice['due_date'] as String? ?? '');
        final daysOverdue = dueDate == null ? 0 : DateTime.now().difference(dueDate).inDays;

        String status = 'current';
        if (daysOverdue > 60) {
          status = '60-day';
        } else if (daysOverdue > 30) {
          status = '30-day';
        }

        return {
          'id': invoice['id'],
          'customerEmail': customer?['email'],
          'customerName': customer?['company_name'] ?? 'Unknown',
          'customerAvatar':
              'https://ui-avatars.com/api/?name=${customer?['company_name']?.replaceAll(' ', '+') ?? 'U'}',
          'semanticLabel':
              'Avatar for ${customer?['company_name'] ?? 'Unknown'}',
          'amount': (totalAmount - amountPaid - credit).clamp(0, double.infinity),
          'currency': invoice['currency'],
          'dueDate': invoice['due_date'],
          'status': status,
          'invoiceNumber': invoice['invoice_number'],
          'daysOverdue': daysOverdue > 0 ? daysOverdue : 0,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching accounts receivable: $e');
      return [];
    }
  }

  /// Refresh all financial metrics and emit to stream
  Future<void> refreshFinancialMetrics() async {
    try {
      final metrics = {
        'cashPosition': await getCashPosition(),
        'dailyRevenue': await getDailyRevenue(),
        'outstandingReceivables': await getOutstandingReceivables(),
        'monthlyExpenses': await getMonthlyExpenses(),
      };

      _financialMetricsController.add(metrics);
    } catch (e) {
      debugPrint('Error refreshing financial metrics: $e');
    }
  }

  /// Refresh receivables and emit to stream
  Future<void> refreshReceivables() async {
    try {
      final receivables = await getAccountsReceivable();
      _receivablesController.add(receivables);
    } catch (e) {
      debugPrint('Error refreshing receivables: $e');
    }
  }

  /// Cleanup subscriptions
  void dispose() {
    _paymentsChannel?.unsubscribe();
    _invoicesChannel?.unsubscribe();
    _expensesChannel?.unsubscribe();
    _auditLogsChannel?.unsubscribe();
    _financialMetricsController.close();
    _receivablesController.close();
  }
}
