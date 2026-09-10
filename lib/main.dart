import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/student_provider.dart';
import 'providers/skill_provider.dart';
import 'providers/flashcard_provider.dart';
import 'views/auth/login_screen.dart';

/// Entry point of the Digital Twin Academic Advisor application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DigitalTwinAdvisorApp());
}

class DigitalTwinAdvisorApp extends StatefulWidget {
  const DigitalTwinAdvisorApp({super.key});

  @override
  State<DigitalTwinAdvisorApp> createState() => _DigitalTwinAdvisorAppState();
}

class _DigitalTwinAdvisorAppState extends State<DigitalTwinAdvisorApp> {
  bool _phoneFrameEnabled = true;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthStateProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => SkillProvider()),
        ChangeNotifierProvider(create: (_) => FlashcardProvider()),
      ],
      child: MaterialApp(
        title: 'CareerTwin AI Advisor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.warmTheme,
        builder: (context, child) {
          final size = MediaQuery.of(context).size;
          if (_phoneFrameEnabled && size.width > 600) {
            return Scaffold(
              backgroundColor: const Color(0xFF141416), // Sleek dark desktop stage
              body: Stack(
                children: [
                  // Centered Realistic Smartphone Frame
                  Center(
                    child: Container(
                      width: 420,
                      height: 870,
                      margin: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(46),
                        border: Border.all(color: const Color(0xFF2E2E33), width: 8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.65),
                            blurRadius: 36,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(38),
                        child: MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            size: const Size(420, 870),
                          ),
                          child: child ?? const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),

                  // Floating Desktop Controls
                  Positioned(
                    top: 20,
                    right: 24,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _phoneFrameEnabled = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27272A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.fullscreen, size: 18),
                      label: const Text('Fullscreen View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          }

          // Full width mode or narrow screen
          return Stack(
            children: [
              child ?? const SizedBox.shrink(),
              if (size.width > 600)
                Positioned(
                  top: 16,
                  right: 20,
                  child: FloatingActionButton.small(
                    tooltip: 'Switch to Phone View',
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    onPressed: () {
                      setState(() {
                        _phoneFrameEnabled = true;
                      });
                    },
                    child: const Icon(Icons.phone_android, size: 18),
                  ),
                ),
            ],
          );
        },
        home: const LoginScreen(),
      ),
    );
  }
}
