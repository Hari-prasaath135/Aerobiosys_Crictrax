import 'package:TURF_TOWN_/src/Menus/privacy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:TURF_TOWN_/src/Menus/account.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      ),
    );
  }

  // Minimalist setting item
  Widget _buildSettingItem({
    required Widget icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLogout 
              ? Colors.red.withOpacity(0.3) 
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: isLogout 
              ? Colors.red.withOpacity(0.1) 
              : Colors.white.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isLogout 
                        ? Colors.red.withOpacity(0.15) 
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: icon),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isLogout ? Colors.red[400] : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isLogout 
                      ? Colors.red.withOpacity(0.5) 
                      : Colors.white.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Minimalist section divider
  Widget _buildSectionDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Divider(
        color: Colors.white.withOpacity(0.15),
        height: 1,
        thickness: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF140088), // deep purple
              Color(0xFF000000), // black
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: Column(
          children: [
            // Minimalist Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Settings icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2962FF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SvgPicture.asset(
                      'assets/images/Group.svg',
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF5E92F3),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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

            const SizedBox(height: 8),

            // Settings List
            Expanded(
              child: Builder(
                builder: (BuildContext builderContext) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildSettingItem(
                          title: 'Privacy',
                          icon: SvgPicture.asset(
                            'assets/images/Vector.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              Colors.white70,
                              BlendMode.srcIn,
                            ),
                            fit: BoxFit.contain,
                          ),
                          onTap: () {
                            Navigator.push(
                              builderContext,
                              MaterialPageRoute(builder: (context) => const PrivacyScreen()),
                            );
                          },
                        ),
                        _buildSettingItem(
                          title: 'Account',
                          icon: SvgPicture.asset(
                            'assets/images/filled.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              Colors.white70,
                              BlendMode.srcIn,
                            ),
                            fit: BoxFit.contain,
                          ),
                          onTap: () {
                            Navigator.push(
                              builderContext,
                              MaterialPageRoute(builder: (context) => const ProfileScreen()),
                            );
                          },
                        ),
                        _buildSectionDivider(),
                        _buildSettingItem(
                          title: 'Previous Bookings',
                          icon: SvgPicture.asset(
                            'assets/images/book.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              Colors.white70,
                              BlendMode.srcIn,
                            ),
                            fit: BoxFit.contain,
                          ),
                          onTap: () {
                            _showToast(builderContext, 'Previous Bookings Tapped');
                          },
                        ),
                        _buildSettingItem(
                          title: 'Payments',
                          icon: SvgPicture.asset(
                            'assets/images/fluent.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              Colors.white70,
                              BlendMode.srcIn,
                            ),
                            fit: BoxFit.contain,
                          ),
                          onTap: () {
                            _showToast(builderContext, 'Payments Tapped');
                          },
                        ),
                        _buildSettingItem(
                          title: 'Support',
                          icon: SvgPicture.asset(
                            'assets/images/Vec.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              Colors.white70,
                              BlendMode.srcIn,
                            ),
                            fit: BoxFit.contain,
                          ),
                          onTap: () {
                            _showToast(builderContext, 'Support Tapped');
                          },
                        ),
                        _buildSectionDivider(),
                        _buildSettingItem(
                          title: 'Terms & Conditions',
                          icon: SvgPicture.asset(
                            'assets/images/spanner.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              Colors.white70,
                              BlendMode.srcIn,
                            ),
                            fit: BoxFit.contain,
                          ),
                          onTap: () {
                            _showToast(builderContext, 'Terms & Conditions Tapped');
                          },
                        ),
                        _buildSettingItem(
                          title: 'Logout',
                          isLogout: true,
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Colors.white70,
                            size: 18,
                          ),
                          onTap: () {
                            _showToast(builderContext, 'Logout Tapped');
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}