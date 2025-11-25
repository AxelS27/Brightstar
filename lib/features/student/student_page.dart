import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/brightstar_appbar.dart';
import '../../shared/widgets/report_detail_popup.dart';
import 'student_information_page.dart';
import '../../../core/services/student_service.dart';

class StudentPage extends StatefulWidget {
  final String studentId;
  const StudentPage({super.key, required this.studentId});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, dynamic>? studentData;
  bool _isLoading = true;
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _filteredSchedules = [];
  final _format = DateFormat("yyyy-MM-dd HH:mm");

  @override
  void initState() {
    super.initState();
    _loadStudentInfo();
    _loadStudentSchedule();
  }

  Future<void> _loadStudentInfo() async {
    final data = await StudentService.getStudentInfo(widget.studentId);
    setState(() {
      studentData = data;
      _isLoading = false;
    });
  }

  Future<void> _loadStudentSchedule() async {
    final schedules = await StudentService.getStudentSchedule(widget.studentId);
    setState(() {
      _schedules = schedules;
      _filterSchedulesForDay(_focusedDay);
    });
  }

  void _filterSchedulesForDay(DateTime day) {
    final dateStr =
        "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
    _filteredSchedules = _schedules
        .where((s) => s["courseDate"] == dateStr)
        .toList();
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  void _goToPreviousMonth() {
    setState(
      () => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1),
    );
  }

  void _goToNextMonth() {
    setState(
      () => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1),
    );
  }

  Future<void> _pickMonthYear() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8E24AA),
              onPrimary: Colors.white,
              onSurface: Color(0xFF4A148C),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _focusedDay = picked;
        _selectedDay = picked;
        _filterSchedulesForDay(picked);
      });
    }
  }

  List<Map<String, dynamic>> _upcomingClasses() {
    final now = DateTime.now();
    return _filteredSchedules.where((s) {
      try {
        final start = _format.parse("${s["courseDate"]} ${s["startTime"]}");
        return start.isAfter(now);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  List<Map<String, dynamic>> _ongoingClasses() {
    final now = DateTime.now();
    return _filteredSchedules.where((s) {
      try {
        final start = _format.parse("${s["courseDate"]} ${s["startTime"]}");
        final end = _format.parse("${s["courseDate"]} ${s["endTime"]}");
        return start.isBefore(now) && end.isAfter(now);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  List<Map<String, dynamic>> _pastClasses() {
    final now = DateTime.now();
    return _filteredSchedules.where((s) {
      try {
        final end = _format.parse("${s["courseDate"]} ${s["endTime"]}");
        return end.isBefore(now);
      } catch (_) {
        return false;
      }
    }).toList();
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
    final upcoming = _upcomingClasses();
    final ongoing = _ongoingClasses();
    final past = _pastClasses();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(170),
        child: BrightStarAppBar(
          title: "Student Dashboard",
          teacherName: studentName,
          profileImageUrl: profileImageUrl,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "My Schedule",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              _buildCalendar(),
              const SizedBox(height: 24),
              if (ongoing.isNotEmpty)
                _buildClassSection("Ongoing Classes", ongoing, "ongoing"),
              if (upcoming.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildClassSection("Upcoming Classes", upcoming, "upcoming"),
              ],
              if (past.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildClassSection("Past Classes", past, "past"),
              ],
              if (upcoming.isEmpty && ongoing.isEmpty && past.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Text(
                    "No classes scheduled for this day.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF3E5F5), Color(0xFFD1A4E3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFF6A1B9A),
                  ),
                  onPressed: _goToPreviousMonth,
                ),
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: _pickMonthYear,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${_monthName(_focusedDay.month)} ${_focusedDay.year}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6A1B9A),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF6A1B9A),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF6A1B9A),
                  ),
                  onPressed: _goToNextMonth,
                ),
              ],
            ),
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _filterSchedulesForDay(selectedDay);
                });
              },
              onPageChanged: (focusedDay) =>
                  setState(() => _focusedDay = focusedDay),
              headerVisible: false,
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Color(0xFF8E24AA),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Color(0xFFCE93D8),
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                todayTextStyle: TextStyle(color: Colors.white),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, events) {
                  final hasClasses = _schedules.any(
                    (s) =>
                        s["courseDate"] == day.toIso8601String().split('T')[0],
                  );
                  return Container(
                    alignment: Alignment.topCenter,
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Column(
                      children: [
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 16,
                            color: isSameDay(day, _selectedDay)
                                ? Colors.white
                                : isSameDay(day, DateTime.now())
                                ? Colors.black
                                : Colors.black54,
                          ),
                        ),
                        if (hasClasses)
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            height: 6,
                            width: 6,
                            decoration: BoxDecoration(
                              color: _getDotColorForDay(day),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
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

  Color _getDotColorForDay(DateTime day) {
    final dateStr =
        "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
    final classes = _schedules
        .where((s) => s["courseDate"] == dateStr)
        .toList();
    if (classes.isEmpty) return Colors.transparent;

    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day);
    final endToday = DateTime(now.year, now.month, now.day, 23, 59);

    for (var cls in classes) {
      try {
        final start = _format.parse("${cls["courseDate"]} ${cls["startTime"]}");
        final end = _format.parse("${cls["courseDate"]} ${cls["endTime"]}");
        if (start.isBefore(endToday) && end.isAfter(startToday)) {
          return const Color(0xFF00C853);
        } else if (start.isAfter(endToday)) {
          return const Color(0xA1FF0426);
        } else {
          return const Color(0xFFD32F2F);
        }
      } catch (_) {
        continue;
      }
    }
    return const Color(0xFF8E24AA);
  }

  Widget _buildClassSection(
    String title,
    List<Map<String, dynamic>> classes,
    String type,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Column(
            children: classes.map((classItem) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: type == "past"
                      ? const Color(0xFFBA68C8)
                      : type == "ongoing"
                      ? const Color(0xFF4DB6AC)
                      : const Color(0xFFFFA726),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.class_, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          "${classItem['courseName']} - ${classItem['teacherName']}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${classItem['courseDate']} (${classItem['startTime']} - ${classItem['endTime']})\nRoom: ${classItem['room']}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (type == "past") const SizedBox(height: 12),
                    if (type == "past")
                      Align(
                        alignment: Alignment.bottomRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => ReportDetailPopup(
                                studentName:
                                    studentData?['data']?['studentName'] ??
                                    'N/A',
                                title: classItem['title'] ?? 'No report',
                                course: classItem['courseName'] ?? '-',
                                meetingNumber: 1,
                                description:
                                    classItem['description'] ??
                                    'No report available',
                                imageUrl: classItem['picture'] ?? '',
                                time:
                                    "${classItem['startTime']} - ${classItem['endTime']}",
                                place: classItem['room'] ?? '-',
                              ),
                            );
                          },
                          icon: const Icon(Icons.visibility),
                          label: const Text("View Report"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
