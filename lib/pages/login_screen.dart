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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _rememberMe = false;
  bool _loading = false;

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final number = _numberController.text.trim();
    final password = _passwordController.text.trim();

    final result = await _authService.signIn(
      number: number,
      password: password,
    );

    setState(() => _loading = false);

    if (result['success']) {
      _showSnackBar("Login successful", isError: false);
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showSnackBar("Login failed: ${result['message']}", isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: isError ? _C.red : _C.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 80),
            // Logo/Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_C.gold, _C.goldLt]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _C.gold.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.login_rounded, color: _C.bg, size: 40),
            ),
            const SizedBox(height: 30),
            const Text(
              "Welcome Back!",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _C.txt,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Login to continue to your account",
              style: TextStyle(color: _C.muted, fontSize: 16),
            ),
            const SizedBox(height: 40),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomInput(
                    controller: _numberController,
                    label: "Mobile Number",
                    hintText: "Enter your 10-digit mobile number",
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your mobile number';
                      }
                      if (value.trim().length < 10) {
                        return 'Enter a valid 10-digit number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomInput(
                    controller: _passwordController,
                    label: "Password",
                    hintText: "Enter your password",
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.trim().length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Remember Me & Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value!;
                                });
                              },
                              fillColor: WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return _C.gold;
                                  }
                                  return _C.card;
                                },
                              ),
                              checkColor: _C.bg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                                side: BorderSide(
                                  color: _rememberMe ? _C.gold : _C.border,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Remember me",
                            style: TextStyle(color: _C.muted, fontSize: 14),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Implement forgot password
                        },
                        style: TextButton.styleFrom(foregroundColor: _C.gold),
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Login Button
                  Container(
                    width: double.infinity,
                    height: 56,
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
                      onPressed: _loading ? null : _handleLogin,
                      child: _loading
                          ? const CircularProgressIndicator(
                              color: _C.bg,
                              strokeWidth: 2,
                            )
                          : const Text(
                              "LOGIN",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _C.bg,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
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

                  const SizedBox(height: 20),

                  // Sign Up Link
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/signup');
                      },
                      style: TextButton.styleFrom(foregroundColor: _C.muted),
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: _C.muted, fontSize: 14),
                          children: [
                            TextSpan(
                              text: "Sign Up",
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

                  // Terms and Privacy
                  Center(
                    child: Text(
                      "By logging in, you agree to our",
                      style: TextStyle(color: _C.muted, fontSize: 11),
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
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        " and ",
                        style: TextStyle(color: _C.muted, fontSize: 11),
                      ),
                      Text(
                        "Privacy Policy",
                        style: TextStyle(
                          color: _C.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
