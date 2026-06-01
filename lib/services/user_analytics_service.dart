import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class UserAnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Track user session
  Future<String?> startUserSession({
    required String userId,
    String? ipAddress,
    String? userAgent,
    String deviceType = 'Mobile',
  }) async {
    try {
      final response = await _supabase
          .from('user_sessions')
          .insert({
            'user_id': userId,
            'session_start': DateTime.now().toIso8601String(),
            'ip_address': ipAddress,
            'user_agent': userAgent,
            'device_type': deviceType,
            'status': 'active',
          })
          .select('id')
          .single();

      return response['id'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<void> endUserSession(String sessionId) async {
    try {
      await _supabase.from('user_sessions').update({
        'session_end': DateTime.now().toIso8601String(),
        'status': 'logged_out',
      }).eq('id', sessionId);
    } catch (e) {
      // Silent fail
    }
  }

  // Track screen views
  Future<void> trackScreenView({
    required String userId,
    String? sessionId,
    required String screenName,
    String screenCategory = 'other',
    int? timeSpentSeconds,
  }) async {
    try {
      await _supabase.from('screen_views').insert({
        'user_id': userId,
        'session_id': sessionId,
        'screen_name': screenName,
        'screen_category': screenCategory,
        'view_timestamp': DateTime.now().toIso8601String(),
        'time_spent_seconds': timeSpentSeconds,
      });
    } catch (e) {
      // Silent fail
    }
  }

  // Track feature usage
  Future<void> trackFeatureUsage({
    required String userId,
    required String featureName,
    required String moduleName,
    required String actionType,
    int? timeSeconds,
  }) async {
    try {
      await _supabase.rpc('update_feature_usage_stats', params: {
        'p_user_id': userId,
        'p_feature_name': featureName,
        'p_module_name': moduleName,
        'p_action_type': actionType,
        'p_time_seconds': timeSeconds,
      });
    } catch (e) {
      // Silent fail
    }
  }

  // Get login patterns
  Future<Map<String, dynamic>> getLoginPatterns({
    required String userId,
    int daysBack = 30,
  }) async {
    try {
      final startDate =
          DateTime.now().subtract(Duration(days: daysBack)).toIso8601String();
      final endDate = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('user_sessions')
          .select('session_start, session_end, duration_minutes, device_type')
          .eq('user_id', userId)
          .gte('session_start', startDate)
          .lte('session_start', endDate)
          .order('session_start', ascending: false);

      final sessions = response as List<dynamic>;

      // Calculate patterns
      int totalSessions = sessions.length;
      double avgDuration = 0;
      Map<int, int> hourlyDistribution = {};
      Map<String, int> deviceDistribution = {};

      for (var session in sessions) {
        final duration = session['duration_minutes'] ?? 0;
        avgDuration += duration;

        final sessionStart = DateTime.parse(session['session_start']);
        final hour = sessionStart.hour;
        hourlyDistribution[hour] = (hourlyDistribution[hour] ?? 0) + 1;

        final device = session['device_type'] ?? 'Unknown';
        deviceDistribution[device] = (deviceDistribution[device] ?? 0) + 1;
      }

      if (totalSessions > 0) {
        avgDuration = avgDuration / totalSessions;
      }

      return {
        'total_sessions': totalSessions,
        'avg_duration_minutes': avgDuration.toStringAsFixed(1),
        'peak_login_hours': (hourlyDistribution.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(3)
            .map((e) => '${e.key}:00')
            .toList(),
        'device_breakdown': deviceDistribution,
        'sessions': sessions,
      };
    } catch (e) {
      return {
        'total_sessions': 0,
        'avg_duration_minutes': '0',
        'peak_login_hours': [],
        'device_breakdown': {},
        'sessions': [],
      };
    }
  }

  // Get feature usage frequency
  Future<Map<String, dynamic>> getFeatureUsageStats({
    required String userId,
    String? moduleName,
    int limit = 10,
  }) async {
    try {
      var query = _supabase
          .from('feature_usage_stats')
          .select(
              'feature_name, module_name, action_type, usage_count, average_time_seconds, last_used_at')
          .eq('user_id', userId);

      if (moduleName != null) {
        query = query.eq('module_name', moduleName);
      }

      final response =
          await query.order('usage_count', ascending: false).limit(limit);

      final stats = response as List<dynamic>;

      // Calculate totals
      int totalUsage = 0;
      Map<String, int> moduleBreakdown = {};

      for (var stat in stats) {
        totalUsage += (stat['usage_count'] as int? ?? 0);
        final module = stat['module_name'] as String;
        moduleBreakdown[module] =
            (moduleBreakdown[module] ?? 0) + (stat['usage_count'] as int);
      }

      return {
        'total_feature_usage': totalUsage,
        'top_features': stats,
        'module_breakdown': moduleBreakdown,
      };
    } catch (e) {
      return {
        'total_feature_usage': 0,
        'top_features': [],
        'module_breakdown': {},
      };
    }
  }

  // Get screen navigation analytics
  Future<Map<String, dynamic>> getScreenNavigationStats({
    required String userId,
    int daysBack = 30,
  }) async {
    try {
      final startDate =
          DateTime.now().subtract(Duration(days: daysBack)).toIso8601String();
      final endDate = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('screen_views')
          .select(
              'screen_name, screen_category, time_spent_seconds, previous_screen, next_screen')
          .eq('user_id', userId)
          .gte('view_timestamp', startDate)
          .lte('view_timestamp', endDate);

      final views = response as List<dynamic>;

      // Calculate navigation patterns
      Map<String, int> screenFrequency = {};
      Map<String, int> categoryFrequency = {};
      Map<String, double> avgTimePerScreen = {};
      Map<String, Map<String, int>> navigationFlow = {};

      for (var view in views) {
        final screenName = view['screen_name'] as String;
        final category = view['screen_category'] as String;
        final timeSpent = view['time_spent_seconds'] as int? ?? 0;

        screenFrequency[screenName] = (screenFrequency[screenName] ?? 0) + 1;
        categoryFrequency[category] = (categoryFrequency[category] ?? 0) + 1;

        if (avgTimePerScreen.containsKey(screenName)) {
          avgTimePerScreen[screenName] =
              ((avgTimePerScreen[screenName]! + timeSpent) / 2);
        } else {
          avgTimePerScreen[screenName] = timeSpent.toDouble();
        }

        // Track navigation flow
        final prevScreen = view['previous_screen'] as String?;
        if (prevScreen != null) {
          navigationFlow[prevScreen] ??= {};
          navigationFlow[prevScreen]![screenName] =
              (navigationFlow[prevScreen]![screenName] ?? 0) + 1;
        }
      }

      // Sort by frequency
      final sortedScreens = screenFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final sortedCategories = categoryFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return {
        'total_screen_views': views.length,
        'unique_screens_visited': screenFrequency.length,
        'most_visited_screens': sortedScreens.take(5).map((e) {
          return {
            'screen': e.key,
            'visits': e.value,
            'avg_time': avgTimePerScreen[e.key]?.toStringAsFixed(0) ?? '0',
          };
        }).toList(),
        'category_breakdown': sortedCategories.map((e) {
          return {
            'category': e.key,
            'visits': e.value,
          };
        }).toList(),
        'navigation_flow': navigationFlow,
      };
    } catch (e) {
      return {
        'total_screen_views': 0,
        'unique_screens_visited': 0,
        'most_visited_screens': [],
        'category_breakdown': [],
        'navigation_flow': {},
      };
    }
  }

  // Get user productivity metrics
  Future<Map<String, dynamic>> getUserProductivityMetrics({
    required String userId,
    int daysBack = 30,
  }) async {
    try {
      final startDate =
          DateTime.now().subtract(Duration(days: daysBack)).toIso8601String();
      final endDate = DateTime.now().toIso8601String();

      final response =
          await _supabase.rpc('get_user_productivity_metrics', params: {
        'p_user_id': userId,
        'p_start_date': startDate,
        'p_end_date': endDate,
      });

      if (response == null || (response as List).isEmpty) {
        return {
          'total_sessions': 0,
          'total_session_time_minutes': 0,
          'avg_session_duration_minutes': 0,
          'total_screens_visited': 0,
          'unique_screens_count': 0,
          'most_used_feature': 'N/A',
          'most_visited_screen': 'N/A',
          'productivity_score': 0,
        };
      }

      final metrics = (response).first;
      return {
        'total_sessions': metrics['total_sessions'] ?? 0,
        'total_session_time_minutes':
            (metrics['total_session_time_minutes'] ?? 0).toStringAsFixed(0),
        'avg_session_duration_minutes':
            (metrics['avg_session_duration_minutes'] ?? 0).toStringAsFixed(1),
        'total_screens_visited': metrics['total_screens_visited'] ?? 0,
        'unique_screens_count': metrics['unique_screens_count'] ?? 0,
        'most_used_feature': metrics['most_used_feature'] ?? 'N/A',
        'most_visited_screen': metrics['most_visited_screen'] ?? 'N/A',
        'productivity_score':
            (metrics['productivity_score'] ?? 0).toStringAsFixed(1),
      };
    } catch (e) {
      return {
        'total_sessions': 0,
        'total_session_time_minutes': '0',
        'avg_session_duration_minutes': '0',
        'total_screens_visited': 0,
        'unique_screens_count': 0,
        'most_used_feature': 'N/A',
        'most_visited_screen': 'N/A',
        'productivity_score': '0',
      };
    }
  }

  // Get all analytics for user
  Future<Map<String, dynamic>> getAllUserAnalytics({
    required String userId,
    int daysBack = 30,
  }) async {
    try {
      final loginPatterns =
          await getLoginPatterns(userId: userId, daysBack: daysBack);
      final featureUsage =
          await getFeatureUsageStats(userId: userId, limit: 10);
      final screenNavigation =
          await getScreenNavigationStats(userId: userId, daysBack: daysBack);
      final productivity =
          await getUserProductivityMetrics(userId: userId, daysBack: daysBack);

      return {
        'login_patterns': loginPatterns,
        'feature_usage': featureUsage,
        'screen_navigation': screenNavigation,
        'productivity_metrics': productivity,
      };
    } catch (e) {
      return {
        'login_patterns': {},
        'feature_usage': {},
        'screen_navigation': {},
        'productivity_metrics': {},
      };
    }
  }

  // Get analytics for all users (admin only)
  Future<List<Map<String, dynamic>>> getAllUsersAnalyticsSummary({
    int daysBack = 30,
  }) async {
    try {
      final startDate =
          DateTime.now().subtract(Duration(days: daysBack)).toIso8601String();

      // Get all users with their session counts
      final response = await _supabase.rpc('get_all_users_summary', params: {
        'p_start_date': startDate,
      });

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      // Fallback to basic query if function doesn't exist
      try {
        final users = await _supabase
            .from('user_profiles')
            .select('id, full_name, role, email');

        List<Map<String, dynamic>> summary = [];
        for (var user in users as List<dynamic>) {
          final userId = user['id'] as String;
          final metrics = await getUserProductivityMetrics(
              userId: userId, daysBack: daysBack);

          summary.add({
            'user_id': userId,
            'full_name': user['full_name'],
            'role': user['role'],
            'email': user['email'],
            'total_sessions': metrics['total_sessions'],
            'productivity_score': metrics['productivity_score'],
          });
        }

        return summary;
      } catch (e) {
        return [];
      }
    }
  }
}
