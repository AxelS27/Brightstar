import 'package:flutter/material.dart';
import '../../../core/config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CreateSessionPage extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback onSessionCreated;
  const CreateSessionPage({
    super.key,
    required this.selectedDate,
    required this.onSessionCreated,
  });

  @override
  State<CreateSessionPage> createState() => _CreateSessionPageState();
}

class _CreateSessionPageState extends State<CreateSessionPage> {
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String _selectedCourse = 'CO001';
  String _selectedTeacher = 'T270206001';
  final List<String> _selectedStudents = [];

  final List<String> _courses = ['CO001', 'EN001', 'MA001', 'LG001'];
  final List<String> _teachers = ['T270206001', 'T100395001'];
  final List<String> _allStudents = ['S150807001', 'S031208001', 'S221107001'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Session")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text("Date: ${widget.selectedDate.toLocal()}"),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCourse,
                items: _courses
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCourse = v!),
                decoration: const InputDecoration(labelText: "Course"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedTeacher,
                items: _teachers
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedTeacher = v!),
                decoration: const InputDecoration(labelText: "Teacher"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _startTimeController,
                decoration: const InputDecoration(
                  labelText: "Start Time (HH:MM)",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _endTimeController,
                decoration: const InputDecoration(
                  labelText: "End Time (HH:MM)",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: "Location"),
              ),
              const SizedBox(height: 16),
              const Text(
                "Select Students",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _allStudents.map((student) {
                  final isSelected = _selectedStudents.contains(student);
                  return ChoiceChip(
                    label: Text(student),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedStudents.add(student);
                        } else {
                          _selectedStudents.remove(student);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _createSession,
                child: const Text("Create Session"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createSession() async {
    final sessionUrl = Uri.parse("${ApiConfig.baseUrl}/create_session.php");
    final sessionRes = await http.post(
      sessionUrl,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'course_type_id': _selectedCourse,
        'teacher_id': _selectedTeacher,
        'session_date':
            "${widget.selectedDate.year}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')}",
        'start_time': _startTimeController.text,
        'end_time': _endTimeController.text,
        'location': _locationController.text,
      }),
    );

    final sessionData = jsonDecode(sessionRes.body);
    if (sessionData['status'] != 'success') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to create session")));
      return;
    }

    for (var studentId in _selectedStudents) {
      final enrollUrl = Uri.parse("${ApiConfig.baseUrl}/enroll_student.php");
      await http.post(
        enrollUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'student_id': studentId,
          'session_id': sessionData['id'],
        }),
      );
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Session created")));
    widget.onSessionCreated();
    Navigator.pop(context);
  }
}
