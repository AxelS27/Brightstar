import 'package:flutter/material.dart';
import '../../features/auth/login_page.dart';
import '../../features/teacher/teacher_main.dart';
import '../../features/student/student_main.dart';

class AppRoutes {
  static const login = '/';
  static const teacher = '/teacher';
  static const student = '/student';
  static const admin = '/admin';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case teacher:
        final args = settings.arguments as Map<String, dynamic>?;
        final teacherId = args?['id'] ?? '';
        return MaterialPageRoute(
          builder: (_) => TeacherMain(teacherId: teacherId),
        );
      case student:
        final args = settings.arguments as Map<String, dynamic>?;
        final studentId = args?['id'] ?? '';
        return MaterialPageRoute(
          builder: (_) => StudentMain(studentId: studentId),
        );
      case admin:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Admin page coming soon')),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Page not found'))),
        );
    }
  }
}
