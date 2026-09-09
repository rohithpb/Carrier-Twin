import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/student_provider.dart';
import 'providers/skill_provider.dart';
import 'providers/career_coach_provider.dart';
import 'views/auth/login_screen.dart';

/// Entry point of the Digital Twin Academic Advisor application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DigitalTwinAdvisorApp());
}

class DigitalTwinAdvisorApp extends StatelessWidget {
  const DigitalTwinAdvisorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthStateProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => SkillProvider()),
        ChangeNotifierProvider(create: (_) => CareerCoachProvider()),
      ],
      child: MaterialApp(
        title: 'digital_twin_advisor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.warmTheme,
        home: const LoginScreen(),
      ),
    );
  }
}
