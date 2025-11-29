import 'package:flutter/material.dart';
import '../../../core/config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ManageCoursesPage extends StatefulWidget {
  const ManageCoursesPage({super.key});

  @override
  State<ManageCoursesPage> createState() => _ManageCoursesPageState();
}

class _ManageCoursesPageState extends State<ManageCoursesPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
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
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _courses = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _createCourse() async {
    if (_idController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Course ID is required")));
      return;
    }

    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Course name is required")));
      return;
    }

    // Validasi format ID: 2 huruf + 3 angka
    if (!_isValidCourseId(_idController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "ID must be 2 letters followed by 3 digits (e.g., CO001)",
          ),
        ),
      );
      return;
    }

    final url = Uri.parse("${ApiConfig.baseUrl}/create_course.php");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'id': _idController.text.toUpperCase(),
          'name': _nameController.text,
          'description': _descriptionController.text,
          'created_by': 'ADM001',
        }),
      );
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Course created")));
        _idController.clear();
        _nameController.clear();
        _descriptionController.clear();
        _loadCourses();
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

  bool _isValidCourseId(String id) {
    if (id.length != 5) return false;
    final firstTwo = id.substring(0, 2);
    final lastThree = id.substring(2, 5);
    return firstTwo.isNotEmpty &&
        lastThree.isNotEmpty &&
        firstTwo.contains(RegExp(r'^[a-zA-Z]+$')) &&
        lastThree.contains(RegExp(r'^[0-9]+$'));
  }

  Future<void> _editCourse(Map<String, dynamic> course) async {
    _idController.text = course['id'];
    _nameController.text = course['name'];
    _descriptionController.text = course['description'] ?? '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Course"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: "Course ID (2 letters + 3 digits)",
              ),
              enabled: false, // ID tidak bisa diubah setelah dibuat
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Course Name"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = Uri.parse("${ApiConfig.baseUrl}/update_course.php");
              try {
                final res = await http.post(
                  url,
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({
                    'id':
                        course['id'], // Gunakan ID asli, bukan yang diinput ulang
                    'name': _nameController.text,
                    'description': _descriptionController.text,
                  }),
                );
                final data = jsonDecode(res.body);
                if (data['status'] == 'success') {
                  _loadCourses();
                  Navigator.pop(context);
                }
              } catch (e) {}
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCourse(String id) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Course"),
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
      final url = Uri.parse("${ApiConfig.baseUrl}/delete_course.php");
      try {
        await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({'id': id}),
        );
        _loadCourses();
      } catch (e) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Courses")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _courses.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _idController,
                            decoration: const InputDecoration(
                              labelText: "Course ID (e.g., CO001)",
                              hintText: "2 letters + 3 digits",
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: "Course Name",
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: "Description",
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _createCourse,
                            child: const Text("Create Course"),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final course = _courses[index - 1];
                return ListTile(
                  title: Text(course['name']),
                  subtitle: Text(course['description'] ?? 'No description'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editCourse(course),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteCourse(course['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
