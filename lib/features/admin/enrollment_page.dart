import 'package:flutter/material.dart';
import '../../../core/config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EnrollmentPage extends StatefulWidget {
  final String sessionId;
  const EnrollmentPage({super.key, required this.sessionId});

  @override
  State<EnrollmentPage> createState() => _EnrollmentPageState();
}

class _EnrollmentPageState extends State<EnrollmentPage> {
  String _selectedStudent = 'S150807001';
  final List<String> _students = ['S150807001', 'S031208001', 'S221107001'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enroll Student")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedStudent,
              items: _students
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedStudent = v!),
              decoration: const InputDecoration(labelText: "Student"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final url = Uri.parse(
                  "${ApiConfig.baseUrl}/enroll_student.php",
                );
                try {
                  final response = await http.post(
                    url,
                    headers: {"Content-Type": "application/json"},
                    body: jsonEncode({
                      'student_id': _selectedStudent,
                      'session_id': widget.sessionId,
                    }),
                  );
                  final data = jsonDecode(response.body);
                  if (data['status'] == 'success') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Student enrolled")),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to enroll student")),
                  );
                }
              },
              child: const Text("Enroll Student"),
            ),
          ],
        ),
      ),
    );
  }
}
