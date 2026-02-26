import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (firstName.isEmpty || lastName.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signUpWithEmailAndPassword(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        password: password,
      );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (Route<dynamic> route) => false, // Remove all previous routes
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Sign up failed';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else {
         message = e.message ?? message;
      }
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An unexpected error occurred.')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf5f7f8), // background-light
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuC3d8huYBXMDLUbFtGKAEvtWpw0NB-Gz6TiUNQRmnB2Wvv6kjNpnWdQtJhTDPyzdyPaFhaghXqCnHEKuLWjswfXlLxRg1p4sU01c1tYoZyWFsmHxE0701vaJcRk0CCIBGegJaAUrErlKFtI2WtfsMT2tI-ok1EDI0jwB4gGfHryrV462MzWo2PvD-60LPwxdBmS_07DJFvya2YTgnoyz_p2pgL-_tA6irnpmkuLQBw8DKZ_g6lD0WTc7sVyzk4k807MTdus5V4fB7k',
              fit: BoxFit.cover,
            ),
          ),
          
          // Gradients and Overlays
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.1), 
                    Colors.transparent,
                    Colors.black.withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ),

          // Floating Background Clouds
          Positioned(
            top: MediaQuery.of(context).size.height * 0.1,
            left: MediaQuery.of(context).size.width * 0.15,
            child: const Opacity(
              opacity: 0.4,
              child: Icon(Icons.cloud, color: Colors.white, size: 56),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            right: MediaQuery.of(context).size.width * 0.2,
            child: const Opacity(
              opacity: 0.4,
              child: Icon(Icons.cloud, color: Colors.white, size: 48),
            ),
          ),

          // Header
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0a2540), size: 18),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: const [
                       Icon(Icons.waves, color: Color(0xFF0a2540), size: 20),
                       SizedBox(width: 8),
                       Text('ECO QUEST', style: TextStyle(color: Color(0xFF0a2540), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0)),
                     ],
                  )
                )
              ],
            ),
          ),

          // Main Form Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 100.0, bottom: 48.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Titles
                    const Text(
                      'Join Eco Quest',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0a2540), // navy
                        letterSpacing: -1.0,
                        shadows: [Shadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start your sustainable journey today.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xCC0a2540), // navy/80
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Forms
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 384),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // First / Last Name Row
                          Row(
                            children: [
                              Expanded(child: _buildInputLabel('First Name', 'John', _firstNameController, null)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildInputLabel('Last Name', 'Doe', _lastNameController, null)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          _buildInputLabel('Username', '@nature_lover', _usernameController, Icons.person),
                          const SizedBox(height: 16),
                          _buildInputLabel('Email Address', 'your@email.com', _emailController, Icons.mail, keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 16),
                          
                          // Password
                          _buildPasswordLabel(),

                          const SizedBox(height: 32),

                          // Signup Button
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0d93f2), // primary
                                foregroundColor: Colors.white,
                                elevation: 8,
                                shadowColor: const Color(0x4D0d93f2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                              ),
                              child: _isLoading 
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('CREATE ACCOUNT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Login Link
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Already have an account?',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xB30a2540)), // navy/70
                                ),
                                TextButton(
                                  onPressed: () {
                                     Navigator.pop(context);
                                  },
                                  style: TextButton.styleFrom(
                                     padding: const EdgeInsets.symmetric(horizontal: 8),
                                     minimumSize: Size.zero,
                                     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('LOG IN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0d93f2))),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label, String hint, TextEditingController controller, IconData? icon, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(color: Color(0xCC0a2540), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
        ),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.45), // frosted-glass-item
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0a2540)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0x4D0a2540)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(left: icon != null ? 48 : 20, right: 16, top: 18, bottom: 18),
              prefixIcon: icon != null ? Icon(icon, color: const Color(0x660a2540), size: 20) : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordLabel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 6.0),
          child: Text(
            'PASSWORD',
            style: TextStyle(color: Color(0xCC0a2540), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
        ),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0a2540)),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: const TextStyle(color: Color(0x4D0a2540)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(left: 48, right: 48, top: 18, bottom: 18),
              prefixIcon: const Icon(Icons.lock, color: Color(0x660a2540), size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0x660a2540),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
