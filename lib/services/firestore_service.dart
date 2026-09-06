import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_profile.dart';
import '../models/skill_tree.dart';
import '../models/college.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch list of colleges from Firestore "colleges" collection
  Future<List<College>> getColleges() async {
    try {
      final snapshot = await _db.collection('colleges').get();
      return snapshot.docs.map((doc) => College.fromFirestore(doc)).toList();
    } catch (e) {
      // Fallback default list if offline or network error
      return [
        College(id: 'JECC', name: 'Jyothi Engineering College', code: 'JECC'),
        College(id: 'MACE', name: 'Mar Athanasius College of Engineering, Kothamangalam', code: 'MACE'),
        College(id: 'GECT', name: 'Government Engineering College, Thrissur', code: 'GECT'),
      ];
    }
  }

  /// Get Student document from "students" collection
  Future<Map<String, dynamic>?> getStudentDoc(String uid) async {
    try {
      final doc = await _db.collection('students').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Update mustResetPassword flag for student
  Future<void> updateMustResetPassword(String uid, bool mustReset) async {
    try {
      await _db.collection('students').doc(uid).set({
        'mustResetPassword': mustReset,
      }, SetOptions(merge: true));
    } catch (e) {
      // Handle error
    }
  }

  // Save/Update Student Profile in both 'users' and 'students' collections in Firebase Firestore
  Future<void> saveStudentProfile(StudentProfile profile) async {
    try {
      final data = profile.toMap();
      await _db.collection('users').doc(profile.uid).set(data, SetOptions(merge: true));
      await _db.collection('students').doc(profile.uid).set(data, SetOptions(merge: true));
    } catch (e) {
      // Local fallback in memory handled via Provider
    }
  }

  // Get Student Profile from Firebase Firestore
  Future<StudentProfile?> getStudentProfile(String uid) async {
    try {
      final doc = await _db.collection('students').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return StudentProfile.fromMap(doc.data()!, uid);
      }
      final userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        return StudentProfile.fromMap(userDoc.data()!, uid);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Get all student documents directly from Firebase Firestore
  Future<List<Map<String, dynamic>>> getStudentsFromFirestore() async {
    try {
      final snapshot = await _db.collection('students').get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      }
    } catch (e) {
      // Fallback
    }
    return [];
  }

  /// Helper to lookup accredited college info for any user ID
  static Map<String, String> getCollegeInfoForUser(String inputId) {
    final cleanId = inputId.trim().toUpperCase();

    // Faculty mapping
    if (cleanId == 'FAC-CSE-0914' || cleanId == 'FAC-ECE-0315') {
      return {'code': 'JECC', 'name': 'Jyothi Engineering College'};
    }
    if (cleanId == 'FAC-IT-0412' || cleanId == 'FAC-CSE-0101') {
      return {'code': 'GECT', 'name': 'Government Engineering College, Thrissur'};
    }
    if (cleanId == 'FAC-BCA-0881') {
      return {'code': 'MACE', 'name': 'Mar Athanasius College of Engineering, Kothamangalam'};
    }

    // Recruiter mapping
    if (cleanId.startsWith('REC-')) {
      return {'code': 'ALL', 'name': 'All Partner Colleges'};
    }

    // Specific Student ID mapping from all_credentials.csv
    const Map<String, String> gectStudents = {
      '22IT002': 'GECT', '22ECE005': 'GECT', '23BCA009': 'GECT', '23IT012': 'GECT',
      '23ECE015': 'GECT', '24CS018': 'GECT', '23CS022': 'GECT', '21CS025': 'GECT',
      '24IT028': 'GECT',
    };
    const Map<String, String> maceStudents = {
      '24BCA003': 'MACE', '24IT007': 'MACE', '22ECE010': 'MACE', '21CS013': 'MACE',
      '21IT017': 'MACE', '22IT020': 'MACE', '24BCA023': 'MACE', '23ECE026': 'MACE',
      '21CS030': 'MACE',
    };

    if (gectStudents.containsKey(cleanId)) {
      return {'code': 'GECT', 'name': 'Government Engineering College, Thrissur'};
    }
    if (maceStudents.containsKey(cleanId)) {
      return {'code': 'MACE', 'name': 'Mar Athanasius College of Engineering, Kothamangalam'};
    }

    return {'code': 'JECC', 'name': 'Jyothi Engineering College'};
  }

  /// Automatically seed all 31 Student, 5 Faculty, and 7 Recruiter accounts directly into Firebase Firestore!
  Future<void> seedFirestoreCollections() async {
    try {
      // 0. Seed Colleges into Firestore "colleges" collection
      final collegeSeed = [
        {'id': 'JECC', 'name': 'Jyothi Engineering College', 'code': 'JECC'},
        {'id': 'GECT', 'name': 'Government Engineering College, Thrissur', 'code': 'GECT'},
        {'id': 'MACE', 'name': 'Mar Athanasius College of Engineering, Kothamangalam', 'code': 'MACE'},
      ];
      for (final col in collegeSeed) {
        await _db.collection('colleges').doc(col['code']).set(col, SetOptions(merge: true));
      }

      // 1. Seed all Student documents into Firestore "students" and "users" collections
      final List<Map<String, dynamic>> allStudentsSeed = [
        {'id': '24CS031', 'name': 'Nikhil Sharma (Fresh Start)', 'email': 'fresh.student@jecc.ac.in', 'password': r'S@Fresh2026!', 'department': 'JECC Computer Science', 'cgpa': 8.00, 'current_semester': 1, 'target_role': 'Full Stack Developer', 'career_readiness': 0, 'completedDailyTaskIds': []},
        {'id': '23CS001', 'name': 'Arjun Nair', 'email': 'arjun.nair@jecc.ac.in', 'password': r'S@nTE2DV@', 'department': 'JECC Computer Science', 'cgpa': 8.45, 'current_semester': 4, 'target_role': 'Data Analyst', 'career_readiness': 78, 'completedDailyTaskIds': ['day1', 'day2']},
        {'id': '22IT002', 'name': 'Meera Krishnan', 'email': 'meera.k@gect.ac.in', 'password': r'S@UCBeCG$', 'department': 'GECT Information Technology', 'cgpa': 8.80, 'current_semester': 6, 'target_role': 'Cloud Architect', 'career_readiness': 85, 'completedDailyTaskIds': []},
        {'id': '24BCA003', 'name': 'Rahul Menon', 'email': 'rahul.m@mace.ac.in', 'password': r'S@SWNvmo*', 'department': 'MACE BCA', 'cgpa': 7.90, 'current_semester': 2, 'target_role': 'Web Developer', 'career_readiness': 62, 'completedDailyTaskIds': []},
        {'id': '21CS004', 'name': 'Ananya Varma', 'email': 'ananya.v@jecc.ac.in', 'password': r'S@NFzmUR!', 'department': 'JECC Computer Science', 'cgpa': 9.10, 'current_semester': 8, 'target_role': 'Data Scientist', 'career_readiness': 92, 'completedDailyTaskIds': []},
        {'id': '22ECE005', 'name': 'Devika S', 'email': 'devika.s@gect.ac.in', 'password': r'S@bKeEzN*', 'department': 'GECT Electronics', 'cgpa': 8.20, 'current_semester': 6, 'target_role': 'Embedded Engineer', 'career_readiness': 74, 'completedDailyTaskIds': []},
        {'id': '23CS006', 'name': 'Siddharth Shenoy', 'email': 'siddharth.s@jecc.ac.in', 'password': r'S@mOzwaj%', 'department': 'JECC Computer Science', 'cgpa': 8.65, 'current_semester': 4, 'target_role': 'Backend Engineer', 'career_readiness': 81, 'completedDailyTaskIds': []},
        {'id': '24IT007', 'name': 'Kavya Rajesh', 'email': 'kavya.r@mace.ac.in', 'password': r'S@Dqx7xa$', 'department': 'MACE Information Technology', 'cgpa': 7.85, 'current_semester': 2, 'target_role': 'UI/UX Developer', 'career_readiness': 65, 'completedDailyTaskIds': []},
        {'id': '21CS008', 'name': 'Aditya Prabhu', 'email': 'aditya.p@jecc.ac.in', 'password': r'S@uynxW9@', 'department': 'JECC Computer Science', 'cgpa': 8.95, 'current_semester': 8, 'target_role': 'DevOps Engineer', 'career_readiness': 89, 'completedDailyTaskIds': []},
        {'id': '23BCA009', 'name': 'Niharika Pillai', 'email': 'niharika.p@gect.ac.in', 'password': r'S@zAl3oz#', 'department': 'GECT BCA', 'cgpa': 8.15, 'current_semester': 4, 'target_role': 'Mobile App Developer', 'career_readiness': 72, 'completedDailyTaskIds': []},
        {'id': '22ECE010', 'name': 'Gautam V', 'email': 'gautam.v@mace.ac.in', 'password': r'S@EzlBSW*', 'department': 'MACE Electronics', 'cgpa': 7.95, 'current_semester': 6, 'target_role': 'IoT Developer', 'career_readiness': 68, 'completedDailyTaskIds': []},
        {'id': '22CS011', 'name': 'Pooja Suresh', 'email': 'pooja.s@jecc.ac.in', 'password': r'S@QLfPkd$', 'department': 'JECC Computer Science', 'cgpa': 8.50, 'current_semester': 6, 'target_role': 'AI/ML Engineer', 'career_readiness': 83, 'completedDailyTaskIds': []},
        {'id': '23IT012', 'name': 'Vishnu Kant', 'email': 'vishnu.k@gect.ac.in', 'password': r'S@HhkVlW%', 'department': 'GECT Information Technology', 'cgpa': 8.10, 'current_semester': 4, 'target_role': 'Cyber Security Analyst', 'career_readiness': 75, 'completedDailyTaskIds': []},
        {'id': '21CS013', 'name': 'Rhea Ananth', 'email': 'rhea.ananth@mace.ac.in', 'password': r'S@4WwgXd$', 'department': 'MACE Computer Science', 'cgpa': 9.30, 'current_semester': 8, 'target_role': 'Software Development Engineer', 'career_readiness': 95, 'completedDailyTaskIds': []},
        {'id': '22BCA014', 'name': 'Abhishek Nair', 'email': 'abhishek.n@jecc.ac.in', 'password': r'S@GIakqC$', 'department': 'JECC BCA', 'cgpa': 7.70, 'current_semester': 6, 'target_role': 'Full Stack Developer', 'career_readiness': 69, 'completedDailyTaskIds': []},
        {'id': '23ECE015', 'name': 'Sneha Mohan', 'email': 'sneha.m@gect.ac.in', 'password': r'S@AaD3Fp$', 'department': 'GECT Electronics', 'cgpa': 8.40, 'current_semester': 4, 'target_role': 'Signal Processing Engineer', 'career_readiness': 77, 'completedDailyTaskIds': []},
        {'id': '22CS016', 'name': 'Karthik Subramanian', 'email': 'karthik.s@jecc.ac.in', 'password': r'S@G9jJBT%', 'department': 'JECC Computer Science', 'cgpa': 8.75, 'current_semester': 6, 'target_role': 'Cloud Native Engineer', 'career_readiness': 86, 'completedDailyTaskIds': []},
        {'id': '21IT017', 'name': 'Varun Gopal', 'email': 'varun.g@mace.ac.in', 'password': r'S@BPAeof!', 'department': 'MACE Information Technology', 'cgpa': 8.05, 'current_semester': 8, 'target_role': 'Database Administrator', 'career_readiness': 73, 'completedDailyTaskIds': []},
        {'id': '24CS018', 'name': 'Nidhi Bhat', 'email': 'nidhi.b@gect.ac.in', 'password': r'S@eaSzVx*', 'department': 'GECT Computer Science', 'cgpa': 8.90, 'current_semester': 1, 'target_role': 'AI Foundations', 'career_readiness': 10, 'completedDailyTaskIds': []},
        {'id': '23BCA019', 'name': 'Aravind Swamy', 'email': 'aravind.s@jecc.ac.in', 'password': r'S@8qwtb7@', 'department': 'JECC BCA', 'cgpa': 7.65, 'current_semester': 4, 'target_role': 'Web Developer', 'career_readiness': 64, 'completedDailyTaskIds': []},
        {'id': '22IT020', 'name': 'Harini V', 'email': 'harini.v@mace.ac.in', 'password': r'S@BXYknV@', 'department': 'MACE Information Technology', 'cgpa': 8.55, 'current_semester': 6, 'target_role': 'Frontend Specialist', 'career_readiness': 82, 'completedDailyTaskIds': []},
        {'id': '21ECE021', 'name': 'Rohan Kamath', 'email': 'rohan.k@jecc.ac.in', 'password': r'S@qUHwXQ#', 'department': 'JECC Electronics', 'cgpa': 8.30, 'current_semester': 8, 'target_role': 'Robotics Engineer', 'career_readiness': 79, 'completedDailyTaskIds': []},
        {'id': '23CS022', 'name': 'Lakshmi Narayanan', 'email': 'lakshmi.n@gect.ac.in', 'password': r'S@j0UTLK#', 'department': 'GECT Computer Science', 'cgpa': 9.00, 'current_semester': 4, 'target_role': 'Data Engineer', 'career_readiness': 90, 'completedDailyTaskIds': []},
        {'id': '24BCA023', 'name': 'Akhil Das', 'email': 'akhil.d@mace.ac.in', 'password': r'S@vbgYiy*', 'department': 'MACE BCA', 'cgpa': 7.50, 'current_semester': 2, 'target_role': 'Junior Software Developer', 'career_readiness': 60, 'completedDailyTaskIds': []},
        {'id': '22IT024', 'name': 'Bhavana Sharma', 'email': 'bhavana.s@jecc.ac.in', 'password': r'S@mkyuCH%', 'department': 'JECC Information Technology', 'cgpa': 8.40, 'current_semester': 6, 'target_role': 'DevOps Engineer', 'career_readiness': 78, 'completedDailyTaskIds': []},
        {'id': '21CS025', 'name': 'Chirag Hegde', 'email': 'chirag.h@gect.ac.in', 'password': r'S@Pz6R9B$', 'department': 'GECT Computer Science', 'cgpa': 8.85, 'current_semester': 8, 'target_role': 'Site Reliability Engineer', 'career_readiness': 87, 'completedDailyTaskIds': []},
        {'id': '23ECE026', 'name': 'Divya Pillai', 'email': 'divya.p@mace.ac.in', 'password': r'S@PB335x*', 'department': 'MACE Electronics', 'cgpa': 8.10, 'current_semester': 4, 'target_role': 'VLSI Designer', 'career_readiness': 71, 'completedDailyTaskIds': []},
        {'id': '22CS027', 'name': 'Eeshwar K', 'email': 'eeshwar.k@jecc.ac.in', 'password': r'S@PpLGmu*', 'department': 'JECC Computer Science', 'cgpa': 8.60, 'current_semester': 6, 'target_role': 'Full Stack Developer', 'career_readiness': 83, 'completedDailyTaskIds': []},
        {'id': '24IT028', 'name': 'Fathima Noor', 'email': 'fathima.n@gect.ac.in', 'password': r'S@K9NULm@', 'department': 'GECT Information Technology', 'cgpa': 8.70, 'current_semester': 2, 'target_role': 'Mobile Developer', 'career_readiness': 76, 'completedDailyTaskIds': []},
        {'id': '22BCA029', 'name': 'Girish M', 'email': 'girish.m@jecc.ac.in', 'password': r'S@aAeKdJ!', 'department': 'JECC BCA', 'cgpa': 7.80, 'current_semester': 6, 'target_role': 'Web Developer', 'career_readiness': 67, 'completedDailyTaskIds': []},
        {'id': '21CS030', 'name': 'Hrishikesh Sen', 'email': 'hrishikesh.s@mace.ac.in', 'password': r'S@kfv1lz*', 'department': 'MACE Computer Science', 'cgpa': 9.25, 'current_semester': 8, 'target_role': 'Machine Learning Engineer', 'career_readiness': 94, 'completedDailyTaskIds': []},
      ];

      for (final item in allStudentsSeed) {
        final colInfo = getCollegeInfoForUser(item['id'] as String);
        item['college'] = colInfo['code'];
        item['collegeName'] = colInfo['name'];
        await _db.collection('students').doc(item['id']).set(item, SetOptions(merge: true));
        await _db.collection('users').doc(item['id']).set(item, SetOptions(merge: true));
      }

      // 2. Seed Faculty members in Firestore "faculties" collection
      final List<Map<String, dynamic>> facultySeed = [
        {'id': 'FAC-CSE-0914', 'name': 'Dr. Priya Nair', 'email': 'priya.nair@jecc.ac.in', 'password': r'M@uNLrUk@', 'department': 'Computer Science Dept', 'college': 'JECC'},
        {'id': 'FAC-IT-0412', 'name': 'Prof. Rajesh Kumar', 'email': 'rajesh.k@gect.ac.in', 'password': r'M@3Pby9E$', 'department': 'Information Technology Dept', 'college': 'GECT'},
        {'id': 'FAC-BCA-0881', 'name': 'Dr. Manoj Pillai', 'email': 'manoj.p@mace.ac.in', 'password': r'M@0kwCcl#', 'department': 'BCA Dept', 'college': 'MACE'},
        {'id': 'FAC-ECE-0315', 'name': 'Prof. Anitha Varghese', 'email': 'anitha.v@jecc.ac.in', 'password': r'M@UEdBab$', 'department': 'Electronics Dept', 'college': 'JECC'},
        {'id': 'FAC-CSE-0101', 'name': 'Dr. Suresh Menon', 'email': 'suresh.m@gect.ac.in', 'password': r'M@6fCs7H$', 'department': 'Computer Science Dept', 'college': 'GECT'},
      ];
      for (final fac in facultySeed) {
        final colInfo = getCollegeInfoForUser(fac['id'] as String);
        fac['college'] = colInfo['code'];
        fac['collegeName'] = colInfo['name'];
        await _db.collection('faculties').doc(fac['id']).set(fac, SetOptions(merge: true));
        await _db.collection('users').doc(fac['id']).set(fac, SetOptions(merge: true));
      }

      // 3. Seed Recruiter profiles in Firestore "recruiters" collection
      final List<Map<String, dynamic>> recruiterSeed = [
        {'id': 'REC-TNP-001', 'name': 'Ananya Sharma', 'email': 'ananya.s@techcorp.com', 'password': r'R@ZKr6U9!', 'company': 'TechCorp Solutions'},
        {'id': 'REC-TNP-002', 'name': 'Karthik Raja', 'email': 'karthik.r@cloudscale.io', 'password': r'R@0dS4dZ*', 'company': 'CloudScale Systems'},
        {'id': 'REC-TNP-003', 'name': 'Vikram Sethi', 'email': 'vikram.s@innovateai.labs', 'password': r'R@OyEwo5%', 'company': 'Innovate AI Labs'},
        {'id': 'REC-TNP-004', 'name': 'Deepa Sundaram', 'email': 'deepa.s@codekraft.tech', 'password': r'R@Tw2hZs%', 'company': 'CodeKraft Global'},
        {'id': 'REC-TNP-005', 'name': 'Rohan Deshmukh', 'email': 'rohan.d@cyberguard.sec', 'password': r'R@UxW2OE*', 'company': 'CyberGuard Security'},
        {'id': 'REC-TNP-006', 'name': 'Priya Nair', 'email': 'priya.n@mobileapps.co', 'password': r'R@O70N3c*', 'company': 'MobilePro Digital'},
        {'id': 'REC-TNP-007', 'name': 'Arun Varma', 'email': 'arun.v@devopsops.io', 'password': r'R@yWaC0X*', 'company': 'InfraScale DevOps'},
      ];
      for (final rec in recruiterSeed) {
        rec['college'] = 'ALL';
        rec['collegeName'] = 'All Partner Colleges';
        await _db.collection('recruiters').doc(rec['id']).set(rec, SetOptions(merge: true));
        await _db.collection('users').doc(rec['id']).set(rec, SetOptions(merge: true));
      }

      // 4. Seed default user profile
      final userDoc = await _db.collection('users').doc('demo_user_001').get();
      if (!userDoc.exists) {
        await _db.collection('users').doc('demo_user_001').set({
          'displayName': 'Arjun Nair',
          'email': 'alex@univ.edu',
          'currentGpa': 8.42,
          'targetGpa': 9.20,
          'careerPath': 'Full Stack Development',
          'weeklyStudyHours': 18.0,
          'certPrepHours': 8.0,
          'stressLevel': 5,
          'completedSkillIds': ['fs1', 'fs2'],
        });
      }

      // 2. Seed NPTEL certificates collection
      final certsSnapshot = await _db.collection('nptel_certificates').limit(1).get();
      if (certsSnapshot.docs.isEmpty) {
        await _db.collection('nptel_certificates').doc('cert_python').set({
          'studentId': 'demo_user_001',
          'courseName': 'Python for Data Science',
          'offeringInstitute': 'IIT Madras',
          'score': 82,
          'creditsEarned': 3,
          'status': 'Approved',
          'fileUrl': 'https://firebasestorage.googleapis.com/v0/b/twin-brain-advisor.firebasestorage.app/o/cert_python.pdf',
        });
        await _db.collection('nptel_certificates').doc('cert_cloud').set({
          'studentId': 'demo_user_001',
          'courseName': 'Cloud Computing Fundamentals',
          'offeringInstitute': 'IIT Ropar',
          'score': 78,
          'creditsEarned': 2,
          'status': 'Approved',
        });
      }

      // 3. Seed Campus Placement Drives collection
      final drivesSnapshot = await _db.collection('drives').limit(1).get();
      if (drivesSnapshot.docs.isEmpty) {
        await _db.collection('drives').doc('tcs_digital').set({
          'companyName': 'TCS Digital',
          'minCgpa': 7.50,
          'maxBacklogs': 0,
          'boardPercentCutoff': 80.0,
          'roleTitle': 'Digital Software Engineer',
          'packageLpa': 7.2,
          'status': 'Upcoming Friday',
        });
        await _db.collection('drives').doc('cognizant_genc').set({
          'companyName': 'Cognizant GenC Next',
          'minCgpa': 7.00,
          'maxBacklogs': 0,
          'boardPercentCutoff': 75.0,
          'roleTitle': 'Full Stack Developer',
          'packageLpa': 6.8,
          'status': 'Open',
        });
      }
    } catch (e) {
      // Ignored for offline operation
    }
  }

  // Fetch Skill Tree for chosen path
  Future<CareerPathSkillTree> getSkillTreeForPath(String careerPath) async {
    try {
      final querySnapshot = await _db
          .collection('career_paths')
          .where('title', isEqualTo: careerPath)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        final List rawSkills = data['skills'] ?? [];
        final skills = rawSkills.map((s) => SkillNode.fromMap(Map<String, dynamic>.from(s))).toList();

        return CareerPathSkillTree(
          pathId: querySnapshot.docs.first.id,
          title: data['title'] ?? careerPath,
          description: data['description'] ?? '',
          iconName: data['iconName'] ?? 'code',
          skills: skills,
        );
      }
    } catch (e) {
      return _getFallbackSkillTree(careerPath);
    }
    return _getFallbackSkillTree(careerPath);
  }

  /// Default extracted skill trees for the 4 IT paths
  CareerPathSkillTree _getFallbackSkillTree(String careerPath) {
    switch (careerPath) {
      case 'Cloud Computing':
        return CareerPathSkillTree(
          pathId: 'cloud_path',
          title: 'Cloud Computing',
          description: 'Master cloud architecture, containerization, CI/CD, and DevOps practices.',
          iconName: 'cloud',
          skills: [
            SkillNode(
              id: 'c1',
              title: 'Linux Fundamentals & Shell Scripting',
              category: 'Infrastructure',
              description: 'Bash automation, file permissions, process management, SSH.',
              difficulty: 'Beginner',
              estimatedHours: 15,
            ),
            SkillNode(
              id: 'c2',
              title: 'Docker & Containerization',
              category: 'DevOps',
              description: 'Dockerfile composition, multi-stage builds, Docker Compose.',
              difficulty: 'Beginner',
              estimatedHours: 20,
            ),
            SkillNode(
              id: 'c3',
              title: 'AWS Core Services (EC2, S3, IAM, VPC)',
              category: 'Cloud Infrastructure',
              description: 'Virtual servers, cloud storage, security policies, networking.',
              difficulty: 'Intermediate',
              estimatedHours: 35,
            ),
            SkillNode(
              id: 'c4',
              title: 'Kubernetes Orchestration',
              category: 'DevOps',
              description: 'Pods, deployments, services, ingress controllers, Helm charts.',
              difficulty: 'Advanced',
              estimatedHours: 40,
            ),
            SkillNode(
              id: 'c5',
              title: 'Terraform Infrastructure as Code',
              category: 'DevOps',
              description: 'Declarative cloud provisioning, state management, modules.',
              difficulty: 'Intermediate',
              estimatedHours: 25,
            ),
          ],
        );

      case 'Machine Learning':
        return CareerPathSkillTree(
          pathId: 'ml_path',
          title: 'Machine Learning',
          description: 'Build data pipelines, train models, and master ML engineering workflows.',
          iconName: 'psychology',
          skills: [
            SkillNode(
              id: 'm1',
              title: 'Python for Data Analysis (NumPy & Pandas)',
              category: 'Data Engineering',
              description: 'Data wrangling, feature extraction, tabular analysis.',
              difficulty: 'Beginner',
              estimatedHours: 20,
            ),
            SkillNode(
              id: 'm2',
              title: 'Classical Machine Learning (Scikit-Learn)',
              category: 'Modeling',
              description: 'Linear regression, decision trees, random forests, clustering.',
              difficulty: 'Intermediate',
              estimatedHours: 30,
            ),
            SkillNode(
              id: 'm3',
              title: 'SQL & Database Querying',
              category: 'Data Engineering',
              description: 'Complex joins, aggregation, indexing, window functions.',
              difficulty: 'Beginner',
              estimatedHours: 15,
            ),
            SkillNode(
              id: 'm4',
              title: 'Deep Learning with PyTorch',
              category: 'Deep Learning',
              description: 'Neural networks, CNNs, Transformers, model training loops.',
              difficulty: 'Advanced',
              estimatedHours: 45,
            ),
            SkillNode(
              id: 'm5',
              title: 'MLOps & Model Deployment',
              category: 'Deployment',
              description: 'REST API wrapping (FastAPI/Flask), model monitoring, MLflow.',
              difficulty: 'Intermediate',
              estimatedHours: 25,
            ),
          ],
        );

      case 'Web Development':
        return CareerPathSkillTree(
          pathId: 'web_path',
          title: 'Web Development',
          description: 'Construct modern, high-performance responsive web applications.',
          iconName: 'web',
          skills: [
            SkillNode(
              id: 'w1',
              title: 'Modern HTML5 & Semantic Web',
              category: 'Frontend',
              description: 'Accessibility (a11y), SEO tags, semantic structure.',
              difficulty: 'Beginner',
              estimatedHours: 10,
            ),
            SkillNode(
              id: 'w2',
              title: 'CSS3, Modern Layouts & Tailwind CSS',
              category: 'Frontend',
              description: 'Flexbox, Grid, keyframe animations, utility classes.',
              difficulty: 'Beginner',
              estimatedHours: 15,
            ),
            SkillNode(
              id: 'w3',
              title: 'JavaScript (ES6+) & Async Programming',
              category: 'Frontend',
              description: 'Promises, Async/Await, Fetch API, Closures, Modules.',
              difficulty: 'Intermediate',
              estimatedHours: 25,
            ),
            SkillNode(
              id: 'w4',
              title: 'React / Vue.js Framework Architecture',
              category: 'Frontend',
              description: 'Component lifecycles, state management, hooks, router.',
              difficulty: 'Intermediate',
              estimatedHours: 35,
            ),
            SkillNode(
              id: 'w5',
              title: 'Web Performance & Core Web Vitals',
              category: 'Optimization',
              description: 'Lighthouse metrics, code splitting, lazy loading, caching.',
              difficulty: 'Advanced',
              estimatedHours: 20,
            ),
          ],
        );

      case 'Full Stack Development':
      default:
        return CareerPathSkillTree(
          pathId: 'fs_path',
          title: 'Full Stack Development',
          description: 'End-to-end full stack software development lifecycle.',
          iconName: 'layers',
          skills: [
            SkillNode(
              id: 'fs1',
              title: 'Frontend Frameworks (React / Next.js)',
              category: 'Frontend',
              description: 'UI components, Server Components, client state.',
              difficulty: 'Intermediate',
              estimatedHours: 30,
            ),
            SkillNode(
              id: 'fs2',
              title: 'Node.js Backend & REST APIs',
              category: 'Backend',
              description: 'Express server, middleware, authentication, error handling.',
              difficulty: 'Intermediate',
              estimatedHours: 25,
            ),
            SkillNode(
              id: 'fs3',
              title: 'PostgreSQL & Relational DB Design',
              category: 'Database',
              description: 'Schema modeling, migrations, indexing, transactions.',
              difficulty: 'Intermediate',
              estimatedHours: 20,
            ),
            SkillNode(
              id: 'fs4',
              title: 'Git, GitHub Actions & CI/CD Pipelines',
              category: 'DevOps',
              description: 'Branch strategies, pull request workflows, automated deployment.',
              difficulty: 'Beginner',
              estimatedHours: 15,
            ),
            SkillNode(
              id: 'fs5',
              title: 'System Design & Scalable Architecture',
              category: 'Architecture',
              description: 'Caching (Redis), load balancers, rate limiting, microservices.',
              difficulty: 'Advanced',
              estimatedHours: 35,
            ),
          ],
        );
    }
  }
}
