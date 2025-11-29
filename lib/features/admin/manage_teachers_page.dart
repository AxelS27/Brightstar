import 'package:flutter/material.dart';
import '../../../core/config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ManageTeachersPage extends StatefulWidget {
  const ManageTeachersPage({super.key});

  @override
  State<ManageTeachersPage> createState() => _ManageTeachersPageState();
}

class _ManageTeachersPageState extends State<ManageTeachersPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _specializationController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  List<String> _selectedCourses = [];
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _allCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
    _loadAllCourses();
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
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _teachers = [];
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
      firstDate: DateTime(1970),
      lastDate: DateTime(2025, 12, 31),
    );
    if (picked != null) {
      controller.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _createTeacher() async {
    if (_nameController.text.isEmpty || _dobController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Name and DOB required")));
      return;
    }

    final url = Uri.parse("${ApiConfig.baseUrl}/create_teacher.php");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'full_name': _nameController.text,
          'date_of_birth': _dobController.text,
          'phone': _phoneController.text,
          'specialization': _specializationController.text,
          'email': _emailController.text,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        final teacherId = data['id'];

        for (var courseId in _selectedCourses) {
          final assignUrl = Uri.parse(
            "${ApiConfig.baseUrl}/assign_teacher_to_course.php",
          );
          await http.post(
            assignUrl,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              'teacher_id': teacherId,
              'course_type_id': courseId,
            }),
          );
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Teacher created")));
        _nameController.clear();
        _dobController.clear();
        _phoneController.clear();
        _specializationController.clear();
        _emailController.clear();
        _selectedCourses.clear();
        _loadTeachers();
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

  Future<void> _editTeacher(Map<String, dynamic> teacher) async {
    // Tunggu sampai _allCourses siap
    if (_allCourses.isEmpty) {
      await _loadAllCourses();
    }

    // Ambil course yang sudah diajarkan oleh guru ini
    final localSelectedCourses = await _fetchAssignedCourseIds(teacher['id']);

    // Buat controller lokal
    final nameController = TextEditingController(text: teacher['full_name']);
    final dobController = TextEditingController(text: teacher['date_of_birth']);
    final phoneController = TextEditingController(text: teacher['phone'] ?? '');
    final specializationController = TextEditingController(
      text: teacher['specialization'] ?? '',
    );
    final emailController = TextEditingController(text: teacher['email'] ?? '');

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Edit Teacher"),
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
                    controller: specializationController,
                    decoration: const InputDecoration(
                      labelText: "Specialization",
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: "Email"),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Teach Courses",
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
                    "${ApiConfig.baseUrl}/update_teacher.php",
                  );
                  try {
                    final res = await http.post(
                      url,
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode({
                        'id': teacher['id'],
                        'full_name': nameController.text,
                        'date_of_birth': dobController.text,
                        'phone': phoneController.text,
                        'specialization': specializationController.text,
                        'email': emailController.text,
                      }),
                    );
                    final data = jsonDecode(res.body);
                    if (data['status'] == 'success') {
                      await _updateCourseAssignments(
                        teacher['id'],
                        localSelectedCourses,
                      );
                      _loadTeachers();
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

  // Fungsi baru: ambil course IDs yang sudah diajarkan
  Future<List<String>> _fetchAssignedCourseIds(String teacherId) async {
    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/get_teacher_courses.php?teacher_id=$teacherId",
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
    String teacherId,
    List<String> selectedCourses,
  ) async {
    final deleteUrl = Uri.parse(
      "${ApiConfig.baseUrl}/delete_teacher_courses.php?teacher_id=$teacherId",
    );
    await http.get(deleteUrl);

    for (var courseId in selectedCourses) {
      final assignUrl = Uri.parse(
        "${ApiConfig.baseUrl}/assign_teacher_to_course.php",
      );
      await http.post(
        assignUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'teacher_id': teacherId, 'course_type_id': courseId}),
      );
    }
  }

  Future<void> _deleteTeacher(String id) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Teacher"),
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
      final url = Uri.parse("${ApiConfig.baseUrl}/delete_teacher.php");
      try {
        await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({'id': id}),
        );
        _loadTeachers();
      } catch (e) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Teachers")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _teachers.length + 1,
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
                            controller: _specializationController,
                            decoration: const InputDecoration(
                              labelText: "Specialization",
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
                            "Teach Courses",
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
                            onPressed: _createTeacher,
                            child: const Text("Create Teacher"),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final teacher = _teachers[index - 1];
                return ListTile(
                  title: Text(teacher['full_name']),
                  subtitle: Text(
                    "${teacher['id']} • ${teacher['specialization'] ?? 'N/A'} • ${teacher['email'] ?? 'No email'}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editTeacher(teacher),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteTeacher(teacher['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
