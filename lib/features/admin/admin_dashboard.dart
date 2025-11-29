import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/brightstar_appbar.dart';
import '../../../core/config/api_config.dart';
import 'admin_information_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminDashboard extends StatefulWidget {
  final String adminId;
  const AdminDashboard({super.key, required this.adminId});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _schedules = [];
  Map<String, dynamic>? _adminInfo;
  bool _isLoading = true;
  final _format = DateFormat("yyyy-MM-dd HH:mm");

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
    _loadAllSessions();
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

  Future<void> _loadAllSessions() async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/get_all_sessions.php");
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _schedules = List<Map<String, dynamic>>.from(data['data']);
            _filterSchedulesForDay(_focusedDay);
            _isLoading = false;
          });
        } else {
          _handleError();
        }
      } else {
        _handleError();
      }
    } catch (e) {
      _handleError();
    }
  }

  void _handleError() {
    setState(() {
      _schedules = [];
      _isLoading = false;
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
    final adminName = _adminInfo?['adminName'] ?? 'Admin';
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(170),
        child: BrightStarAppBar(
          title: "Admin Dashboard",
          teacherName: adminName,
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
                  "Global Calendar",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              _buildCalendar(),
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

  List<Map<String, dynamic>> _filteredSchedules = [];
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
          return const Color(0xFF4DB6AC);
        } else if (start.isAfter(endToday)) {
          return const Color(0xFFFFA726);
        } else {
          return const Color(0xFFBA68C8);
        }
      } catch (_) {
        continue;
      }
    }
    return const Color(0xFF8E24AA);
  }
}
