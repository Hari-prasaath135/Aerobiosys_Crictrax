import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class PermissionService {
  static final PermissionService instance = PermissionService._();
  PermissionService._();

  // ✅ Same channel name as MainActivity.kt
  static const _channel = MethodChannel('com.example.features/location');

  Future<void> requestLocationPermission(BuildContext context) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('📍 Location service enabled: $serviceEnabled');

      if (!serviceEnabled) {
        // ✅ Triggers the inline Google system dialog — no app switch needed
        await _channel.invokeMethod('requestLocationEnable');

        // Wait a moment for user to respond
        await Future.delayed(const Duration(seconds: 1));

        // Check again after dialog
        final nowEnabled = await Geolocator.isLocationServiceEnabled();
        if (!nowEnabled) return; // user denied
      }

      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('📍 Permission status: $permission');

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) return;

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Row(children: [
                Icon(Icons.location_disabled, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('Permission Denied'),
              ]),
              content: const Text(
                  'Please enable location from App Settings.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Geolocator.openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Trigger system permission popup
      final result = await Geolocator.requestPermission();
      debugPrint('📍 Permission result: $result');

    } catch (e) {
      debugPrint('⚠️ Permission error: $e');
    }
  }
}