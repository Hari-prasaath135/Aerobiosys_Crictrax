import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ── Phone OTP ──────────────────────────────────────────────
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) onAutoVerified,
    required void Function(String verId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException e) onFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: '+91$phoneNumber',
      timeout: const Duration(seconds: 60),
      verificationCompleted: onAutoVerified,
      verificationFailed: onFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<User?> verifyOtp(String verificationId, String otp) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      final result = await _auth.signInWithCredential(credential);
      await _saveUserToFirestore(result.user);
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('OTP verification error: $e');
      return null;
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────
  Future<User?> signInWithGoogle() async {
    try {
      // Clear stale cached session — prevents ApiException:10
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google Sign-In cancelled by user');
        return null;
      }

      if (googleUser.email.isEmpty) {
        debugPrint('Google Sign-In error: account has no email');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result =
          await _auth.signInWithCredential(credential);

      debugPrint('✅ Google Sign-In success: ${result.user?.email}');
      await _saveUserToFirestore(result.user);
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Google Sign-In FirebaseAuth error [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return null;
    }
  }

  // ── Save / merge user to Firestore /users/{uid} ────────────
  Future<void> _saveUserToFirestore(User? user) async {
    if (user == null) return;
    try {
      final ref = _db.collection('users').doc(user.uid);

      // Update all login fields every time
      await ref.set(
        {
          'uid': user.uid,
          'displayName': user.displayName ?? '',
          'email': user.email ?? '',
          'phone': user.phoneNumber ?? '',
          'photoUrl': user.photoURL ?? '',
          'emailVerified': user.emailVerified,
          'lastLoginAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Only write createdAt once (on first login)
      final snapshot = await ref.get();
      if (snapshot.data()?['createdAt'] == null) {
        await ref.update({'createdAt': FieldValue.serverTimestamp()});
      }

      debugPrint('✅ Firestore profile saved: ${user.email}');
    } on FirebaseException catch (e) {
      debugPrint('Firestore save error [${e.code}]: ${e.message}');
    } catch (e) {
      debugPrint('Firestore unexpected error: $e');
    }
  }

  // ── Get user profile from Firestore ───────────────────────
  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  // ── Sign Out ───────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('Google disconnect error (safe to ignore): $e');
    } finally {
      await _auth.signOut();
    }
  }

  // ── Helper: is the current user email-verified? ────────────
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }
}