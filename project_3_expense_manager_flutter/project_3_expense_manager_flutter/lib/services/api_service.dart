import 'dart:convert';
import 'package:http/http.dart' as http;

/// Change this URL to match your environment.
/// Android emulator: http://10.0.2.2/expense_manager_api/api.php
/// Chrome on the same PC: http://localhost/expense_manager_api/api.php
const String apiBaseUrl = 'http://localhost/expense_manager_api/api.php';

class ApiService {
  Uri _uri(String action, [Map<String, String>? query]) => Uri.parse(apiBaseUrl).replace(
        queryParameters: {'action': action, ...?query},
      );

  Future<Map<String, dynamic>> _request(Uri uri, {Map<String, dynamic>? body, String method = 'GET'}) async {
    final response = method == 'POST'
        ? await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
        : method == 'DELETE'
            ? await http.delete(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
            : await http.get(uri);
    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded is Map ? (decoded['message'] ?? 'API error') : 'API error');
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected API response');
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final result = await _request(_uri('transactions'));
    return List<Map<String, dynamic>>.from(result['data'] ?? []);
  }

  Future<Map<String, dynamic>> getSummary() => _request(_uri('summary'));

  Future<void> saveTransaction({int? id, required String title, required double amount,
    required String type, required String category, required String date, String notes = ''}) async {
    await _request(_uri('save'), method: 'POST', body: {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'transaction_date': date,
      'notes': notes,
    });
  }

  Future<void> deleteTransaction(int id) async {
    await _request(_uri('delete'), method: 'DELETE', body: {'id': id});
  }
}
