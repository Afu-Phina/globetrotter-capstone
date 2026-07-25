import 'dart:convert';
import 'package:http/http.dart' as http;

/// Single place that knows how to talk to the Flask backend.
///
/// Why centralize this? Every screen needs the same base URL, the same
/// JSON encode/decode boilerplate, and (once auth exists) the same
/// "attach the JWT token" step. Putting it here means screens just call
/// ApiService.get('/destinations') and don't repeat that plumbing.
class ApiService {
  // Android emulator reaches the host machine's localhost via 10.0.2.2.
  // iOS simulator / web can use localhost directly.
  static const String baseUrl = '  http://172.20.10.2:5000/api';

  String? _authToken;

  void setToken(String token) => _authToken = token;
  void clearToken() => _authToken = null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  Future<dynamic> get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    return _handle(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(Uri.parse('$baseUrl$path'), headers: _headers);
    return _handle(res);
  }

  dynamic _handle(http.Response res) {
    final decoded = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }
    final message = (decoded is Map && decoded['error'] != null)
        ? decoded['error']
        : 'Request failed (${res.statusCode})';
    throw ApiException(message.toString());
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// One shared instance used across the app.
final apiService = ApiService();
