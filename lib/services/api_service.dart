import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;

class ApiService {
  // Automatically choose proper host IP depending on platform (Android emulator vs Desktop/Web)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000/api';
      }
    } catch (_) {}
    return 'http://localhost:8000/api';
  }

  /// Health check
  Future<Map<String, dynamic>?> getHealth() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('ApiService getHealth error: $e');
    }
    return null;
  }

  /// Get all students
  Future<List<dynamic>> getStudents() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/students')).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('ApiService getStudents error: $e');
    }
    return [];
  }

  /// Get student digital twin
  Future<Map<String, dynamic>?> getDigitalTwin(String studentId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/students/$studentId/digital-twin')).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('ApiService getDigitalTwin error: $e');
    }
    return null;
  }

  /// Get student recommendations
  Future<Map<String, dynamic>?> getRecommendations(String studentId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/students/$studentId/recommendations')).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('ApiService getRecommendations error: $e');
    }
    return null;
  }

  /// Add new activity to student
  Future<Map<String, dynamic>?> addActivity(String studentId, Map<String, dynamic> activityData) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/students/$studentId/activities'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(activityData),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('ApiService addActivity error: $e');
    }
    return null;
  }

  /// Predict career for student
  Future<Map<String, dynamic>?> predictCareer(String studentId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/predict-career'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'student_id': studentId}),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('ApiService predictCareer error: $e');
    }
    return null;
  }

  /// Get mentor analytics
  Future<Map<String, dynamic>?> getMentorAnalytics(String mentorId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/mentors/$mentorId/analytics')).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('ApiService getMentorAnalytics error: $e');
    }
    return null;
  }

  /// Get placement analytics
  Future<Map<String, dynamic>?> getPlacementAnalytics() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/placement/analytics')).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('ApiService getPlacementAnalytics error: $e');
    }
    return null;
  }

  /// Recruiter student candidate matching
  Future<List<dynamic>> matchRecruiterCandidates({
    required String recruiterId,
    required String jobRole,
    required List<String> requiredSkills,
    int minMatchScore = 60,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/recruiters/$recruiterId/match-students'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'job_role': jobRole,
          'required_skills': requiredSkills,
          'min_match_score': minMatchScore,
        }),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['candidates'] ?? [];
      }
    } catch (e) {
      debugPrint('ApiService matchRecruiterCandidates error: $e');
    }
    return [];
  }

  /// Get opportunities
  Future<List<dynamic>> getOpportunities({String? type}) async {
    try {
      final uri = type != null && type.isNotEmpty
          ? Uri.parse('$baseUrl/opportunities?type=$type')
          : Uri.parse('$baseUrl/opportunities');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('ApiService getOpportunities error: $e');
    }
    return [];
  }
}
