import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class StudentService {
  static Future<Map<String, dynamic>?> getStudentInfo(String studentId) async {
    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/get_student.php?id=$studentId",
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["status"] == "success") {
          return data;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getStudentSchedule(
    String studentId,
  ) async {
    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/get_student_schedule.php?studentId=$studentId",
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["status"] == "success") {
          return List<Map<String, dynamic>>.from(data["data"]);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
