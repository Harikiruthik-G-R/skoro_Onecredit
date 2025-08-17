import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';

class UserTypeSelectionScreen extends StatelessWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                SizedBox(height: 40.h),
                // App Logo and Title
                Icon(Icons.local_taxi, size: 80.sp, color: Colors.white),
                SizedBox(height: 12.h),
                Text(
                  'Skoro',
                  style: TextStyle(
                    fontSize: 36.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Your Ride, Your Way',
                  style: TextStyle(fontSize: 16.sp, color: Colors.white70),
                ),
                SizedBox(height: 30.h),

                // User Type Selection Cards
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Choose Your Role',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 30.h),

                      // Rider Card
                      _UserTypeCard(
                        icon: Icons.person,
                        title: 'I\'m a Rider',
                        subtitle: 'Book rides and travel with ease',
                        onTap: () => context.go('/login?userType=rider'),
                      ),

                      SizedBox(height: 20.h),

                      // Driver Card
                      _UserTypeCard(
                        icon: Icons.directions_car,
                        title: 'I\'m a Driver',
                        subtitle: 'Drive and earn money',
                        onTap: () => context.go('/login?userType=driver'),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _UserTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 48.sp, color: AppColors.primary),
            SizedBox(height: 16.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
