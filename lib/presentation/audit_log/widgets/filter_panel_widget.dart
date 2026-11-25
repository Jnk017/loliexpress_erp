import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class FilterPanelWidget extends StatelessWidget {
  final String? selectedUser;
  final String? selectedModule;
  final String? selectedActionType;
  final List<String> availableUsers;
  final List<String> availableModules;
  final List<String> actionTypes;
  final Function(String?) onUserChanged;
  final Function(String?) onModuleChanged;
  final Function(String?) onActionTypeChanged;
  final VoidCallback onReset;
  final int resultCount;

  const FilterPanelWidget({
    super.key,
    required this.selectedUser,
    required this.selectedModule,
    required this.selectedActionType,
    required this.availableUsers,
    required this.availableModules,
    required this.actionTypes,
    required this.onUserChanged,
    required this.onModuleChanged,
    required this.onActionTypeChanged,
    required this.onReset,
    required this.resultCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Advanced Filters',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  onReset();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Réinitialiser'),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // User filter
          _buildFilterSection(
            context,
            'Filter by User',
            Icons.person_outline,
            DropdownButtonFormField<String>(
              initialValue: selectedUser,
              decoration: InputDecoration(
                hintText: 'Select user',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 3.w,
                  vertical: 1.5.h,
                ),
              ),
              items: availableUsers.map((user) {
                return DropdownMenuItem(
                  value: user,
                  child: Text(user),
                );
              }).toList(),
              onChanged: onUserChanged,
            ),
          ),

          SizedBox(height: 2.h),

          // Module filter
          _buildFilterSection(
            context,
            'Filter by Module',
            Icons.folder_outlined,
            DropdownButtonFormField<String>(
              initialValue: selectedModule,
              decoration: InputDecoration(
                hintText: 'Select module',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 3.w,
                  vertical: 1.5.h,
                ),
              ),
              items: availableModules.map((module) {
                return DropdownMenuItem(
                  value: module,
                  child: Text(module),
                );
              }).toList(),
              onChanged: onModuleChanged,
            ),
          ),

          SizedBox(height: 2.h),

          // Action type filter
          _buildFilterSection(
            context,
            'Filter by Action Type',
            Icons.play_circle_outline,
            DropdownButtonFormField<String>(
              initialValue: selectedActionType,
              decoration: InputDecoration(
                hintText: 'Select action type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 3.w,
                  vertical: 1.5.h,
                ),
              ),
              items: actionTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: onActionTypeChanged,
            ),
          ),

          SizedBox(height: 2.h),

          // Result count
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(width: 2.w),
                Text(
                  '$resultCount results found',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 2.h),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
      BuildContext context, String title, IconData icon, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 5.w, color: Colors.grey[600]),
            SizedBox(width: 2.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        child,
      ],
    );
  }
}
