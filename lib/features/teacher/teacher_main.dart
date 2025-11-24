import 'package:flutter/material.dart';
import 'teacher_page.dart';
import 'view_report_page.dart';

class TeacherMain extends StatefulWidget {
  final String teacherId;
  const TeacherMain({super.key, required this.teacherId});

  @override
  State<TeacherMain> createState() => _TeacherMainState();
}

class _TeacherMainState extends State<TeacherMain> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      TeacherPage(teacherId: widget.teacherId),
      ViewReportPage(teacherId: widget.teacherId),
    ];
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF8E24AA),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long_rounded),
            label: 'View Reports',
          ),
        ],
      ),
    );
  }
}
