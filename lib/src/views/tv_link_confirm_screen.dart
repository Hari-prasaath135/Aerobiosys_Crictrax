import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TvLinkConfirmScreen extends StatefulWidget {
  final String sessionId;
  const TvLinkConfirmScreen({super.key, required this.sessionId});

  @override
  State<TvLinkConfirmScreen> createState() => _TvLinkConfirmScreenState();
}

class _TvLinkConfirmScreenState extends State<TvLinkConfirmScreen> {
  bool _linking = false;
  bool _linked = false; // NEW
  String? _error;
// Call this when QR session is confirmed/linked
Future<void> _registerTvSession(String sessionId) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  await FirebaseFirestore.instance
      .collection('tv_sessions')
      .doc(sessionId)
      .set({
    'ownerUid': uid,
    'sessionId': sessionId,
    'deviceName': 'TV Screen',   // or detect from device info
    'deviceType': 'tv',
    'connectedAt': FieldValue.serverTimestamp(),
    'loggedOut': false,
    'loggedOutAt': null,
    'loggedOutBy': null,
  }, SetOptions(merge: true));
}

Future<void> _confirmLink() async {
  if (_linking) return; // prevent double-tap re-entry

  setState(() {
    _linking = true;
    _error = null;
  });

  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');

    final sessionRef = FirebaseFirestore.instance
        .collection('tv_sessions')
        .doc(widget.sessionId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snap = await transaction.get(sessionRef);
      if (!snap.exists) throw Exception('Session not found');

      final data = snap.data()!;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();

      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception('QR code has expired. Please scan again.');
      }
      if (data['status'] != 'pending') {
        throw Exception('Session already used.');
      }

      transaction.update(sessionRef, {
        'status': 'linked',
        'userId': user.uid,
        'displayName': user.displayName ?? '',
        'email': user.email ?? '',
        'linkedAt': FieldValue.serverTimestamp(),
      });
   });

    await _registerTvSession(widget.sessionId);

    if (!mounted) return;
    setState(() {
      _linking = false;
      _linked = true;
    });

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('TV linked successfully!',
            style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: Color(0xFF00E676),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _error = e.toString().replaceFirst('Exception: ', '');
      _linking = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B3E),
        title: const Text('Link TV',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600)),
        leading: const BackButton(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF141928),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: const Color(0xFF00C4FF).withOpacity(0.25), width: 1),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C4FF).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF00C4FF).withOpacity(0.3),
                          width: 1.5),
                    ),
                    child: const Icon(Icons.tv_rounded,
                        size: 52, color: Color(0xFF00C4FF)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Link your account\nto this TV?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You will be logged in on the TV screen\nwith your Turf Town account.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontFamily: 'Poppins',
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.red.withOpacity(0.3), width: 1),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontFamily: 'Poppins',
                            fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  switchInCurve: Curves.easeOut,
  switchOutCurve: Curves.easeIn,
  transitionBuilder: (child, animation) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: animation,
        axisAlignment: 0.0,
        child: child,
      ),
    );
  },
  child: _linked
      ? Column(
          key: const ValueKey('linked'),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Color(0xFF00E676), size: 36),
            ),
            const SizedBox(height: 12),
            const Text(
              'TV Linked!',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        )
      : _linking
          ? const CircularProgressIndicator(
              key: ValueKey('loading'),
              color: Color(0xFF00C4FF),
              strokeWidth: 2.5)
          : Column(
              key: const ValueKey('buttons'),
              children: [
                GestureDetector(
                  onTap: _confirmLink,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFF00C4FF),
                        Color(0xFF0066CC),
                      ]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00C4FF).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.link_rounded,
                            color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Yes, Link TV',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.1), width: 1),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white60,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
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