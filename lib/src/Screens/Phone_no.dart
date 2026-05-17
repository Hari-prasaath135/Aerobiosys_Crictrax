import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:TURF_TOWN_/src/CommonParameters/AppBackGround1/Appbg1.dart';
import 'package:TURF_TOWN_/src/services/auth_service.dart';
import 'package:TURF_TOWN_/src/services/Otp.dart';
import 'package:TURF_TOWN_/src/views/Home.dart';
import 'package:TURF_TOWN_/src/Screens/loading_screen.dart';

class PhoneNumberPage extends StatefulWidget {
  const PhoneNumberPage({super.key});

  @override
  State<PhoneNumberPage> createState() => _PhoneNumberPageState();
}

class _PhoneNumberPageState extends State<PhoneNumberPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  bool _isAgreed = false;
  bool _isLoading = false;

  // ── Shared: show loading screen then go to Home ────────────
  void _goToLoadingThenHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => LoadingScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const Home(),
            transitionDuration: const Duration(milliseconds: 500),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    });
  }

  // ── Send OTP ───────────────────────────────────────────────
  void _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 10-digit number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    await _authService.sendOtp(
      phoneNumber: phone,
      onAutoVerified: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        setState(() => _isLoading = false);
        if (mounted) _goToLoadingThenHome();
      },
      onCodeSent: (verId, _) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerification(
              phoneNumber: phone,
              verificationId: verId,
              onVerified: _goToLoadingThenHome, // ← pass callback to OTP screen
            ),
          ),
        );
      },
      onFailed: (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'OTP failed')),
        );
      },
    );
  }

  // ── Google Sign-In ─────────────────────────────────────────
  void _signInWithGoogle() async {
    setState(() => _isLoading = true);
    final user = await _authService.signInWithGoogle();
    setState(() => _isLoading = false);

    if (user != null && mounted) {
      _goToLoadingThenHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(gradient: Appbg1.mainGradient),
          ),

          Positioned(
            top: 230,
            left: 100,
            child: const Text(
              'Enter your Phone \nNumber',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Phone input
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Form(
                key: _formKey,
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    labelText: 'Phone Number',
                    prefixText: '+91 ',
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFFC6C3C3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // OR divider + Google button
          Positioned(
            bottom: 230,
            left: 50,
            right: 50,
            child: Column(
              children: [
                const Row(children: [
                  Expanded(child: Divider(color: Colors.white38)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('OR', style: TextStyle(color: Colors.white54)),
                  ),
                  Expanded(child: Divider(color: Colors.white38)),
                ]),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _isLoading ? null : _signInWithGoogle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/google_icon.png',
                          height: 20,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.g_mobiledata, size: 24),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Continue with Google',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Terms checkbox
          Positioned(
            bottom: 140,
            left: 30,
            right: 30,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    value: _isAgreed,
                    onChanged: (val) =>
                        setState(() => _isAgreed = val ?? false),
                    activeColor: Colors.white,
                    checkColor: const Color(0xFF0094FF),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'By entering your number, you\'re agreeing to our Terms of service & Privacy Policy',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Arrow / Send OTP button
          Positioned(
            bottom: 55,
            right: 16,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _isAgreed
                          ? LinearGradient(
                              colors: [
                                const Color(0xFF00C4FF).withOpacity(0.3),
                                const Color(0xFF0094FF).withOpacity(0.4),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color:
                          _isAgreed ? null : Colors.grey.withOpacity(0.3),
                      boxShadow: _isAgreed
                          ? [
                              BoxShadow(
                                color:
                                    const Color(0xFF00C4FF).withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isAgreed ? _sendOtp : null,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.arrow_forward,
                            color: _isAgreed ? Colors.white : Colors.white54,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}