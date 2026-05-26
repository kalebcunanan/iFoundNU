import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _emailPrefixController = TextEditingController();
  final _passwordController = TextEditingController();
  final _sectionController = TextEditingController();

  String? _selectedProgram;
  bool _showDropdown = false;

  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _isLoading = false;
  bool _showPassword = false;
  String _currentPassword = "";

  final Map<String, List<String>> _programs = {
    'School of Education, Arts, and Sciences (SEAS)': [
      'BACHELOR OF ARTS IN COMMUNICATION (ABComm)',
      'BACHELOR OF ARTS IN POLITICAL SCIENCE (BAPolSci)',
      'BACHELOR OF SCIENCE IN MEDICAL TECHNOLOGY (BSMT)',
      'BACHELOR OF SCIENCE IN PSYCHOLOGY (BSPsy)',
      'DOCTOR OF DENTAL MEDICINE (DMD)',
    ],
    'School of Accountancy, Business and Management (SABM)': [
      'BACHELOR OF SCIENCE IN ACCOUNTANCY (BSAccountancy)',
      'BACHELOR OF SCIENCE IN BUSINESS ADMINISTRATION MAJOR IN MARKETING MANAGEMENT (BSBA-MktgMgmt-MNL)',
      'BACHELOR OF SCIENCE IN MANAGEMENT ACCOUNTING (BSMA)',
      'BACHELOR OF SCIENCE IN TOURISM MANAGEMENT (BSTM)',
    ],
    'School of Engineering, Architecture and Technology (SEAT)': [
      'BACHELOR OF SCIENCE IN ARCHITECTURE (BSArch-MNL)',
      'BACHELOR OF SCIENCE IN CIVIL ENGINEERING (BSCE)',
      'BACHELOR OF SCIENCE IN COMPUTER ENGINEERING (BSCpE-MNL)',
      'BACHELOR OF SCIENCE IN COMPUTER SCIENCE WITH SPECIALIZATION IN ARTIFICIAL INTELLIGENCE (BSCS)',
      'BACHELOR OF SCIENCE IN INFORMATION TECHNOLOGY WITH SPECIALIZATION IN MOBILE AND WEB APPLICATION (BSIT-MNL)',
    ],
  };

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _studentIdController.dispose();
    _emailPrefixController.dispose();
    _passwordController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  void _register() async {
    bool isLengthValid = _currentPassword.length >= 8;
    bool hasLetterAndNumber = RegExp(r'[a-zA-Z]').hasMatch(_currentPassword) && RegExp(r'\d').hasMatch(_currentPassword);
    bool hasSpecial = RegExp(r'[^a-zA-Z0-9\s]').hasMatch(_currentPassword);

    if (_formKey.currentState!.validate()) {
      if (_selectedProgram == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select an Academic Program!"), backgroundColor: Colors.red));
        return;
      }

      if (!isLengthValid || !hasLetterAndNumber || !hasSpecial) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Please complete all password requirements!"), backgroundColor: Colors.red.shade600));
        return;
      }

      setState(() => _isLoading = true);

      String fullName = "${_firstNameController.text.trim()} ${_lastNameController.text.trim()} - ${_studentIdController.text.trim()}";
      String fullEmail = "${_emailPrefixController.text.trim().toLowerCase()}@gmail.com";

      String? result = await _authService.registerUser(
        email: fullEmail,
        password: _passwordController.text,
        name: fullName,
        section: _sectionController.text.trim(),
        college: _selectedProgram!,
      );

      setState(() => _isLoading = false);

      if (result != null) {
        bool isSuccess = result.contains("Success");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSuccess
                ? "Success! Check your SPAM/Inbox folder to verify your email before logging in."
                : result),
            backgroundColor: isSuccess ? Colors.green.shade600 : Colors.red.shade600,
            duration: const Duration(seconds: 5),
          ),
        );

        if (isSuccess) {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.pop(context);
          }
        }
      }
    }
  }

  InputDecoration _mRescueInputStyle(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94a3b8)),
      prefixIcon: Icon(icon, color: const Color(0xFF94a3b8)),
      filled: true,
      fillColor: const Color(0xFFf8fafc),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF3772FF), width: 2)),
    );
  }

  Widget _buildRuleRow(bool isValid, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(isValid ? Icons.check_circle : Icons.cancel, size: 16, color: isValid ? const Color(0xFF16a34a) : const Color(0xFF94a3b8)),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 13, color: isValid ? const Color(0xFF16a34a) : const Color(0xFF64748b))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isLengthValid = _currentPassword.length >= 8;
    bool hasLetterAndNumber = RegExp(r'[a-zA-Z]').hasMatch(_currentPassword) && RegExp(r'\d').hasMatch(_currentPassword);
    bool hasSpecial = RegExp(r'[^a-zA-Z0-9\s]').hasMatch(_currentPassword);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0f172a), size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Create Account", style: GoogleFonts.firaSans(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF0f172a))),
              const SizedBox(height: 5),
              const Text("Enter your student details to register.", style: TextStyle(fontSize: 16, color: Color(0xFF64748b))),
              const SizedBox(height: 35),

              TextFormField(
                controller: _firstNameController,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0f172a)),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [UpperCaseTextFormatter()],
                decoration: _mRescueInputStyle("First Name", Icons.person_outline),
                validator: (value) => value!.isEmpty ? "Required field" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _lastNameController,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0f172a)),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [UpperCaseTextFormatter()],
                decoration: _mRescueInputStyle("Last Name", Icons.person_outline),
                validator: (value) => value!.isEmpty ? "Required field" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _studentIdController,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0f172a)),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  StudentIdFormatter(),
                ],
                decoration: _mRescueInputStyle("Student ID (e.g. 2023-123456)", Icons.badge_outlined),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Required field";
                  if (!RegExp(r'^\d{4}-\d{6}$').hasMatch(value)) {
                    return "Format must be YYYY-XXXXXX";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _emailPrefixController,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0f172a)),
                decoration: _mRescueInputStyle("cunanankd", Icons.email_outlined).copyWith(
                  suffixText: "@gmail.com",
                  suffixStyle: const TextStyle(color: Color(0xFF64748b), fontSize: 14, fontWeight: FontWeight.bold),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Required";
                  if (value.contains("@")) return "Do not include @";
                  return null;
                },
              ),
              const SizedBox(height: 15),

              GestureDetector(
                onTap: () => setState(() => _showDropdown = !_showDropdown),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf8fafc),
                    border: Border.all(color: const Color(0xFFe2e8f0)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedProgram ?? "Academic Program",
                          style: TextStyle(
                              fontSize: 14,
                              color: _selectedProgram == null ? const Color(0xFF94a3b8) : const Color(0xFF0f172a),
                              fontWeight: _selectedProgram == null ? FontWeight.normal : FontWeight.bold
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(_showDropdown ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: const Color(0xFF94a3b8)),
                    ],
                  ),
                ),
              ),

              if (_showDropdown)
                Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  margin: const EdgeInsets.only(top: 5, bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFe2e8f0)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Scrollbar(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: _programs.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              color: const Color(0xFFf1f5f9),
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              child: Text(entry.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748b))),
                            ),
                            ...entry.value.map((course) => InkWell(
                              onTap: () => setState(() {
                                _selectedProgram = course;
                                _showDropdown = false;
                              }),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFf1f5f9)))),
                                child: Text(course, style: const TextStyle(fontSize: 13, color: Color(0xFF0f172a))),
                              ),
                            )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              if (!_showDropdown) const SizedBox(height: 15),

              TextFormField(
                controller: _sectionController,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0f172a)),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  SectionTextFormatter(),
                ],
                decoration: _mRescueInputStyle("Section (e.g. POLSCI302)", Icons.class_outlined),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Required field";
                  int digitCount = value.replaceAll(RegExp(r'[^0-9]'), '').length;
                  if (digitCount != 3) {
                    return "Must contain exactly 3 numbers (e.g. POLSCI302)";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _passwordController,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0f172a)),
                obscureText: !_showPassword,
                onChanged: (val) => setState(() => _currentPassword = val),
                decoration: _mRescueInputStyle("Password", Icons.lock_outline).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF94a3b8)),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
              ),

              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 25, left: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRuleRow(isLengthValid, "At least 8 characters"),
                    _buildRuleRow(hasLetterAndNumber, "Contains a letter & number"),
                    _buildRuleRow(hasSpecial, "Contains a special character"),
                  ],
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF232d74),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text("Continue", style: GoogleFonts.firaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class StudentIdFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (text.length > 10) {
      text = text.substring(0, 10);
    }

    String formatted = text;
    if (text.length > 4) {
      formatted = '${text.substring(0, 4)}-${text.substring(4)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class SectionTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.toUpperCase();
    StringBuffer buffer = StringBuffer();
    int letters = 0;
    int digits = 0;

    for (int i = 0; i < text.length; i++) {
      String char = text[i];
      if (RegExp(r'[A-Z]').hasMatch(char)) {
        if (letters < 10) {
          buffer.write(char);
          letters++;
        }
      } else if (RegExp(r'[0-9]').hasMatch(char)) {
        if (digits < 3) {
          buffer.write(char);
          digits++;
        }
      }
    }

    String result = buffer.toString();
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}