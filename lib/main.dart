import 'package:TURF_TOWN_/src/services/bluetooth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:TURF_TOWN_/src/models/objectbox_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:TURF_TOWN_/src/views/splash_screen_new.dart'; // ← fixed

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ObjectBoxHelper.init();
  await Firebase.initializeApp();
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
      home: const SplashScreenNew(), // ← fixed
    );
  }
}