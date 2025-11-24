import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class TeacherService {
  static Future<Map<String, dynamic>?> getTeacherInfo(String teacherId) async {
    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/get_teacher.php?id=$teacherId",
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

  static Future<List<Map<String, dynamic>>> getTeacherSchedule(
    String teacherId,
  ) async {
    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/get_teacher_schedule.php?teacherId=$teacherId",
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

  static Future<List<Map<String, dynamic>>> getTeacherReports(
    String teacherId,
  ) async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/get_teacher_reports.php?teacherId=$teacherId",
    );
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body['status'] == 'success') {
        return List<Map<String, dynamic>>.from(body['data']);
      }
    }
    return [];
  }
}
