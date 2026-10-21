import '../today/today_view_model.dart';
import '../update_status/update_status_data.dart';

/// Separated data source for Coordinator (formerly Super Admin).
/// Wraps centralized chat items with the extra role badge field ('Branch Manager')
/// and assigned branch manager names.
List<Map<String, dynamic>> get coordinatorChatItems {
  final managers = availableBranchManagers;
  return todayChatItems.asMap().entries.map((entry) {
    final index = entry.key;
    final item = entry.value;
    final assignedManager = managers[index % managers.length];
    return {
      ...item,
      'role': 'Branch Manager',
      'branchManager': assignedManager,
    };
  }).toList();
}

/// Backward compatibility alias for coordinatorChatItems.
List<Map<String, dynamic>> get superAdminChatItems => coordinatorChatItems;
