import 'package:TURF_TOWN_/src/Services/bluetooth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:TURF_TOWN_/src/views/splash_screen_new.dart';
import 'package:TURF_TOWN_/src/models/db_helper.dart';
import 'package:TURF_TOWN_/src/models/match_history.dart';
import 'package:TURF_TOWN_/src/models/team_member.dart';
import 'package:TURF_TOWN_/src/services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBHelper.instance.warmUp();
  await Firebase.initializeApp();

  // ✅ Load match history + teams into memory cache on login
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (user != null) {
      try {
        await MatchHistory.loadFromFirestore(userId: user.uid);
        debugPrint('✅ MatchHistory loaded for uid: ${user.uid}');
      } catch (e) {
        debugPrint('⚠️ MatchHistory load failed: $e');
      }

      try {
        final teams = await FirestoreService.instance.getMyTeams();
        for (final team in teams) {
          await TeamMember.loadFromFirestore(team.teamId);
        }
        debugPrint('✅ Teams + players loaded: ${teams.length} teams');
      } catch (e) {
        debugPrint('⚠️ Teams/players load failed: $e');
      }
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('📱 App resumed - Bluetooth stays connected');
        break;
      case AppLifecycleState.paused:
        debugPrint('📱 App paused - Bluetooth stays connected');
        break;
      case AppLifecycleState.detached:
        debugPrint('📱 App detached - Disconnecting Bluetooth');
        BleManagerService().disconnect();
        break;
      case AppLifecycleState.inactive:
        debugPrint('📱 App inactive - Bluetooth stays connected');
        break;
      case AppLifecycleState.hidden:
        debugPrint('📱 App hidden - Bluetooth stays connected');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const SplashScreenNew(),
    );
  }
}