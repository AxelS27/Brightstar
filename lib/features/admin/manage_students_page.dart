import 'package:flutter/material.dart';
import '../../../core/config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ManageStudentsPage extends StatefulWidget {
  const ManageStudentsPage({super.key});

  @override
  State<ManageStudentsPage> createState() => _ManageStudentsPageState();
}

class _ManageStudentsPageState extends State<ManageStudentsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  List<String> _selectedCourses = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _allCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _loadAllCourses();
  }

  Future<void> _loadStudents() async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/get_all_students.php");
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _students = List<Map<String, dynamic>>.from(data['data']);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _students = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAllCourses() async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/get_all_courses.php");
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _allCourses = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      }
    } catch (e) {}
  }

  Future<void> _pickDateOfBirthInDialog(
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2025, 12, 31),
    );
    if (picked != null) {
      controller.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _createStudent() async {
    if (_nameController.text.isEmpty || _dobController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Name and DOB required")));
      return;
    }

    final url = Uri.parse("${ApiConfig.baseUrl}/create_student.php");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'full_name': _nameController.text,
          'date_of_birth': _dobController.text,
          'phone': _phoneController.text,
          'grade_level': _gradeController.text,
          'email': _emailController.text,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        final studentId = data['id'];

        for (var courseId in _selectedCourses) {
          final enrollUrl = Uri.parse(
            "${ApiConfig.baseUrl}/assign_student_to_course.php",
          );
          await http.post(
            enrollUrl,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              'student_id': studentId,
              'course_type_id': courseId,
            }),
          );
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Student created")));
        _nameController.clear();
        _dobController.clear();
        _phoneController.clear();
        _gradeController.clear();
        _emailController.clear();
        _selectedCourses.clear();
        _loadStudents();
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

  Future<void> _editStudent(Map<String, dynamic> student) async {
    // Muat daftar course yang sudah diambil oleh student
    final localSelectedCourses = await _fetchEnrolledCourseIds(student['id']);

    // Buat controller lokal
    final nameController = TextEditingController(text: student['full_name']);
    final dobController = TextEditingController(text: student['date_of_birth']);
    final phoneController = TextEditingController(text: student['phone'] ?? '');
    final gradeController = TextEditingController(
      text: student['grade_level'] ?? '',
    );
    final emailController = TextEditingController(text: student['email'] ?? '');

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Edit Student"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Full Name"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: dobController,
                    decoration: const InputDecoration(
                      labelText: "Date of Birth (YYYY-MM-DD)",
                    ),
                    readOnly: true,
                    onTap: () => _pickDateOfBirthInDialog(dobController),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: "Phone"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: gradeController,
                    decoration: const InputDecoration(labelText: "Grade Level"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: "Email"),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Enroll in Courses",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _allCourses.map((course) {
                      final isSelected = localSelectedCourses.contains(
                        course['id'],
                      );
                      return ChoiceChip(
                        label: Text(course['name']),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              localSelectedCourses.add(course['id']);
                            } else {
                              localSelectedCourses.remove(course['id']);
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
                  final url = Uri.parse(
                    "${ApiConfig.baseUrl}/update_student.php",
                  );
                  try {
                    final res = await http.post(
                      url,
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode({
                        'id': student['id'],
                        'full_name': nameController.text,
                        'date_of_birth': dobController.text,
                        'phone': phoneController.text,
                        'grade_level': gradeController.text,
                        'email': emailController.text,
                      }),
                    );
                    final data = jsonDecode(res.body);
                    if (data['status'] == 'success') {
                      await _updateCourseAssignments(
                        student['id'],
                        localSelectedCourses,
                      );
                      _loadStudents();
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

  Future<List<String>> _fetchEnrolledCourseIds(String studentId) async {
    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/get_student_courses.php?student_id=$studentId",
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          return List<String>.from(
            data['data'].map((c) => c['course_type_id']),
          );
        }
      }
    } catch (e) {
      // ignore
    }
    return [];
  }

  Future<void> _updateCourseAssignments(
    String studentId,
    List<String> selectedCourses,
  ) async {
    // First, delete all existing assignments for this student
    final deleteUrl = Uri.parse(
      "${ApiConfig.baseUrl}/delete_student_courses.php?student_id=$studentId",
    );
    await http.get(deleteUrl);

    // Then, assign the new ones
    for (var courseId in selectedCourses) {
      final enrollUrl = Uri.parse(
        "${ApiConfig.baseUrl}/assign_student_to_course.php",
      );
      await http.post(
        enrollUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'student_id': studentId, 'course_type_id': courseId}),
      );
    }
  }

  Future<void> _deleteStudent(String id) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Student"),
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
      final url = Uri.parse("${ApiConfig.baseUrl}/delete_student.php");
      try {
        await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({'id': id}),
        );
        _loadStudents();
      } catch (e) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Students")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _students.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: "Full Name",
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _dobController,
                            decoration: const InputDecoration(
                              labelText: "Date of Birth (YYYY-MM-DD)",
                            ),
                            readOnly: true,
                            onTap: () {
                              _dobController.clear();
                              _pickDateOfBirthInDialog(_dobController);
                            },
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: "Phone",
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _gradeController,
                            decoration: const InputDecoration(
                              labelText: "Grade Level",
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: "Email",
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Enroll in Courses",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _allCourses.map((course) {
                              final isSelected = _selectedCourses.contains(
                                course['id'],
                              );
                              return ChoiceChip(
                                label: Text(course['name']),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedCourses.add(course['id']);
                                    } else {
                                      _selectedCourses.remove(course['id']);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _createStudent,
                            child: const Text("Create Student"),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final student = _students[index - 1];
                return ListTile(
                  title: Text(student['full_name']),
                  subtitle: Text(
                    "${student['id']} • ${student['grade_level'] ?? 'N/A'} • ${student['email'] ?? 'No email'}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editStudent(student),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteStudent(student['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
