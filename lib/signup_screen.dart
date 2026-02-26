import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'home_screen.dart';

const Color colorNavy = Color(0xFF0a2540);
const Color colorOceanBlue = Color(0xFF0077FF);

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
  final _mobileController = TextEditingController();
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
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final mobile = _mobileController.text.trim();
    final password = _passwordController.text;

    if (firstName.isEmpty || lastName.isEmpty || username.isEmpty || email.isEmpty || mobile.isEmpty || password.isEmpty) {
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
        mobile: mobile,
        password: password,
      );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (Route<dynamic> route) => false,
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuC3d8huYBXMDLUbFtGKAEvtWpw0NB-Gz6TiUNQRmnB2Wvv6kjNpnWdQtJhTDPyzdyPaFhaghXqCnHEKuLWjswfXlLxRg1p4sU01c1tYoZyWFsmHxE0701vaJcRk0CCIBGegJaAUrErlKFtI2WtfsMT2tI-ok1EDI0jwB4gGfHryrV462MzWo2PvD-60LPwxdBmS_07DJFvya2YTgnoyz_p2pgL-_tA6irnpmkuLQBw8DKZ_g6lD0WTc7sVyzk4k807MTdus5V4fB7k',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none, // "pixel-bg" effect
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.4)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, color: colorNavy, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white.withOpacity(0.4)),
                        ),
                        child: Row(
                           mainAxisSize: MainAxisSize.min,
                           children: const [
                             Icon(Icons.waves, color: colorNavy, size: 18),
                             SizedBox(width: 8),
                             Text('ECO QUEST', style: TextStyle(color: colorNavy, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0)),
                           ],
                        )
                      )
                    ],
                  ),
                ),

                // Main Form Area
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 48.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Join Eco Quest',
                            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: colorNavy, letterSpacing: -1.0),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start your sustainable journey today.',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorNavy.withOpacity(0.9)),
                          ),
                          const SizedBox(height: 32),

                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 384),
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                Row(
                                  children: [
                                    Expanded(child: _buildInputLabelless('First Name', 'John', _firstNameController, null)),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildInputLabelless('Last Name', 'Doe', _lastNameController, null)),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _buildInputLabelless('Unique Handle', 'nature_lover', _usernameController, Icons.alternate_email),
                                const SizedBox(height: 14),
                                _buildInputLabelless('Email Address', 'your@email.com', _emailController, Icons.mail, keyboardType: TextInputType.emailAddress),
                                const SizedBox(height: 14),
                                _buildInputLabelless('Mobile Number', '+1 (555) 000-0000', _mobileController, Icons.smartphone, keyboardType: TextInputType.phone),
                                const SizedBox(height: 14),
                                _buildPasswordLabelless(),
                                
                                const SizedBox(height: 24),

                                SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _signup,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorOceanBlue,
                                      foregroundColor: Colors.white,
                                      elevation: 8,
                                      shadowColor: colorOceanBlue.withOpacity(0.3),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                                    ),
                                    child: _isLoading 
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Text('CREATE ACCOUNT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('Already have an account?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorNavy)),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('LOG IN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: colorNavy, decoration: TextDecoration.underline)),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabelless(String label, String hint, TextEditingController controller, IconData? icon, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
          child: Text(label.toUpperCase(), style: const TextStyle(color: colorNavy, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorNavy.withOpacity(0.2)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorNavy),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: colorNavy.withOpacity(0.5)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(left: icon != null ? 48 : 16, right: 16, top: 14, bottom: 14),
              prefixIcon: icon != null ? Icon(icon, color: colorNavy.withOpacity(0.7), size: 20) : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordLabelless() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 4.0),
          child: Text('PASSWORD', style: TextStyle(color: colorNavy, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorNavy.withOpacity(0.2)),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorNavy),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: TextStyle(color: colorNavy.withOpacity(0.5)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(left: 48, right: 48, top: 14, bottom: 14),
              prefixIcon: Icon(Icons.lock, color: colorNavy.withOpacity(0.7), size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: colorNavy.withOpacity(0.5), size: 20),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
