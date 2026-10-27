import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api/api.dart';
import '../../api/authenticated_client.dart';
import '../../login_page/token_storage.dart';
import '../models/status_chip_model.dart';

/// Service responsible for fetching status filter chips from the backend API.
class StatusChipsService {
  final http.Client client;
  final TokenStorage tokenStorage;

  StatusChipsService({
    http.Client? client,
    TokenStorage? tokenStorage,
  }) : client = client ?? AuthenticatedClient(),
       tokenStorage = tokenStorage ?? TokenStorage();

  /// Fetches status chips from GET ApiConfig.status_chips.
  Future<List<StatusChipModel>> fetchStatusChips() async {
    final isTest = TokenStorage.isTestEnvironment;
    String? token;
    try {
      token = await tokenStorage.getToken().timeout(
        isTest ? const Duration(milliseconds: 50) : const Duration(seconds: 5),
      );
    } catch (_) {}

    try {
      final response = await client.get(
        Uri.parse(ApiConfig.status_chips),
        headers: {
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty)
            'authorization': token.startsWith('Bearer ') ? token : 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        final dynamic rawList = decoded is Map<String, dynamic>
            ? (decoded['data'] ?? decoded['statuses'] ?? decoded['items'])
            : (decoded is List ? decoded : []);

        if (rawList is List) {
          final chips = rawList
              .map((item) => StatusChipModel.fromJson(item as Map<String, dynamic>))
              .where((item) => item.isActive && item.label.isNotEmpty)
              .toList();

          chips.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          return chips;
        }
      }
    } catch (_) {
      // In case of error, callers can handle empty list
    }
    return [];
  }
}
