import 'dart:async';
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
    print('Payment change detected: ${payload.eventType}');
    await refreshFinancialMetrics();
    await refreshReceivables();
  }

  /// Handle invoice changes and refresh metrics
  void _handleInvoiceChange(PostgresChangePayload payload) async {
    print('Invoice change detected: ${payload.eventType}');
    await refreshFinancialMetrics();
    await refreshReceivables();
  }

  /// Handle expense changes and refresh metrics
  void _handleExpenseChange(PostgresChangePayload payload) async {
    print('Expense change detected: ${payload.eventType}');
    await refreshFinancialMetrics();
  }

  /// Handle audit log changes for financial transactions
  void _handleAuditLogChange(PostgresChangePayload payload) async {
    final tableName = payload.newRecord['table_name'] as String?;

    // Check if the audit log is for a financial table
    if (tableName != null &&
        ['payments', 'invoices', 'expenses', 'sales_orders']
            .contains(tableName)) {
      print('Financial audit log detected for table: $tableName');
      await refreshFinancialMetrics();
      await refreshReceivables();
    }
  }

  /// Fetch and calculate current cash position
  Future<Map<String, dynamic>> getCashPosition() async {
    try {
      // Calculate total payments received
      final paymentsResponse = await _supabase
          .from('payments')
          .select('amount')
          .gte(
              'payment_date',
              DateTime.now()
                  .subtract(const Duration(days: 30))
                  .toIso8601String());

      double totalPayments = 0;
      for (var payment in paymentsResponse) {
        totalPayments += (payment['amount'] as num?)?.toDouble() ?? 0;
      }
    
      // Calculate total expenses
      final expensesResponse = await _supabase
          .from('expenses')
          .select('amount')
          .gte(
              'expense_date',
              DateTime.now()
                  .subtract(const Duration(days: 30))
                  .toIso8601String());

      double totalExpenses = 0;
      for (var expense in expensesResponse) {
        totalExpenses += (expense['amount'] as num?)?.toDouble() ?? 0;
      }
    
      final cashPosition = totalPayments - totalExpenses;

      return {
        'amount': cashPosition,
        'currency': 'XOF',
        'change': 0.0, // Calculate actual change from previous period
        'trend': cashPosition > 0 ? 'up' : 'down',
      };
    } catch (e) {
      print('Error fetching cash position: $e');
      return {
        'amount': 0,
        'currency': 'XOF',
        'change': 0.0,
        'trend': 'neutral'
      };
    }
  }

  /// Fetch daily revenue
  Future<Map<String, dynamic>> getDailyRevenue() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final ordersResponse = await _supabase
          .from('sales_orders')
          .select('total_amount')
          .gte('order_date', startOfDay.toIso8601String())
          .eq('order_status', 'delivered');

      double totalRevenue = 0;
      for (var order in ordersResponse) {
        totalRevenue += (order['total_amount'] as num?)?.toDouble() ?? 0;
      }
    
      return {
        'amount': totalRevenue,
        'currency': 'XOF',
        'change': 0.0, // Calculate actual change
        'trend': 'up',
      };
    } catch (e) {
      print('Error fetching daily revenue: $e');
      return {
        'amount': 0,
        'currency': 'XOF',
        'change': 0.0,
        'trend': 'neutral'
      };
    }
  }

  /// Fetch outstanding receivables
  Future<Map<String, dynamic>> getOutstandingReceivables() async {
    try {
      final invoicesResponse = await _supabase
          .from('invoices')
          .select('total_amount, amount_paid')
          .inFilter('payment_status', ['pending', 'partial']);

      double totalOutstanding = 0;
      for (var invoice in invoicesResponse) {
        final total = (invoice['total_amount'] as num?)?.toDouble() ?? 0;
        final paid = (invoice['amount_paid'] as num?)?.toDouble() ?? 0;
        totalOutstanding += (total - paid);
      }
    
      return {
        'amount': totalOutstanding,
        'currency': 'XOF',
        'change': 0.0, // Calculate actual change
        'trend': 'up',
      };
    } catch (e) {
      print('Error fetching receivables: $e');
      return {
        'amount': 0,
        'currency': 'XOF',
        'change': 0.0,
        'trend': 'neutral'
      };
    }
  }

  /// Fetch monthly expenses
  Future<Map<String, dynamic>> getMonthlyExpenses() async {
    try {
      final startOfMonth =
          DateTime(DateTime.now().year, DateTime.now().month, 1);

      final expensesResponse = await _supabase
          .from('expenses')
          .select('amount')
          .gte('expense_date', startOfMonth.toIso8601String());

      double totalExpenses = 0;
      for (var expense in expensesResponse) {
        totalExpenses += (expense['amount'] as num?)?.toDouble() ?? 0;
      }
    
      return {
        'amount': totalExpenses,
        'currency': 'XOF',
        'change': 0.0, // Calculate actual change
        'trend': 'up',
      };
    } catch (e) {
      print('Error fetching expenses: $e');
      return {
        'amount': 0,
        'currency': 'XOF',
        'change': 0.0,
        'trend': 'neutral'
      };
    }
  }

  /// Fetch accounts receivable list
  Future<List<Map<String, dynamic>>> getAccountsReceivable() async {
    try {
      final response = await _supabase.from('invoices').select('''
            id,
            invoice_number,
            total_amount,
            amount_paid,
            due_date,
            payment_status,
            customer_id,
            customers (
              company_name,
              contact_person
            )
          ''').inFilter('payment_status', [
        'pending',
        'partial'
      ]).order('due_date', ascending: true);

      return response.map((invoice) {
        final customer = invoice['customers'] as Map<String, dynamic>?;
        final totalAmount =
            (invoice['total_amount'] as num?)?.toDouble() ?? 0;
        final amountPaid = (invoice['amount_paid'] as num?)?.toDouble() ?? 0;
        final dueDate = DateTime.parse(invoice['due_date'] as String);
        final now = DateTime.now();
        final daysOverdue = now.difference(dueDate).inDays;

        String status = 'current';
        if (daysOverdue > 60) {
          status = '60-day';
        } else if (daysOverdue > 30) {
          status = '30-day';
        }

        return {
          'id': invoice['id'],
          'customerName': customer?['company_name'] ?? 'Unknown',
          'customerAvatar':
              'https://ui-avatars.com/api/?name=${customer?['company_name']?.replaceAll(' ', '+') ?? 'U'}',
          'semanticLabel':
              'Avatar for ${customer?['company_name'] ?? 'Unknown'}',
          'amount': totalAmount - amountPaid,
          'currency': 'XOF',
          'dueDate': invoice['due_date'],
          'status': status,
          'invoiceNumber': invoice['invoice_number'],
          'daysOverdue': daysOverdue > 0 ? daysOverdue : 0,
        };
      }).toList();
    
      return [];
    } catch (e) {
      print('Error fetching accounts receivable: $e');
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
      print('Error refreshing financial metrics: $e');
    }
  }

  /// Refresh receivables and emit to stream
  Future<void> refreshReceivables() async {
    try {
      final receivables = await getAccountsReceivable();
      _receivablesController.add(receivables);
    } catch (e) {
      print('Error refreshing receivables: $e');
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