import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart'; // REQUIRED PARA SA FORGOT PASSWORD
import '../services/firebase_auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // REUSABLE ERROR MODAL (Pinalitan natin yung SnackBar!)
  void _showErrorModal(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.firaSans(fontWeight: FontWeight.bold, color: const Color(0xFF0f172a))),
          ],
        ),
        content: Text(message, style: GoogleFonts.firaSans(color: const Color(0xFF64748b))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Okay", style: GoogleFonts.firaSans(color: const Color(0xFF232d74), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // REUSABLE SUCCESS MODAL PARA SA FORGOT PASSWORD
  void _showSuccessModal(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.firaSans(fontWeight: FontWeight.bold, color: const Color(0xFF0f172a))),
          ],
        ),
        content: Text(message, style: GoogleFonts.firaSans(color: const Color(0xFF64748b))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Awesome", style: GoogleFonts.firaSans(color: const Color(0xFF232d74), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Handles the login execution
  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String fullEmail = "${_emailController.text.trim().toLowerCase()}@gmail.com";

      String? result = await _authService.loginUser(
        email: fullEmail,
        password: _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (result != "Success") {
        String displayError = result!;
        String lowercaseResult = result.toLowerCase();

        if (lowercaseResult.contains("credential") ||
            lowercaseResult.contains("password") ||
            lowercaseResult.contains("identifier") ||
            lowercaseResult.contains("record")) {
          displayError = "Incorrect email or password. Please try again.";
        } else if (lowercaseResult.contains("network")) {
          displayError = "Network error. Please check your internet connection.";
        }

        // TATAWAGIN NA NATIN YUNG MODAL IMBES NA SNACKBAR
        _showErrorModal("Login Failed", displayError);
      }
    }
  }

  // MAGIC FUNCTION: FORGOT PASSWORD
  void _resetPassword() async {
    String emailPrefix = _emailController.text.trim().toLowerCase();

    // Check muna kung may tinype siyang email bago niya pinindot yung forgot password
    if (emailPrefix.isEmpty) {
      _showErrorModal("Missing Email", "Please enter your email prefix in the text box first, then click 'Forgot Password?' again.");
      return;
    }

    String fullEmail = "$emailPrefix@gmail.com";

    // Show loading indicator in a dialog while sending the request
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF3772FF))),
    );

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: fullEmail);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      _showSuccessModal("Email Sent!", "A password reset link has been sent to $fullEmail. Please check your inbox or spam folder.");
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      _showErrorModal("Reset Failed", "Something went wrong. Please check if your email is correct or try again later.");
    }
  }

  // Standardized input styling
  InputDecoration _mRescueInputStyle(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94a3b8)),
      prefixIcon: Icon(icon, color: const Color(0xFF94a3b8)),
      filled: true,
      fillColor: const Color(0xFFf8fafc),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFe2e8f0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFe2e8f0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF232d74), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 300,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 40),

                const Text("Enter your NU Email to access your account.", textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Color(0xFF64748b))),
                const SizedBox(height: 20),

                // EMAIL FIELD
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF0f172a)),
                  decoration: _mRescueInputStyle("cunanankd", Icons.email_outlined).copyWith(
                    suffixText: "@gmail.com",
                    suffixStyle: const TextStyle(color: Color(0xFF64748b), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Required field";
                    if (value.contains("@")) return "Do not include @ symbol";
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // PASSWORD FIELD
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF0f172a)),
                  decoration: _mRescueInputStyle("Password", Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF94a3b8)),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? "Required field" : null,
                ),

                // FORGOT PASSWORD BUTTON
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetPassword,
                    child: Text(
                      "Forgot Password?",
                      style: GoogleFonts.firaSans(color: const Color(0xFF3772FF), fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                // LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF232d74),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text("Continue", style: GoogleFonts.firaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 20),

                // NAVIGATION TO REGISTRATION
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ", style: TextStyle(color: Color(0xFF64748b), fontSize: 15)),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                      child: Text("Register here", style: GoogleFonts.firaSans(color: const Color(0xFF232d74), fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}