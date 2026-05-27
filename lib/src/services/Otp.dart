import 'package:flutter/material.dart';
import 'package:TURF_TOWN_/src/Services/auth_service.dart';

class OtpVerification extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final VoidCallback onVerified; // ← ADDED

  const OtpVerification({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    required this.onVerified, // ← ADDED
  });

  @override
  State<OtpVerification> createState() => _OtpVerificationState();
}

class _OtpVerificationState extends State<OtpVerification> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _authService = AuthService();
  bool _isLoading = false;

  void _verify() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter all 6 digits')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = await _authService.verifyOtp(widget.verificationId, otp);
    setState(() => _isLoading = false);

    if (user != null && mounted) {
      widget.onVerified(); // ← triggers LoadingScreen → Home flow
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter OTP',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Sent to +91 ${widget.phoneNumber}',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 40),

            // 6-box OTP row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) {
                return SizedBox(
                  width: 45,
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty && i < 5) {
                        _focusNodes[i + 1].requestFocus();
                      } else if (val.isEmpty && i > 0) {
                        _focusNodes[i - 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),

            // Verify button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verify,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF0094FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'VERIFY & LOGIN',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }
}