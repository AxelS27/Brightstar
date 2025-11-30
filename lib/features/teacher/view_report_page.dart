import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../shared/widgets/report_detail_popup.dart';
import '../../shared/widgets/brightstar_appbar.dart';
import 'teacher_information_page.dart';
import '../../core/services/teacher_service.dart';

class ViewReportPage extends StatefulWidget {
  final String teacherId;
  const ViewReportPage({super.key, required this.teacherId});

  @override
  State<ViewReportPage> createState() => _ViewReportPageState();
}

class _ViewReportPageState extends State<ViewReportPage> {
  String selectedCourse = 'All Courses';
  DateTime? startDate, endDate;
  Map<String, dynamic>? teacherData;
  bool _isLoading = true;
  List<Map<String, dynamic>> reports = [];
  List<String> courses = ['All Courses'];

  @override
  void initState() {
    super.initState();
    _loadTeacherInfo();
    _loadCourses();
  }

  Future<void> _loadTeacherInfo() async {
    final data = await TeacherService.getTeacherInfo(widget.teacherId);
    setState(() => teacherData = data);
  }

  Future<void> _loadCourses() async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/get_all_courses.php");
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['status'] == 'success') {
          final courseList = ['All Courses'];
          for (var course in body['data']) {
            courseList.add(course['name']);
          }
          setState(() {
            courses = courseList;
            _loadReports();
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadReports() async {
    String url =
        "${ApiConfig.baseUrl}/get_teacher_reports.php?teacherId=${widget.teacherId}";
    if (selectedCourse != 'All Courses') {
      url += "&course=${Uri.encodeComponent(selectedCourse)}";
    }
    if (startDate != null) {
      url +=
          "&start_date=${startDate!.year.toString().padLeft(4, '0')}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}";
    }
    if (endDate != null) {
      url +=
          "&end_date=${endDate!.year.toString().padLeft(4, '0')}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}";
    }

    try {
      final res = await http.get(Uri.parse(url));
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
    final teacherName =
        teacherData?['data']?['teacherName'] ?? 'Unknown Teacher';
    final profileImageUrl = teacherData?['data']?['profile_image'];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(170),
        child: BrightStarAppBar(
          title: "View Reports",
          name: teacherName,
          profileImageUrl: profileImageUrl,
          showBackButton: false,
          onAvatarTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    TeacherInformationPage(teacherId: widget.teacherId),
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
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
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
                              studentName: r['studentName'] ?? 'N/A',
                              title: r['title'] ?? '-',
                              course: r['courseName'] ?? '-',
                              meetingNumber:
                                  int.tryParse(
                                    r['session_id'].toString().replaceAll(
                                      'SES',
                                      '',
                                    ),
                                  ) ??
                                  0,
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
