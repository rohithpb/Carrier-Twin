import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../models/college.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../main_navigation.dart';
import 'reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  static final Map<String, String> userPermanentPasswords = {};
  static final Set<String> resetUsers = {};

  static void registerUpdatedPassword(String userId, String newPassword) {
    final cleanId = userId.trim().toUpperCase();
    userPermanentPasswords[cleanId] = newPassword.trim();
    resetUsers.add(cleanId);
  }

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _selectedRole = 'student'; // 'student', 'faculty', 'tnp'
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  List<College> _colleges = [];
  College? _selectedCollege;
  bool _isLoadingColleges = true;

  bool _obscurePassword = true;
  bool _rememberDevice = true;
  bool _isLoading = false;

  final Map<String, Map<String, String>> _roleConfigs = {
    'student': {
      'title': 'Student Portal',
      'badge': 'Student Suite',
      'desc': 'Academics, NPTEL Credits, AI Digital Twin & Placement Drives.',
      'icon': 'school',
      'idLabel': 'Admission Number / ID',
      'idHint': 'Enter Admission Number / Student ID',
      'submitText': 'Sign In to Student Portal',
    },
    'faculty': {
      'title': 'Faculty & Mentor Gateway',
      'badge': 'Faculty Suite',
      'desc': 'Mentee Progress Tracking, Credit Verifications & Endorsements.',
      'icon': 'local_library',
      'idLabel': 'Faculty Employee ID / UID',
      'idHint': 'Enter Faculty Employee ID',
      'submitText': 'Sign In as Mentor / Faculty',
    },
    'tnp': {
      'title': 'Placement Cell & Recruiter Hub',
      'badge': 'Coordinator Suite',
      'desc': 'College-Wide Student Progress Discovery & Talent Matching.',
      'icon': 'corporate_fare',
      'idLabel': 'Recruiter ID / T&P Key',
      'idHint': 'Enter Recruiter ID / T&P Key',
      'submitText': 'Sign In to Recruiter Hub',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadColleges();
  }

  Future<void> _loadColleges() async {
    try {
      final fetchedColleges = await _firestoreService.getColleges();
      if (mounted) {
        setState(() {
          _colleges = fetchedColleges;
          if (_colleges.isNotEmpty) {
            _selectedCollege = _colleges.first;
          }
          _isLoadingColleges = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingColleges = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final inputId = _idController.text.trim().toUpperCase();
    final inputPassword = _passwordController.text.trim();

    if (inputId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your Admission Number or Employee ID.')),
      );
      return;
    }

    if (inputPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password.')),
      );
      return;
    }

    // 1. Strict Role-Based ID Validation
    if (_selectedRole == 'faculty' && !inputId.startsWith('FAC-')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No faculty account found with ID "$inputId". Please switch to the Student Portal tab.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedRole == 'tnp' && !inputId.startsWith('REC-')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No recruiter account found with ID "$inputId". Please switch to the Faculty Gateway or Student Portal.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedRole == 'student' && (inputId.startsWith('FAC-') || inputId.startsWith('REC-'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No student account found with ID "$inputId". Please select the Faculty Gateway or Recruiter Hub tab.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedCollege == null && (_selectedRole == 'student' || _selectedRole == 'faculty')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your institution.')),
      );
      return;
    }

    // 2. Strict College Name & Institution Matching Validation
    if (_selectedRole != 'tnp' && _selectedCollege != null) {
      final collegeInfo = FirestoreService.getCollegeInfoForUser(inputId);
      final expectedCode = collegeInfo['code'] ?? 'JECC';
      final expectedName = collegeInfo['name'] ?? 'Jyothi Engineering College';

      if (_selectedCollege!.code.toUpperCase() != expectedCode.toUpperCase()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Institution Mismatch: Account "$inputId" belongs to $expectedName ($expectedCode). Please select $expectedCode from the dropdown.',
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    // 2. Check Expiry of Temporary Passwords
    final bool hasResetPassword = LoginScreen.resetUsers.contains(inputId);

    if (hasResetPassword) {
      final storedPermanentPass = LoginScreen.userPermanentPasswords[inputId];
      if (inputPassword != storedPermanentPass) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Temporary password has expired. Please log in using your new permanent password.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // Logged in with new permanent password
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back! Signed in with permanent password as $_selectedRole.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainNavigation(userRole: _selectedRole, userId: inputId)),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    // 3. User logging in for first time with unique temporary password -> Mandatory Reset!
    if (!hasResetPassword) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              userRole: _selectedRole,
              userId: inputId,
            ),
          ),
        );
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleInfo = _roleConfigs[_selectedRole]!;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Partner Header Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.school, size: 16, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'ACCREDITED ACADEMIC PARTNER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 6),
                    CircleAvatar(radius: 3, backgroundColor: AppColors.tertiary),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Title & Description
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.displayLarge,
                  children: const [
                    TextSpan(text: 'Welcome to '),
                    TextSpan(
                      text: 'CareerTwin',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Unified Academic & Placement Suite for University Students, Faculty Mentors & Placement Cells.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // Micro Stats Badges
              Row(
                children: [
                  _buildMicroBadge(Icons.auto_awesome, 'AI Twin V3.2 Active', AppColors.primary),
                  const SizedBox(width: 8),
                  _buildMicroBadge(Icons.verified_user, 'College Portal Login', AppColors.tertiary),
                ],
              ),
              const SizedBox(height: 24),

              // Role Selector Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Your Portal Gateway',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Access permissions adjust immediately',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const Icon(Icons.switch_account_outlined, color: AppColors.outline),
                ],
              ),
              const SizedBox(height: 12),

              // 3 Role Tab Radio Buttons
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildRoleTab('student', 'Student', 'Learner', Icons.person),
                    _buildRoleTab('faculty', 'Faculty', 'Mentor', Icons.local_library),
                    _buildRoleTab('tnp', 'T&P Cell', 'Recruiter', Icons.corporate_fare),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Context Information Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _selectedRole == 'student'
                            ? Icons.badge
                            : _selectedRole == 'faculty'
                                ? Icons.school
                                : Icons.business_center,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                roleInfo['title']!,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryFixed,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  roleInfo['badge']!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onPrimaryFixed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            roleInfo['desc']!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sign In Form Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE8E3DC)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Campus Sign In',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(
                              'Select your college & enter credentials',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.surfaceContainer,
                          child: Icon(Icons.lock_outline, size: 16, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Field 1: Select College Dropdown
                    if (_selectedRole == 'student' || _selectedRole == 'faculty') ...[
                      const Text(
                        'Select Institution / College',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      _isLoadingColleges
                          ? Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE8E3DC)),
                              ),
                              child: Row(
                                children: const [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Loading Colleges...', style: TextStyle(color: AppColors.onSurfaceVariant)),
                                ],
                              ),
                            )
                          : DropdownButtonFormField<College>(
                              value: _selectedCollege,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.account_balance_outlined, color: AppColors.outline),
                              ),
                              items: _colleges.map((college) {
                                return DropdownMenuItem<College>(
                                  value: college,
                                  child: Text(
                                    '${college.name} (${college.code})',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedCollege = val;
                                });
                              },
                            ),
                      const SizedBox(height: 16),
                    ],

                    // Field 2: Admission Number / ID
                    Text(
                      roleInfo['idLabel']!,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _idController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.tag, color: AppColors.outline),
                        hintText: roleInfo['idHint'],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Field 3: Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Campus Password',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: const Text('Forgot password?'),
                        ),
                      ],
                    ),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.key_outlined, color: AppColors.outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppColors.onSurfaceVariant,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        hintText: 'Enter password',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Remember Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberDevice,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _rememberDevice = v!),
                        ),
                        const Expanded(
                          child: Text(
                            'Trust & remember this campus device for 30 days',
                            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(roleInfo['submitText']!),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Campus Feed Notices
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      CircleAvatar(radius: 4, backgroundColor: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Campus Feed & Notices',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryFixed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Real-time',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onTertiaryFixed),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildNoticeCard(
                category: 'Recruitment',
                title: 'Upcoming On-Campus Drives: TCS Digital & Cognizant technical assessment registration closes Friday.',
                closing: 'Closes Friday',
                isUrgent: true,
              ),
              const SizedBox(height: 10),
              _buildNoticeCard(
                category: 'NPTEL Swayam',
                title: 'NPTEL Swayam July-Dec Exam Fee Reimbursement window is now open for students with 75%+ scores.',
                closing: 'Window Open',
                isUrgent: false,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMicroBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTab(String key, String label, String sublabel, IconData icon) {
    final isSelected = _selectedRole == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                sublabel,
                style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeCard({
    required String category,
    required String title,
    required String closing,
    required bool isUrgent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E3DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isUrgent ? AppColors.primaryFixed : AppColors.secondaryFixed,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isUrgent ? AppColors.onPrimaryFixed : AppColors.onSecondaryFixed,
                  ),
                ),
              ),
              Text(
                closing,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isUrgent ? AppColors.error : AppColors.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 13, height: 1.3, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
