import 'package:flutter/material.dart';
import 'manage_students_page.dart';
import 'manage_teachers_page.dart';
import 'manage_courses_page.dart';
import 'manage_sessions_page.dart';
import 'admin_information_page.dart';
import 'manage_rooms_page.dart';
import '../../shared/widgets/brightstar_appbar.dart';
import '../../../core/config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ManagementHub extends StatefulWidget {
  final String adminId;
  const ManagementHub({super.key, required this.adminId});

  @override
  State<ManagementHub> createState() => _ManagementHubState();
}

class _ManagementHubState extends State<ManagementHub> {
  Map<String, dynamic>? _adminInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
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
    final adminName = _adminInfo?['adminName'] ?? 'Admin';
    final profileImageUrl = _adminInfo?['profile_image'];
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(170),
        child: BrightStarAppBar(
          title: "Management",
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
