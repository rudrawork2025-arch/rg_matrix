import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard.dart';
import 'signup.dart';
import 'forgot_password_screen.dart'; // Added import for Forgot Password screen

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isGoogleSignInInitialized = false;

  // Use the new v7 singleton instance
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));

    // Initialize Google Sign-In as required by v7+
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      // PASTE YOUR WEB CLIENT ID HERE:
      await _googleSignIn.initialize(
        serverClientId: '795052324512-vvi7mccd8haq37aql2gorctfcm68482h.apps.googleusercontent.com',
      );
      _isGoogleSignInInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize Google Sign-In: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final String enteredEmail = _emailController.text.trim().toLowerCase();
    final String enteredPassword = _passwordController.text;

    final String? registeredEmail = prefs.getString('saved_email');
    final String? registeredPassword = prefs.getString('saved_password');
    final String? registeredName = prefs.getString('saved_name');

    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);

    String doctorName = 'Doctor';

    if (registeredEmail != null && registeredPassword != null) {
      if (enteredEmail == registeredEmail && enteredPassword == registeredPassword) {
        // Extract ONLY the first name (e.g., "Rudra" from "Rudra Bhanushali")
        if (registeredName != null && registeredName.trim().isNotEmpty) {
          doctorName = registeredName.trim().split(' ')[0];
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid email or password!"), backgroundColor: Colors.redAccent),
        );
        return;
      }
    } else {
      // Fallback: If logging in without a local signup, split the email prefix or use default
      final namePart = enteredEmail.split('@')[0];
      if (namePart.isNotEmpty) {
        final cleanName = namePart.replaceAll(RegExp(r'[0-9]'), '');
        if (cleanName.isNotEmpty) {
          doctorName = cleanName[0].toUpperCase() + cleanName.substring(1);
        } else {
          doctorName = namePart[0].toUpperCase() + namePart.substring(1);
        }
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorHomeScreen(doctorName: doctorName),
      ),
    );
  }

  // ---------------- GOOGLE SIGN IN LOGIC (VERSION 7+) ----------------
  Future<void> _handleGoogleSignIn() async {
    if (!_isGoogleSignInInitialized) {
      await _initializeGoogleSignIn();
    }

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final GoogleSignInAccount? account = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );

      if (account != null) {
        debugPrint("Google Sign-In Success: ${account.email}");

        // Extract clean first name from Google profile or email (strips numbers like 7234)
        final rawName = account.displayName ?? account.email.split('@')[0];
        final cleanName = rawName.replaceAll(RegExp(r'[0-9]'), '').trim();
        final String doctorName = cleanName.isNotEmpty
            ? cleanName.split(' ')[0]
            : rawName.split(' ')[0];

        final formattedName = doctorName.isNotEmpty
            ? doctorName[0].toUpperCase() + doctorName.substring(1)
            : 'Doctor';

        if (!mounted) return;

        // Pass the formatted first name to the dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorHomeScreen(doctorName: formattedName),
          ),
        );
      }
    } catch (error) {
      debugPrint("Google Sign-In Error: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Google Sign-In failed: $error"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF161921),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigoAccent.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        size: 64,
                        color: Colors.indigoAccent,
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 32),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          if (_emailFocus.hasFocus)
                            BoxShadow(
                              color: Colors.indigoAccent.withOpacity(0.25),
                              blurRadius: 12,
                              spreadRadius: 2,
                            )
                        ],
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(
                              color: _emailFocus.hasFocus ? Colors.indigoAccent : Colors.grey[500]),
                          prefixIcon: Icon(Icons.email_outlined,
                              color: _emailFocus.hasFocus ? Colors.indigoAccent : Colors.grey[500]),
                          filled: true,
                          fillColor: const Color(0xFF222631),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.indigoAccent, width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@') || !value.contains('.com')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          if (_passwordFocus.hasFocus)
                            BoxShadow(
                              color: Colors.indigoAccent.withOpacity(0.25),
                              blurRadius: 12,
                              spreadRadius: 2,
                            )
                        ],
                      ),
                      child: TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                              color: _passwordFocus.hasFocus ? Colors.indigoAccent : Colors.grey[500]),
                          prefixIcon: Icon(Icons.lock_outline,
                              color: _passwordFocus.hasFocus ? Colors.indigoAccent : Colors.grey[500]),
                          filled: true,
                          fillColor: const Color(0xFF222631),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey[500],
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.indigoAccent, width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(color: Colors.indigoAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: Colors.indigoAccent.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                            : const Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[800])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[800])),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFF222631),
                          side: BorderSide(color: Colors.grey[800]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isGoogleLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.indigoAccent,
                            strokeWidth: 2,
                          ),
                        )
                            : Image.network(
                          'https://www.google.com/favicon.ico',
                          height: 20,
                          width: 20,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.g_mobiledata, size: 24, color: Colors.white),
                        ),
                        label: Text(
                          _isGoogleLoading ? 'Signing in...' : 'Continue with Google',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                              color: Colors.indigoAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}