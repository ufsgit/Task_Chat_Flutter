import '../today/today_data.dart';

/// Separated data source for Super Admin.
/// Wraps centralized chat items with the extra role badge field ('Branch Manager').
List<Map<String, dynamic>> get superAdminChatItems {
  return todayChatItems.map((item) {
    return {
      ...item,
      'role': 'Branch Manager',
    };
  }).toList();
}
