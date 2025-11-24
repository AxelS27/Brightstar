import 'package:flutter/material.dart';
import '../../core/config/api_config.dart';

class BrightStarAppBar extends StatelessWidget {
  final String title;
  final String teacherName;
  final String? profileImageUrl;
  final bool showBackButton;
  final VoidCallback? onBack;
  final VoidCallback? onAvatarTap;
  const BrightStarAppBar({
    super.key,
    required this.title,
    required this.teacherName,
    this.profileImageUrl,
    this.showBackButton = false,
    this.onBack,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (showBackButton)
            Positioned(
              top: 40,
              left: 12,
              child: IconButton(
                onPressed: onBack ?? () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              ),
            ),
          Positioned(
            left: 20,
            top: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/logo.png', height: 42),
                const SizedBox(height: 6),
                const Text(
                  'Bright Starr Academy',
                  style: TextStyle(
                    color: Color(0xFFF3E5F5),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black38,
                        offset: Offset(1, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            top: 35,
            child: GestureDetector(
              onTap: onAvatarTap,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    teacherName,
                    style: const TextStyle(
                      color: Color(0xFFF3E5F5),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(
                            "${ApiConfig.baseUrl}/uploads/$profileImageUrl",
                          )
                        : null,
                    child: profileImageUrl == null
                        ? const Icon(
                            Icons.person,
                            size: 28,
                            color: Color(0xFF6A1B9A),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
