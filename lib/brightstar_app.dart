import 'package:flutter/material.dart';
import 'core/app_routes.dart';

class BrightStarApp extends StatelessWidget {
  const BrightStarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrightStar Academy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8E24AA)),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
