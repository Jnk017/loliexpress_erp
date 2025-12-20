import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/automation_rules_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/blocked_users_widget.dart';
import './widgets/escalation_config_widget.dart';
import './widgets/execution_history_widget.dart';
import './widgets/rule_builder_dialog_widget.dart';
import './widgets/rules_list_widget.dart';

class AutomationRulesManager extends StatefulWidget {
  const AutomationRulesManager({super.key});

  @override
  State<AutomationRulesManager> createState() => _AutomationRulesManagerState();
}

class _AutomationRulesManagerState extends State<AutomationRulesManager>
    with SingleTickerProviderStateMixin {
  final _rulesService = AutomationRulesService();
  late TabController _tabController;

  Map<String, dynamic>? _statistics;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoadingStats = true);
    try {
      final stats = await _rulesService.getRulesStatistics();
      setState(() {
        _statistics = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() => _isLoadingStats = false);
    }
  }

  void _showRuleBuilder({Map<String, dynamic>? existingRule}) {
    showDialog(
      context: context,
      builder: (context) => RuleBuilderDialogWidget(
        existingRule: existingRule,
        onRuleSaved: () {
          Navigator.pop(context);
          _loadStatistics();
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Automation Rules',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showRuleBuilder(),
            tooltip: 'Create New Rule',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatisticsHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RulesListWidget(
                    onEditRule: (rule) => _showRuleBuilder(existingRule: rule)),
                const BlockedUsersWidget(),
                const EscalationConfigWidget(),
                const ExecutionHistoryWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsHeader() {
    if (_isLoadingStats) {
      return const LinearProgressIndicator();
    }

    return Container(
      padding: EdgeInsets.all(3.w),
      color: Theme.of(context).primaryColor.withAlpha(26),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            'Total Rules',
            _statistics?['total_rules']?.toString() ?? '0',
            Icons.rule_outlined,
            Colors.blue,
          ),
          _buildStatCard(
            'Active Rules',
            _statistics?['active_rules']?.toString() ?? '0',
            Icons.check_circle_outline,
            Colors.green,
          ),
          _buildStatCard(
            'Executions Today',
            _statistics?['executions_today']?.toString() ?? '0',
            Icons.play_circle_outline,
            Colors.orange,
          ),
          _buildStatCard(
            'Blocked Users',
            _statistics?['currently_blocked_users']?.toString() ?? '0',
            Icons.block,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Rules'),
          Tab(text: 'Blocked Users'),
          Tab(text: 'Escalations'),
          Tab(text: 'History'),
        ],
      ),
    );
  }
}
