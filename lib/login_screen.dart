import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'signup_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.loginWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
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
      backgroundColor: const Color(0xFFE0F2FE), // sky-50 equivalent
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCjoKWbtTwtflsV4BCtB-Xrxz94sQ5kogEuTgcAcoeyGPi1SStXiSw8mSTPI6VIjlLgtWhE604rj58F1jMRVJ6dew-13kPXxk-V2sy2k9bIJcc-hykIfaWScZTFFyVYBHp49NUQosocafkWaxjpArLi_TYfuBjOd6Ji0SeqaGBSjOQJcOp4k55iubt5h9MUbYpb5qg9mo1e39f8jB6TWMH-0_eZ7fv8WBLDZcRy2BMTPimAVpURCrTnD3iGsUlsz9H2D7LN8-LOPhQ',
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
                    const Color(0xFF38BDF8).withOpacity(0.3), // sky-400
                    Colors.transparent,
                    const Color(0xFFFED7AA).withOpacity(0.4), // orange-200
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.2)),
          ),

          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header Section
                    const SizedBox(height: 120),
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.4)),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
                      ),
                      child: const Center(
                        child: Icon(Icons.eco, color: Color(0xFF0077ff), size: 48), // ocean-blue
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Eco Quest',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0d161c), // navy-deep
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'JOIN THE MISSION',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0x990d161c), // navy-deep/60
                        letterSpacing: 2.8, // 0.2em roughly
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Forms
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 384),
                      child: Column(
                        children: [
                          // Email Input
                          Container(
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF0d161c)),
                              decoration: const InputDecoration(
                                hintText: 'Email Address',
                                hintStyle: TextStyle(color: Color(0x660d161c)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Password Input
                          Container(
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF0d161c)),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: const TextStyle(color: Color(0x660d161c)),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                    color: const Color(0x660d161c),
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
                          
                          // Forgot Password
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0x800d161c),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 64,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0077ff), // ocean-blue
                                foregroundColor: Colors.white,
                                elevation: 8,
                                shadowColor: const Color(0x4D0077ff),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                              ),
                              child: _isLoading 
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('LOGIN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Create Account Button
                          SizedBox(
                            width: double.infinity,
                            height: 64,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.6), // frosted-glass-button
                                foregroundColor: const Color(0xFF0d161c),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                  side: BorderSide(color: Colors.white.withOpacity(0.4)),
                                ),
                              ),
                              child: const Text('CREATE AN ACCOUNT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 120), // Spacing for bottom icons
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom Decor Icons
          Positioned(
            bottom: 48,
            left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDecoIcon(Icons.water_drop),
                const SizedBox(width: 32),
                _buildDecoIcon(Icons.sunny),
                const SizedBox(width: 32),
                _buildDecoIcon(Icons.forest),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecoIcon(IconData icon) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Center(
        child: Icon(icon, color: const Color(0x990d161c), size: 20),
      ),
    );
  }
}
