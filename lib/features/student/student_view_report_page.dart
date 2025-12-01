import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../shared/widgets/report_detail_popup.dart';
import '../../shared/widgets/brightstar_appbar.dart';
import 'student_information_page.dart';

class StudentViewReportPage extends StatefulWidget {
  final String studentId;
  const StudentViewReportPage({super.key, required this.studentId});

  @override
  State<StudentViewReportPage> createState() => _StudentViewReportPageState();
}

class _StudentViewReportPageState extends State<StudentViewReportPage> {
  DateTime? startDate, endDate;
  String selectedCourse = 'All Courses';
  Map<String, dynamic>? studentData;
  bool _isLoading = true;
  List<Map<String, dynamic>> reports = [];
  List<String> courses = ['All Courses'];

  @override
  void initState() {
    super.initState();
    _loadStudentInfo();
    _loadStudentCourses();
  }

  Future<void> _loadStudentInfo() async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/get_student.php?id=${widget.studentId}",
    );
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            studentData = data;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStudentCourses() async {
    try {
      final coursesRes = await http.get(
        Uri.parse(
          "${ApiConfig.baseUrl}/get_student_courses.php?student_id=${widget.studentId}",
        ),
      );
      List<String> courseNames = ['All Courses'];

      if (coursesRes.statusCode == 200) {
        final coursesData = jsonDecode(coursesRes.body);
        if (coursesData['status'] == 'success') {
          final courseIds = List<String>.from(
            coursesData['data'].map((c) => c['course_type_id']),
          );

          if (courseIds.isNotEmpty) {
            final detailsRes = await http.post(
              Uri.parse("${ApiConfig.baseUrl}/get_courses_by_ids.php"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({'course_ids': courseIds}),
            );
            if (detailsRes.statusCode == 200) {
              final detailsData = jsonDecode(detailsRes.body);
              if (detailsData['status'] == 'success') {
                courseNames =
                    ['All Courses'] +
                    List<String>.from(
                      detailsData['data'].map((c) => c['name']),
                    );
              }
            }
          }
        }
      }

      setState(() {
        courses = courseNames;
        _loadReports();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadReports() async {
    final params = <String, String>{'studentId': widget.studentId};
    if (startDate != null) {
      params['start_date'] =
          "${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}";
    }
    if (endDate != null) {
      params['end_date'] =
          "${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}";
    }
    if (selectedCourse != 'All Courses') {
      params['course'] = selectedCourse;
    }

    final uri = Uri.parse(
      "${ApiConfig.baseUrl}/get_student_reports.php",
    ).replace(queryParameters: params);

    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['status'] == 'success') {
          setState(() {
            reports = List<Map<String, dynamic>>.from(body['data']);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
        _loadReports();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF8E24AA)),
        ),
      );
    }
    final studentName =
        studentData?['data']?['studentName'] ?? 'Unknown Student';
    final profileImageUrl = studentData?['data']?['profile_image'];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(170),
        child: BrightStarAppBar(
          title: "My Reports",
          name: studentName,
          profileImageUrl: profileImageUrl,
          showBackButton: false,
          onAvatarTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    StudentInformationPage(studentId: widget.studentId),
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: ListTile(
                            leading: const Icon(Icons.date_range),
                            title: const Text('Start Date'),
                            subtitle: Text(
                              startDate?.toIso8601String().split('T')[0] ??
                                  'Not set',
                            ),
                            onTap: () => _selectDate(true),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Card(
                          child: ListTile(
                            leading: const Icon(Icons.date_range),
                            title: const Text('End Date'),
                            subtitle: Text(
                              endDate?.toIso8601String().split('T')[0] ??
                                  'Not set',
                            ),
                            onTap: () => _selectDate(false),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCourse,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(8),
                        items: courses
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedCourse = value);
                            _loadReports();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: reports.isEmpty
                  ? const Center(
                      child: Text(
                        "No reports found.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: reports.length,
                      itemBuilder: (context, index) {
                        final r = reports[index];
                        return GestureDetector(
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => ReportDetailPopup(
                              studentName: studentName,
                              title: r['title'] ?? '-',
                              course: r['courseName'] ?? '-',
                              meetingNumber: 1,
                              description: r['description'] ?? '-',
                              imageUrl: r['picture'] ?? '',
                              time: "${r['startTime']} - ${r['endTime']}",
                              place: r['room'] ?? '-',
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    r['picture'] ?? '',
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const SizedBox(
                                              width: 70,
                                              height: 70,
                                              child: Center(
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r['title'] ?? '-',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(r['courseName'] ?? '-'),
                                      Text(
                                        "${r['courseDate']} • ${r['time']} • ${r['room']}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
