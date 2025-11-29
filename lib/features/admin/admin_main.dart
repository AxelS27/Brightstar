import 'package:flutter/material.dart';
import 'admin_dashboard.dart';
import 'management_hub.dart';
import 'admin_reports_page.dart';

class AdminMain extends StatefulWidget {
  final String adminId;
  const AdminMain({super.key, required this.adminId});

  @override
  State<AdminMain> createState() => _AdminMainState();
}

class _AdminMainState extends State<AdminMain> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      AdminDashboard(adminId: widget.adminId),
      ManagementHub(adminId: widget.adminId),
      const AdminReportsPage(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF8E24AA),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Management',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}
