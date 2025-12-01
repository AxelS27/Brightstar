import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../shared/widgets/report_detail_popup.dart';
import '../../shared/widgets/brightstar_appbar.dart';
import 'admin_information_page.dart';

class AdminReportsPage extends StatefulWidget {
  final String adminId;
  const AdminReportsPage({super.key, required this.adminId});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  DateTime? startDate, endDate;
  String selectedCourse = 'All Courses';
  String selectedTeacher = 'All Teachers';
  String selectedStudent = 'All Students';
  List<Map<String, dynamic>> _reports = [];
  List<String> courses = ['All Courses'];
  List<String> teachers = ['All Teachers'];
  List<String> students = ['All Students'];
  Map<String, dynamic>? _adminInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
    _loadFilters();
  }

  Future<void> _loadAdminInfo() async {
    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/get_admin.php?id=${widget.adminId}",
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _adminInfo = data['data'];
          });
        }
      }
    } catch (e) {}
  }

  Future<void> _loadFilters() async {
    try {
      final courseRes = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/get_all_courses.php"),
      );
      if (courseRes.statusCode == 200 &&
          jsonDecode(courseRes.body)['status'] == 'success') {
        courses =
            ['All Courses'] +
            List<String>.from(
              jsonDecode(courseRes.body)['data'].map((c) => c['name']),
            );
      }

      final teacherRes = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/get_all_teachers.php"),
      );
      if (teacherRes.statusCode == 200 &&
          jsonDecode(teacherRes.body)['status'] == 'success') {
        teachers =
            ['All Teachers'] +
            List<String>.from(
              jsonDecode(teacherRes.body)['data'].map((t) => t['full_name']),
            );
      }

      final studentRes = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/get_all_students.php"),
      );
      if (studentRes.statusCode == 200 &&
          jsonDecode(studentRes.body)['status'] == 'success') {
        students =
            ['All Students'] +
            List<String>.from(
              jsonDecode(studentRes.body)['data'].map((s) => s['full_name']),
            );
      }

      setState(() {
        _loadAllReports();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _fmt(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  Future<void> _loadAllReports() async {
    final params = <String, String>{};
    if (startDate != null) params['start_date'] = _fmt(startDate!);
    if (endDate != null) params['end_date'] = _fmt(endDate!);
    if (selectedCourse != 'All Courses') params['course'] = selectedCourse;
    if (selectedTeacher != 'All Teachers') params['teacher'] = selectedTeacher;
    if (selectedStudent != 'All Students') params['student'] = selectedStudent;

    final uri = Uri.parse(
      "${ApiConfig.baseUrl}/get_all_reports.php",
    ).replace(queryParameters: params);
    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _reports = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      }
    } catch (e) {}
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
        _loadAllReports();
      });
    }
  }

  void _showFilterSheet(
    String type,
    List<String> items,
    String current,
    Function(String) onChanged,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select $type',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...items.map((item) {
                return ListTile(
                  title: Text(item),
                  selected: item == current,
                  selectedTileColor: Colors.purple.withAlpha(25),
                  onTap: () {
                    Navigator.pop(context);
                    onChanged(item);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String _formatDateLabel(DateTime? date) {
    if (date == null) return 'Not set';
    return "${date.day}/${date.month}/${date.year}";
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

    final adminName = _adminInfo?['adminName'] ?? 'Admin';
    final profileImageUrl = _adminInfo?['profile_image'];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(170),
        child: BrightStarAppBar(
          title: "All Reports",
          name: adminName,
          profileImageUrl: profileImageUrl,
          showBackButton: false,
          onAvatarTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminInformationPage(adminId: widget.adminId),
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDateButton(
                  label: 'Start: ${_formatDateLabel(startDate)}',
                  onPressed: () => _selectDate(true),
                ),
                _buildDateButton(
                  label: 'End: ${_formatDateLabel(endDate)}',
                  onPressed: () => _selectDate(false),
                ),
                _buildFilterChip(
                  label: selectedCourse,
                  onPressed: () =>
                      _showFilterSheet('Course', courses, selectedCourse, (v) {
                        setState(() => selectedCourse = v);
                        _loadAllReports();
                      }),
                ),
                _buildFilterChip(
                  label: selectedTeacher,
                  onPressed: () => _showFilterSheet(
                    'Teacher',
                    teachers,
                    selectedTeacher,
                    (v) {
                      setState(() => selectedTeacher = v);
                      _loadAllReports();
                    },
                  ),
                ),
                _buildFilterChip(
                  label: selectedStudent,
                  onPressed: () => _showFilterSheet(
                    'Student',
                    students,
                    selectedStudent,
                    (v) {
                      setState(() => selectedStudent = v);
                      _loadAllReports();
                    },
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _reports.isEmpty
                ? const Center(
                    child: Text(
                      "No reports found.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      final r = _reports[index];
                      return GestureDetector(
                        onTap: () => showDialog(
                          context: context,
                          builder: (_) => ReportDetailPopup(
                            studentName: r['studentName'] ?? 'N/A',
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
                                  errorBuilder: (context, error, stackTrace) =>
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r['title'] ?? '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      "${r['teacherName']} → ${r['studentName']}",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      "${r['courseName']} • ${r['courseDate']}",
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
    );
  }

  Widget _buildDateButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.purple,
        side: const BorderSide(color: Color(0xFF8E24AA)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onPressed,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF8E24AA)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      selected: false,
      onSelected: (_) => onPressed(),
      backgroundColor: Colors.white,
      selectedColor: Colors.purple.withAlpha(25),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFF8E24AA)),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
