import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api/api.dart';
import '../../api/authenticated_client.dart';
import '../../login_page/token_storage.dart';
import 'report_model.dart';

/// ViewModel managing state, metrics, date range filters, and API data fetching for the Report section.
class ReportViewModel extends ChangeNotifier {
  final http.Client _client;
  final bool _isInternalClient;
  final TokenStorage? tokenStorage;

  TaskReportData _data;
  bool _isLoading = false;
  String? _errorMessage;

  List<BookingReportGraphItem> _graphData = [];
  bool _isGraphLoading = false;
  String? _graphErrorMessage;

  String? _dateFrom;
  String? _dateTo;

  static String formatIsoDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// Default To date: Current date (YYYY-MM-DD)
  static String get defaultDateTo => formatIsoDate(DateTime.now());

  /// Default From date: Past 7th day (YYYY-MM-DD)
  static String get defaultDateFrom =>
      formatIsoDate(DateTime.now().subtract(const Duration(days: 7)));

  ReportViewModel({
    TaskReportData? initialData,
    List<BookingReportGraphItem>? initialGraphData,
    String? initialDateFrom,
    String? initialDateTo,
    http.Client? client,
    this.tokenStorage,
    bool useDefaultDateRange = true,
  })  : _client = client ?? AuthenticatedClient(),
        _isInternalClient = client == null,
        _data = initialData ?? defaultTaskReportData,
        _graphData = initialGraphData ?? [],
        _dateFrom =
            initialDateFrom ?? (useDefaultDateRange ? defaultDateFrom : null),
        _dateTo =
            initialDateTo ?? (useDefaultDateRange ? defaultDateTo : null);

  TaskReportData get data => _data;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<BookingReportGraphItem> get graphData => _graphData;
  bool get isGraphLoading => _isGraphLoading;
  String? get graphErrorMessage => _graphErrorMessage;

  String? get dateFrom => _dateFrom;
  String? get dateTo => _dateTo;

  void updateData(TaskReportData newData) {
    _data = newData;
    notifyListeners();
  }

  void setGraphData(List<BookingReportGraphItem> newGraphData) {
    _graphData = newGraphData;
    notifyListeners();
  }

  /// Sets date range (YYYY-MM-DD) and fetches updated report graph.
  void setDateRange({String? from, String? to}) {
    if (_dateFrom != from || _dateTo != to) {
      _dateFrom = from;
      _dateTo = to;
      notifyListeners();
      fetchGraphReport(force: true);
    }
  }

  /// Clears date range and fetches report graph without date filters.
  void clearDateRange() {
    if (_dateFrom != null || _dateTo != null) {
      _dateFrom = null;
      _dateTo = null;
      notifyListeners();
      fetchGraphReport(force: true);
    }
  }

  /// Resets date range back to the default: past 7th day to current date.
  void resetToDefaultDateRange() {
    setDateRange(from: defaultDateFrom, to: defaultDateTo);
  }

  /// Fetches booking activity breakdown from ApiConfig.report_graph with optional dateFrom and dateTo.
  Future<void> fetchGraphReport({bool force = false}) async {
    if (_isGraphLoading && !force) return;
    _isGraphLoading = true;
    _graphErrorMessage = null;
    notifyListeners();

    String? token;
    try {
      final isTest = TokenStorage.isTestEnvironment;
      token = await (tokenStorage ?? TokenStorage()).getToken().timeout(
            isTest ? const Duration(milliseconds: 50) : const Duration(seconds: 2),
            onTimeout: () => null,
          );
    } catch (_) {}

    try {
      final headers = <String, String>{
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty)
          'authorization': token.startsWith('Bearer ') ? token : 'Bearer $token',
      };

      final queryParams = <String, String>{};
      if (_dateFrom != null && _dateFrom!.trim().isNotEmpty) {
        queryParams['dateFrom'] = _dateFrom!.trim();
      }
      if (_dateTo != null && _dateTo!.trim().isNotEmpty) {
        queryParams['dateTo'] = _dateTo!.trim();
      }

      final baseUri = Uri.parse(ApiConfig.report_graph);
      final uri = queryParams.isNotEmpty
          ? baseUri.replace(queryParameters: queryParams)
          : baseUri;

      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        final dynamic rawList = decoded is Map<String, dynamic>
            ? (decoded['data'] ?? decoded['items'] ?? decoded['report'])
            : (decoded is List ? decoded : []);

        if (rawList is List) {
          _graphData = rawList
              .map((e) => BookingReportGraphItem.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          _graphData = [];
        }
      } else {
        _graphErrorMessage = 'Failed to load report graph (${response.statusCode})';
        _graphData = [];
      }
    } catch (e) {
      _graphErrorMessage = 'Connection error';
      _graphData = [];
    } finally {
      _isGraphLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshReport() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await fetchGraphReport(force: true);

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_isInternalClient) {
      _client.close();
    }
    super.dispose();
  }
}
