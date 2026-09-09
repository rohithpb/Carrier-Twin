import 'package:flutter/material.dart';
import 'career_coach_screen.dart';

/// Unified entrypoint for the GenAI Conversational Career Coach.
/// Automatically connects to the student's digital twin and provides real-time coaching.
class AdvisorScreen extends StatelessWidget {
  const AdvisorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CareerCoachScreen();
  }
}
