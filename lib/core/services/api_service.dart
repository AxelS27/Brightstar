import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static Future<Map<String, dynamic>> login(String id, String password) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/login.php");
    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id": id, "password": password}),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      return {"status": "error", "message": "Failed to connect to server"};
    }
  }
}
