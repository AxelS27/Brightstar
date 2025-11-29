import 'package:flutter/material.dart';
import '../../../core/config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ManageSessionsPage extends StatefulWidget {
  const ManageSessionsPage({super.key});

  @override
  State<ManageSessionsPage> createState() => _ManageSessionsPageState();
}

class _ManageSessionsPageState extends State<ManageSessionsPage> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String? _selectedCourse;
  String? _selectedTeacher;
  String? _selectedRoom;
  String? _selectedTimeSlot;
  List<String> _selectedStudents = [];
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> _allStudents = [];
  bool _isLoading = true;

  List<String> get _timeSlots {
    final slots = <String>[];
    for (int h = 7; h < 20; h++) {
      final start = '${h.toString().padLeft(2, '0')}:00';
      final end = '${(h + 1).toString().padLeft(2, '0')}:00';
      slots.add('$start-$end');
    }
    slots.add('Custom Time');
    return slots;
  }

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _loadCourses();
    _loadTeachers();
    _loadRooms();
    _loadAllStudents();
  }

  Future<void> _loadSessions() async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/get_all_sessions.php");
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _sessions = List<Map<String, dynamic>>.from(data['data']);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _sessions = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCourses() async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/get_all_courses.php");
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _courses = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      }
    } catch (e) {}
  }

  Future<void> _loadTeachers() async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/get_all_teachers.php");
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _teachers = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      }
    } catch (e) {}
  }

  Future<void> _loadRooms() async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/get_all_rooms.php");
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _rooms = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      }
    } catch (e) {}
  }

  Future<void> _loadAllStudents() async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/get_all_students.php");
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _allStudents = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      }
    } catch (e) {}
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _createSession() async {
    if (_dateController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a date")));
      return;
    }
    if (_selectedCourse == null ||
        _selectedTeacher == null ||
        _selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a course, teacher, and room"),
        ),
      );
      return;
    }

    String? startTime, endTime;
    if (_selectedTimeSlot == 'Custom Time') {
      startTime = '09:00';
      endTime = '10:00';
    } else if (_selectedTimeSlot != null) {
      final parts = _selectedTimeSlot!.split('-');
      if (parts.length == 2) {
        startTime = parts[0];
        endTime = parts[1];
      }
    }

    if (startTime == null || endTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid time slot")));
      return;
    }

    final url = Uri.parse("${ApiConfig.baseUrl}/create_session.php");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'course_type_id': _selectedCourse,
          'teacher_id': _selectedTeacher,
          'session_date': _dateController.text,
          'start_time': startTime,
          'end_time': endTime,
          'location': _selectedRoom,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        final sessionId = data['id'];
        for (var studentId in _selectedStudents) {
          final enrollUrl = Uri.parse(
            "${ApiConfig.baseUrl}/enroll_student.php",
          );
          await http.post(
            enrollUrl,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              'student_id': studentId,
              'session_id': sessionId,
            }),
          );
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Session created")));
        _dateController.clear();
        _selectedStudents.clear();
        _selectedTimeSlot = null;
        _loadSessions();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Failed')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Network error")));
    }
  }

  Future<void> _editSession(Map<String, dynamic> session) async {
    if (_teachers.isEmpty) {
      await _loadTeachers();
    }
    if (_allStudents.isEmpty) {
      await _loadAllStudents();
    }

    final dateController = TextEditingController(text: session['courseDate']);
    String? selectedCourse = session['course_type_id'];
    String? selectedTeacher = session['teacher_id'];
    String? selectedRoom = session['room'];
    final timeSlot = '${session['startTime']}-${session['endTime']}';
    String? selectedTimeSlot = _timeSlots.contains(timeSlot)
        ? timeSlot
        : 'Custom Time';
    List<String> selectedStudents = await _fetchEnrolledStudentIds(
      session['session_id'],
    );

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Edit Session"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCourse,
                    items: _courses
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c['id'] as String,
                            child: Text(c['name'] as String),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedCourse = v!),
                    decoration: const InputDecoration(labelText: "Course"),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedTeacher,
                    items: _teachers
                        .map(
                          (t) => DropdownMenuItem<String>(
                            value: t['id'] as String,
                            child: Text(t['full_name'] as String),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedTeacher = v!),
                    decoration: const InputDecoration(labelText: "Teacher"),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedRoom,
                    items: _rooms
                        .map(
                          (r) => DropdownMenuItem<String>(
                            value: r['name'],
                            child: Text(r['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedRoom = v!),
                    decoration: const InputDecoration(labelText: "Room"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: "Date (YYYY-MM-DD)",
                    ),
                    readOnly: true,
                    onTap: () => _pickDateInDialog(dateController),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedTimeSlot,
                    items: _timeSlots
                        .map(
                          (slot) => DropdownMenuItem<String>(
                            value: slot,
                            child: Text(slot),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedTimeSlot = v!),
                    decoration: const InputDecoration(labelText: "Time Slot"),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Select Students",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _allStudents.map((student) {
                      final isSelected = selectedStudents.contains(
                        student['id'],
                      );
                      return ChoiceChip(
                        label: Text(student['full_name']),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedStudents.add(student['id']);
                            } else {
                              selectedStudents.remove(student['id']);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedCourse == null ||
                      selectedTeacher == null ||
                      selectedRoom == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Please select a course, teacher, and room",
                        ),
                      ),
                    );
                    return;
                  }
                  String? startTime, endTime;
                  if (selectedTimeSlot == 'Custom Time') {
                    startTime = '09:00';
                    endTime = '10:00';
                  } else if (selectedTimeSlot != null) {
                    final parts = selectedTimeSlot!.split('-');
                    if (parts.length == 2) {
                      startTime = parts[0];
                      endTime = parts[1];
                    }
                  }
                  if (startTime == null || endTime == null) return;
                  final url = Uri.parse(
                    "${ApiConfig.baseUrl}/update_session.php",
                  );
                  try {
                    final res = await http.post(
                      url,
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode({
                        'id': session['session_id'],
                        'course_type_id': selectedCourse,
                        'teacher_id': selectedTeacher,
                        'session_date': dateController.text,
                        'start_time': startTime,
                        'end_time': endTime,
                        'location': selectedRoom,
                      }),
                    );
                    final data = jsonDecode(res.body);
                    if (data['status'] == 'success') {
                      final deleteUrl = Uri.parse(
                        "${ApiConfig.baseUrl}/delete_session_enrollments.php?session_id=${session['session_id']}",
                      );
                      await http.get(deleteUrl);
                      for (var studentId in selectedStudents) {
                        final enrollUrl = Uri.parse(
                          "${ApiConfig.baseUrl}/enroll_student.php",
                        );
                        await http.post(
                          enrollUrl,
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode({
                            'student_id': studentId,
                            'session_id': session['session_id'],
                          }),
                        );
                      }
                      _loadSessions();
                      Navigator.pop(context);
                    }
                  } catch (e) {}
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<List<String>> _fetchEnrolledStudentIds(String sessionId) async {
    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/get_enrolled_students.php?session_id=$sessionId",
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          return List<String>.from(data['data'].map((e) => e['student_id']));
        }
      }
    } catch (e) {}
    return [];
  }

  Future<void> _pickDateInDialog(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      controller.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _deleteSession(String id) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Session"),
            content: const Text("Are you sure?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("No"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Yes"),
              ),
            ],
          ),
        ) ??
        false;
    if (confirm) {
      final url = Uri.parse("${ApiConfig.baseUrl}/delete_session.php");
      try {
        await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({'id': id}),
        );
        _loadSessions();
      } catch (e) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Sessions")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _sessions.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedCourse,
                            items: _courses
                                .map(
                                  (c) => DropdownMenuItem<String>(
                                    value: c['id'] as String,
                                    child: Text(c['name'] as String),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCourse = v!),
                            decoration: const InputDecoration(
                              labelText: "Course",
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedTeacher,
                            items: _teachers
                                .map(
                                  (t) => DropdownMenuItem<String>(
                                    value: t['id'] as String,
                                    child: Text(t['full_name'] as String),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedTeacher = v!),
                            decoration: const InputDecoration(
                              labelText: "Teacher",
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedRoom,
                            items: _rooms
                                .map(
                                  (r) => DropdownMenuItem<String>(
                                    value: r['name'],
                                    child: Text(r['name']),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedRoom = v!),
                            decoration: const InputDecoration(
                              labelText: "Room",
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _dateController,
                            decoration: const InputDecoration(
                              labelText: "Date (YYYY-MM-DD)",
                            ),
                            readOnly: true,
                            onTap: _pickDate,
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedTimeSlot,
                            items: _timeSlots
                                .map(
                                  (slot) => DropdownMenuItem<String>(
                                    value: slot,
                                    child: Text(slot),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedTimeSlot = v!),
                            decoration: const InputDecoration(
                              labelText: "Time Slot",
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Select Students",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _allStudents.map((student) {
                              final isSelected = _selectedStudents.contains(
                                student['id'],
                              );
                              return ChoiceChip(
                                label: Text(student['full_name']),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedStudents.add(student['id']);
                                    } else {
                                      _selectedStudents.remove(student['id']);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _createSession,
                            child: const Text("Create Session"),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final session = _sessions[index - 1];
                return ListTile(
                  title: Text(session['courseName']),
                  subtitle: Text(
                    "${session['courseDate']} • ${session['teacherName']} • ${session['room']}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editSession(session),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteSession(session['session_id']),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
