import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../services/investigation_workspace_service.dart';
import './widgets/evidence_repository_widget.dart';
import './widgets/quick_actions_fab_widget.dart';
import './widgets/tasks_kanban_widget.dart';
import './widgets/team_communications_widget.dart';
import './widgets/timeline_correlations_widget.dart';
import './widgets/workspace_header_widget.dart';
import 'widgets/evidence_repository_widget.dart';
import 'widgets/quick_actions_fab_widget.dart';
import 'widgets/tasks_kanban_widget.dart';
import 'widgets/team_communications_widget.dart';
import 'widgets/timeline_correlations_widget.dart';
import 'widgets/workspace_header_widget.dart';

class IncidentInvestigationWorkspaceScreen extends StatefulWidget {
  final String incidentId;
  final String incidentTitle;
  final String severity;

  const IncidentInvestigationWorkspaceScreen({
    super.key,
    required this.incidentId,
    required this.incidentTitle,
    required this.severity,
  });

  @override
  State<IncidentInvestigationWorkspaceScreen> createState() =>
      _IncidentInvestigationWorkspaceScreenState();
}

class _IncidentInvestigationWorkspaceScreenState
    extends State<IncidentInvestigationWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _workspaceService = InvestigationWorkspaceService();
  RealtimeChannel? _realtimeChannel;
  bool _hasUpdate = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    _realtimeChannel = _workspaceService.subscribeToWorkspace(
      widget.incidentId,
      (payload) {
        setState(() {
          _hasUpdate = true;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _hasUpdate = false;
            });
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (_realtimeChannel != null) {
      _workspaceService.unsubscribeFromWorkspace(_realtimeChannel!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          WorkspaceHeaderWidget(
            incidentId: widget.incidentId,
            incidentTitle: widget.incidentTitle,
            severity: widget.severity,
            hasUpdate: _hasUpdate,
          ),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue[700],
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.blue[700],
              tabs: const [
                Tab(icon: Icon(Icons.task_alt), text: 'Tasks'),
                Tab(icon: Icon(Icons.folder_special), text: 'Evidence'),
                Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
                Tab(icon: Icon(Icons.chat), text: 'Communications'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                TasksKanbanWidget(incidentId: widget.incidentId),
                EvidenceRepositoryWidget(incidentId: widget.incidentId),
                TimelineCorrelationsWidget(incidentId: widget.incidentId),
                TeamCommunicationsWidget(incidentId: widget.incidentId),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: QuickActionsFabWidget(
        incidentId: widget.incidentId,
        onActionComplete: () {
          setState(() {});
        },
      ),
    );
  }
}