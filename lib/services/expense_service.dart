import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseService {
  static ExpenseService? _instance;
  static ExpenseService get instance => _instance ??= ExpenseService._();
  ExpenseService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getExpenses(
      {String? status, String? userId, int limit = 50}) async {
    try {
      var query = _client.from('expenses').select('*');
      if (status != null) query = query.eq('status', status);
      if (userId != null) query = query.eq('requested_by', userId);
      final response =
          await query.order('created_at', ascending: false).limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur chargement dépenses: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingApprovals() async {
    try {
      final response = await _client
          .from('expenses')
          .select('*')
          .eq('status', 'pending_approval')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur chargement approbations: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingPayments() async {
    try {
      final response = await _client
          .from('expenses')
          .select('*')
          .eq('status', 'pending_payment')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur chargement paiements: $e');
    }
  }

  Future<Map<String, dynamic>> createExpenseRequest({
    required String category,
    required String description,
    required double amount,
    required String currency,
    String? beneficiary,
    String urgency = 'normal',
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      final response = await _client
          .from('expenses')
          .insert({
            'category': category,
            'description': description,
            'amount': amount,
            'currency': currency,
            'status': 'pending_approval',
            'requested_by': userId,
            'created_by': userId,
            'expense_date': DateTime.now().toIso8601String().substring(0, 10),
            if (beneficiary != null) 'beneficiary': beneficiary,
            'urgency': urgency,
          })
          .select()
          .single();

      await _addHistory(response['id'], 'submitted', null);
      return response;
    } catch (e) {
      throw Exception('Erreur création demande: $e');
    }
  }

  Future<void> approveExpense(String expenseId, {String? comment}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      await _client.from('expenses').update({
        'status': 'pending_payment',
        'approved_by': userId,
        'approved_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', expenseId);

      await _addHistory(expenseId, 'approved', comment);
    } catch (e) {
      throw Exception('Erreur approbation: $e');
    }
  }

  Future<void> rejectExpense(String expenseId, {required String reason}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      await _client.from('expenses').update({
        'status': 'rejected',
        'approved_by': userId,
        'approved_at': DateTime.now().toIso8601String(),
        'rejection_reason': reason,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', expenseId);

      await _addHistory(expenseId, 'rejected', reason);
    } catch (e) {
      throw Exception('Erreur rejet: $e');
    }
  }

  Future<void> markAsPaid(
    String expenseId, {
    required String accountKind,
    required String accountId,
  }) async {
    await _client.rpc('pay_expense_from_account', params: {
      'p_expense_id': expenseId,
      'p_kind': accountKind,
      'p_account_id': accountId,
    });
  }

  Future<void> markAsExecuted(String expenseId, {String? receiptUrl}) async {
    try {
      await _client.from('expenses').update({
        'status': 'executed',
        'executed_at': DateTime.now().toIso8601String(),
        if (receiptUrl != null) 'receipt_url': receiptUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', expenseId);

      await _addHistory(expenseId, 'executed', null);
    } catch (e) {
      throw Exception('Erreur exécution: $e');
    }
  }

  Future<void> _addHistory(
      String expenseId, String action, String? comment) async {
    try {
      await _client.from('expense_approval_history').insert({
        'expense_id': expenseId,
        'action': action,
        'performed_by': _client.auth.currentUser?.id,
        if (comment != null) 'comment': comment,
      });
    } catch (e) {
      // Non-critical
    }
  }

  Future<List<Map<String, dynamic>>> getExpenseHistory(String expenseId) async {
    try {
      final response = await _client
          .from('expense_approval_history')
          .select('*')
          .eq('expense_id', expenseId)
          .order('created_at');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur historique: $e');
    }
  }

  Future<Map<String, dynamic>> getExpenseStats() async {
    try {
      final expenses =
          await _client.from('expenses').select('amount, currency, status');
      double totalCDF = 0, totalUSD = 0;
      int pending = 0, approved = 0, paid = 0, rejected = 0;
      for (final e in expenses) {
        final amount = (e['amount'] as num?)?.toDouble() ?? 0;
        if (e['currency'] == 'USD') {
          totalUSD += amount;
        } else {
          totalCDF += amount;
        }
        switch (e['status']) {
          case 'pending_approval':
            pending++;
            break;
          case 'pending_payment':
          case 'approved':
            approved++;
            break;
          case 'paid':
          case 'executed':
            paid++;
            break;
          case 'rejected':
            rejected++;
            break;
        }
      }
      return {
        'total_cdf': totalCDF,
        'total_usd': totalUSD,
        'pending': pending,
        'approved': approved,
        'paid': paid,
        'rejected': rejected,
        'total_count': expenses.length,
      };
    } catch (e) {
      throw Exception('Erreur stats dépenses: $e');
    }
  }
}
