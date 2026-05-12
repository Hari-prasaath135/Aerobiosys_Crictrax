import 'package:TURF_TOWN_/src/Screens/Phone_no.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:TURF_TOWN_/src/services/auth_service.dart';
import 'package:TURF_TOWN_/src/Screens/setting.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Derive display values
    final String displayName =
        (user?.displayName?.isNotEmpty == true) ? user!.displayName! : 'Cricket Fan';
    final String handle =
        user?.email?.isNotEmpty == true ? '@${user!.email!.split('@').first}' : '@player';
    final String? photoUrl = user?.photoURL;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                height: 140,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF283593), Color(0xFF1A237E), Color(0xFF000000)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.4, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Profile",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500),
                        ),
                        Row(
                          children: [
                            // Sign Out button
                            IconButton(
                              icon: const Icon(Icons.logout, color: Colors.white),
                              onPressed: () async {
                                await AuthService().signOut();
                                if (context.mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const PhoneNumberPage()),
                                    (_) => false,
                                  );
                                }
                              },
                            ),
                            SvgPicture.asset(
                              'assets/images/supporthead.svg',
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                  Colors.white, BlendMode.srcIn),
                              placeholderBuilder: (_) => const Icon(
                                  Icons.headphones,
                                  color: Colors.white,
                                  size: 24),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          Positioned(
            top: 85,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Avatar — show Google photo if available, else initials
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF5C5C5C),
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(
                          displayName[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                ),

                const SizedBox(height: 14),

                // Share + Edit Profile Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.asset(
                        'assets/images/share.svg',
                        width: 15,
                        height: 15,
                        colorFilter: const ColorFilter.mode(
                            Colors.white, BlendMode.srcIn),
                        placeholderBuilder: (_) => const Icon(
                            Icons.ios_share,
                            color: Colors.white,
                            size: 15),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        "Edit Profile",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Real name from Firebase
                Text(
                  displayName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 4),

                // Handle
                Text(
                  handle,
                  style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                ),

                const SizedBox(height: 8),

                // Phone number if signed in via phone
                if (user?.phoneNumber != null)
                  Text(
                    user!.phoneNumber!,
                    style: const TextStyle(
                        color: Color(0xFF9E9E9E), fontSize: 13),
                  ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text("0 Followers",
                        style:
                            TextStyle(color: Colors.white70, fontSize: 13)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text("·",
                          style: TextStyle(
                              color: Colors.white38, fontSize: 16)),
                    ),
                    Text("0 Following",
                        style:
                            TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}