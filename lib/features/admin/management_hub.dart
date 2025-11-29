import 'package:flutter/material.dart';
import 'manage_students_page.dart';
import 'manage_teachers_page.dart';
import 'manage_courses_page.dart';
import 'manage_sessions_page.dart';
import 'admin_reports_page.dart';
import 'admin_information_page.dart';
import 'manage_rooms_page.dart';

class ManagementHub extends StatelessWidget {
  final String adminId;
  const ManagementHub({super.key, required this.adminId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Management")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMenuCard(
              "Manage Students",
              Icons.group,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageStudentsPage()),
              ),
            ),
            _buildMenuCard(
              "Manage Teachers",
              Icons.school,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageTeachersPage()),
              ),
            ),
            _buildMenuCard(
              "Manage Courses",
              Icons.book,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageCoursesPage()),
              ),
            ),
            _buildMenuCard(
              "Manage Rooms",
              Icons.meeting_room,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageRoomsPage()),
              ),
            ),
            _buildMenuCard(
              "Manage Sessions",
              Icons.event,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageSessionsPage()),
              ),
            ),
            _buildMenuCard(
              "View Reports",
              Icons.receipt_long,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminReportsPage()),
              ),
            ),
            _buildMenuCard(
              "Admin Profile",
              Icons.person,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminInformationPage(adminId: adminId),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF8E24AA)),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
