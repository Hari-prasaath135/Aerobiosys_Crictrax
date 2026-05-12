import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:TURF_TOWN_/src/Menus/account.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // --- NEW HELPER METHOD ---
  // Reusable method to show a SnackBar (Flutter's version of a Toast)
  void _showToast(BuildContext context, String message) {
    // Hide any snackbar that might already be showing
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Show the new snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey[800], // Dark background
        behavior: SnackBarBehavior.floating, // "Floats" above content
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      ),
    );
  }

  // Reusable widget for each setting item
  Widget _buildSettingItem({
    required Widget icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Center(
                child: icon,
              ),
            ),
            const SizedBox(width: 18),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable divider
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        height: 1.5,
        color: Colors.white.withOpacity(0.25),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Gradient Header
          Container(
            width: double.infinity,
            height: 140,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF283593),
                  Color(0xFF1A237E),
                  Color(0xFF000000),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.4, 1.0],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            padding:
            const EdgeInsets.only(top: 40, left: 24, right: 24, bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  'assets/Group.svg',
                  width: 26,
                  height: 26,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 15),
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 7),

          // Settings List
          Expanded(
            // --- CHANGED: Added Builder ---
            // We use a Builder to get a context that is *under* the Scaffold.
            // This is required for ScaffoldMessenger.of(context) to work.
            child: Builder(
              builder: (BuildContext builderContext) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSettingItem(
                        title: 'Privacy',
                        icon: SvgPicture.asset(
                          'assets/Vector.svg',
                          width: 17,
                          height: 17,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          fit: BoxFit.contain,
                        ),
                        // --- CHANGED: Calls _showToast ---
                        onTap: () {
                          _showToast(builderContext, 'Privacy Tapped');
                        },
                      ),
                      _buildSettingItem(
                        title: 'Account',
                        icon: SvgPicture.asset(
                          'assets/filled.svg',
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          fit: BoxFit.contain,
                        ),
                        // 2. CHANGE THE onTap ACTION
                        onTap: () {
                          // FROM: _showToast(builderContext, 'Account Tapped');
                          // TO:
                          Navigator.push(
                            builderContext,
                            MaterialPageRoute(builder: (context) => const ProfileScreen()),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildSettingItem(
                        title: 'Previous Bookings',
                        icon: SvgPicture.asset(
                          'assets/book.svg',
                          width: 22,
                          height: 22,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          fit: BoxFit.contain,
                        ),
                        // --- CHANGED: Calls _showToast ---
                        onTap: () {
                          _showToast(builderContext, 'Previous Bookings Tapped');
                        },
                      ),
                      _buildSettingItem(
                        title: 'Payments',
                        icon: SvgPicture.asset(
                          'assets/fluent.svg',
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          fit: BoxFit.contain,
                        ),
                        // --- CHANGED: Calls _showToast ---
                        onTap: () {
                          _showToast(builderContext, 'Payments Tapped');
                        },
                      ),
                      _buildSettingItem(
                        title: 'Support',
                        icon: SvgPicture.asset(
                          'assets/Vec.svg',
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          fit: BoxFit.contain,
                        ),
                        // --- CHANGED: Calls _showToast ---
                        onTap: () {
                          _showToast(builderContext, 'Support Tapped');
                        },
                      ),
                      _buildDivider(),
                      _buildSettingItem(
                        title: 'Terms & Conditions',
                        icon: SvgPicture.asset(
                          'assets/spanner.svg',
                          width: 19,
                          height: 19,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          fit: BoxFit.contain,
                        ),
                        // --- CHANGED: Calls _showToast ---
                        onTap: () {
                          _showToast(builderContext, 'Terms & Conditions Tapped');
                        },
                      ),
                      _buildSettingItem(
                        title: 'Logout',
                        icon: Image.asset(
                          'assets/logout.png',
                          color: Colors.white,
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                        ),
                        // --- CHANGED: Calls _showToast ---
                        onTap: () {
                          _showToast(builderContext, 'Logout Tapped');
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}