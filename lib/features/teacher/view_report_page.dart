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
  Map<String, dynamic>? teacherData;
  bool _isLoading = true;
  List<Map<String, dynamic>> reports = [];
  final List<String> courses = [
    'All Courses',
    'Coding',
    'English',
    'Math',
    'Lego Robotics',
  ];

  @override
  void initState() {
    super.initState();
    _loadTeacherInfo();
    _loadReports();
  }

  Future<void> _loadTeacherInfo() async {
    final data = await TeacherService.getTeacherInfo(widget.teacherId);
    setState(() => teacherData = data);
  }

  Future<void> _loadReports() async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/get_teacher_reports.php?teacherId=${widget.teacherId}",
    );
    try {
      final res = await http.get(url);
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
    final filteredReports = selectedCourse == 'All Courses'
        ? reports
        : reports.where((r) => r['courseName'] == selectedCourse).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(170),
        child: BrightStarAppBar(
          title: "View Reports",
          teacherName: teacherName,
          profileImageUrl: teacherData?['data']?['profile_image'],
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
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
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
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCourse,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(12),
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
                    onChanged: (value) =>
                        setState(() => selectedCourse = value!),
                  ),
                ),
              ),
            ),
            Expanded(
              child: filteredReports.isEmpty
                  ? const Center(
                      child: Text(
                        "No reports found.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredReports.length,
                      itemBuilder: (context, index) {
                        final r = filteredReports[index];
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
