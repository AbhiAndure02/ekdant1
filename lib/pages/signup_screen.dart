import 'package:ekdant/components/custom_input.dart';
import 'package:ekdant/services/auth_service.dart';
import 'package:flutter/material.dart';

// ─── Palette ────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF070E1A);
  static const card = Color(0xFF111E33);
  static const surface = Color(0xFF162040);
  static const border = Color(0xFF1E3050);
  static const gold = Color(0xFFD4A843);
  static const goldLt = Color(0xFFF5D078);
  static const green = Color(0xFF1DB954);
  static const red = Color(0xFFE74C3C);
  static const blue = Color(0xFF3D8BF8);
  static const txt = Color(0xFFF0F4FF);
  static const muted = Color(0xFF8A9BB5);
  static const dim = Color(0xFF2A3A55);
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Submitting signup form...'); // Debug log

      final result = await _authService.signUp(
        name: _nameController.text.trim(),
        number: _numberController.text.trim(),
        password: _passwordController.text.trim(),
      );

      print('SignUp result: $result'); // Debug log

      if (!mounted) return;

      // Extract data from your API response structure
      final bool success = result['success'] == true;
      final String message =
          result['message']?.toString() ?? 'Something went wrong';

      setState(() => _isLoading = false);

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: _C.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to login
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        // Show error message
        setState(() => _errorMessage = message);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: _C.red),
        );
      }
    } catch (e) {
      print('SignUp error: $e'); // Debug log

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: _C.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              // Logo and Welcome Section
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_C.gold, _C.goldLt],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _C.gold.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_add_rounded,
                        color: _C.bg,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "Create Account",
                      style: TextStyle(
                        color: _C.txt,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Sign up to start your gaming journey",
                      style: TextStyle(color: _C.muted, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _C.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: _C.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: _C.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Name
                    Container(
                      decoration: BoxDecoration(
                        color: _C.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _C.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Text(
                              "Full Name",
                              style: TextStyle(
                                color: _C.gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          CustomInput(
                            controller: _nameController,
                            label: "",
                            hintText: "Enter your full name",
                            keyboardType: TextInputType.name,
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: _C.muted,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mobile
                    Container(
                      decoration: BoxDecoration(
                        color: _C.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _C.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Text(
                              "Mobile Number",
                              style: TextStyle(
                                color: _C.gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          CustomInput(
                            controller: _numberController,
                            label: "",
                            hintText: "Enter 10-digit mobile number",
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icon(
                              Icons.phone_outlined,
                              color: _C.muted,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your mobile number';
                              }
                              if (value.length < 10) {
                                return 'Enter a valid 10-digit number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    Container(
                      decoration: BoxDecoration(
                        color: _C.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _C.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Text(
                              "Password",
                              style: TextStyle(
                                color: _C.gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          CustomInput(
                            controller: _passwordController,
                            label: "",
                            hintText: "Create a strong password",
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              color: _C.muted,
                            ),
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: _C.muted,
                              ),
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: _C.muted,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Password must be at least 6 characters",
                            style: TextStyle(color: _C.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [_C.gold, _C.goldLt],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _C.gold.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _isLoading ? null : _submitForm,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: _C.bg,
                                  strokeWidth: 2,
                                )
                              : const Text(
                                  "Create Account",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _C.bg,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Center(
                      child: Text(
                        "By signing up, you agree to our",
                        style: TextStyle(color: _C.muted, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Terms of Service",
                          style: TextStyle(
                            color: _C.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          " and ",
                          style: TextStyle(color: _C.muted, fontSize: 12),
                        ),
                        Text(
                          "Privacy Policy",
                          style: TextStyle(
                            color: _C.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  _C.border,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "OR",
                            style: TextStyle(
                              color: _C.muted,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  _C.border,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Sign In Link
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                        style: TextButton.styleFrom(foregroundColor: _C.muted),
                        child: RichText(
                          text: TextSpan(
                            text: "Already have an account? ",
                            style: TextStyle(color: _C.muted, fontSize: 14),
                            children: [
                              TextSpan(
                                text: "Sign In",
                                style: TextStyle(
                                  color: _C.gold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
