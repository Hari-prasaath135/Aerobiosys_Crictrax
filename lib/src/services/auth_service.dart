import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
      await _saveUserToFirestore(result.user); // ← now safely wrapped
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('OTP verification error: $e');
      return null;
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result =
          await _auth.signInWithCredential(credential);

      // FIX: user is now signed in before we touch Firestore,
      // so request.auth.uid will match the document uid.
      await _saveUserToFirestore(result.user);
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Google Sign-In FirebaseAuth error: $e');
      return null;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return null;
    }
  }

  // ── Save to Firestore /users/{uid} ─────────────────────────
  // FIX: wrapped entirely in try/catch so a permission error
  // doesn't bubble up and break the sign-in return value.
  Future<void> _saveUserToFirestore(User? user) async {
    if (user == null) return;
    try {
      final ref = _db.collection('users').doc(user.uid);
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          'uid': user.uid,
          'displayName': user.displayName ?? '',
          'email': user.email ?? '',
          'phone': user.phoneNumber ?? '',
          'photoUrl': user.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseException catch (e) {
      // Log but don't rethrow — sign-in still succeeds even if
      // Firestore write fails (e.g. permission-denied).
      debugPrint('Firestore save error [${e.code}]: ${e.message}');
    } catch (e) {
      debugPrint('Firestore unexpected error: $e');
    }
  }

  // ── Sign Out ───────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google sign-out error: $e');
    } finally {
      await _auth.signOut();
    }
  }
}