import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'courses/courses_screen.dart';
import 'guidance/career_guidance_screen.dart';
import 'profile/profile_screen.dart';
import 'profile/faculty_profile_screen.dart';
import 'profile/recruiter_profile_screen.dart';
import 'advisor/advisor_screen.dart';
import 'mentor/mentor_dashboard_screen.dart';
import 'recruiter/recruiter_dashboard_screen.dart';
import 'auth/login_screen.dart';

import 'package:provider/provider.dart';
import '../providers/student_provider.dart';

class MainNavigation extends StatefulWidget {
  final String userRole; // 'student', 'faculty', 'tnp'
  final String userId;
  const MainNavigation({super.key, this.userRole = 'student', this.userId = ''});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    if (widget.userId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<StudentProvider>(context, listen: false).loadStudentProfile(widget.userId);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _handleSignOut() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userRole == 'faculty') {
      // Faculty / Mentor Mode
      final List<Widget> mentorPages = [
        const MentorDashboardScreen(),
        const CoursesScreen(),
        const AdvisorScreen(),
        FacultyProfileScreen(userId: widget.userId),
      ];

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar('Faculty & Mentor Gateway', 'CS Department HOD Portal'),
        body: PageView(
          controller: _pageController,
          physics: const AlwaysScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: mentorPages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex.clamp(0, mentorPages.length - 1),
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              activeIcon: Icon(Icons.school, color: AppColors.primary),
              label: 'Mentee List',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book, color: AppColors.primary),
              label: 'Curriculum',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined),
              activeIcon: Icon(Icons.forum, color: AppColors.primary),
              label: 'AI Advisor',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person, color: AppColors.primary),
              label: 'Profile',
            ),
          ],
        ),
      );
    } else if (widget.userRole == 'tnp') {
      // Recruiter / T&P Cell Hub Mode
      final List<Widget> recruiterPages = [
        const RecruiterDashboardScreen(),
        const CoursesScreen(),
        const AdvisorScreen(),
        RecruiterProfileScreen(userId: widget.userId),
      ];

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar('Recruiter & T&P Hub', 'College Placement Portal'),
        body: PageView(
          controller: _pageController,
          physics: const AlwaysScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: recruiterPages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex.clamp(0, recruiterPages.length - 1),
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.corporate_fare_outlined),
              activeIcon: Icon(Icons.corporate_fare, color: AppColors.primary),
              label: 'College Talent',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.workspace_premium_outlined),
              activeIcon: Icon(Icons.workspace_premium, color: AppColors.primary),
              label: 'Courses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined),
              activeIcon: Icon(Icons.forum, color: AppColors.primary),
              label: 'AI Match',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person, color: AppColors.primary),
              label: 'Profile',
            ),
          ],
        ),
      );
    }

    // Default Student Mode
    final List<Widget> studentPages = [
      DashboardScreen(onNavigateTab: _onTabTapped),
      const CoursesScreen(),
      const CareerGuidanceScreen(),
      const AdvisorScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar('CareerTwin', 'Unified Student Portal'),
      body: PageView(
        controller: _pageController,
        physics: const AlwaysScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: studentPages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school, color: AppColors.primary),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.stars_outlined),
            activeIcon: Icon(Icons.stars, color: AppColors.primary),
            label: 'Career Path',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_outlined),
            activeIcon: Icon(Icons.forum, color: AppColors.primary),
            label: 'Advisor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String title, String subtitle) {
    return AppBar(
      backgroundColor: AppColors.surface.withOpacity(0.85),
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.school, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.1),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant, height: 1.1),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_outlined, color: AppColors.onSurfaceVariant),
          tooltip: 'Sign Out',
          onPressed: _handleSignOut,
        ),
      ],
    );
  }
}
