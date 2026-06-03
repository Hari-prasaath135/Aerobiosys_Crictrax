// Added these imports for location

import 'package:TURF_TOWN_/src/Pages/Teams/Tournament/tournament_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/TeamPage.dart' show TeamPage;
import 'package:TURF_TOWN_/src/Screens/privacy.dart';
import 'package:TURF_TOWN_/src/views/Venue.dart';
import 'package:flutter/material.dart';
import 'package:TURF_TOWN_/src/CommonParameters/AppBackGround1/Appbg1.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:TURF_TOWN_/src/Scorecard/ScoreCard.dart';
import 'package:TURF_TOWN_/src/services/permission_service.dart';
import 'package:TURF_TOWN_/src/models/ScoreController.dart';
import 'package:TURF_TOWN_/src/widgets/Navigation_bar.dart';
import 'package:TURF_TOWN_/src/Screens/setting.dart';
import 'package:TURF_TOWN_/src/Screens/account.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/InitialTeamPage.dart';
import 'package:TURF_TOWN_/src/views/alerts_page.dart';
import 'package:TURF_TOWN_/src/views/bluetooth_page.dart';
import 'package:TURF_TOWN_/src/views/history_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:TURF_TOWN_/src/models/team.dart';
import 'package:TURF_TOWN_/src/models/team_member.dart';
import 'package:TURF_TOWN_/src/models/match_history.dart';
import 'package:TURF_TOWN_/src/models/match.dart';
import 'package:TURF_TOWN_/src/models/innings.dart';
import 'package:TURF_TOWN_/src/models/score.dart';
import 'package:TURF_TOWN_/src/models/batsman.dart';
import 'package:TURF_TOWN_/src/models/bowler.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {
  int _selectedIndex = 2;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      CricketScorerHeader(),  // Index 0 - Venue page
      const HistoryPage(),    // Index 1 - History page
      const HomeContent(),    // Index 2 - Home page (default/center)
      const TournamentPage(), // Index 3 - Tournaments
      const AlertsPage(),     // Index 4 - Alerts page
    ];
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Step 1: Load teams from /users/{uid}/teams
    await Team.loadFromFirestore(user.uid);

    // Step 2: Load members from /users/{uid}/teams/{teamId}/members
    for (final team in Team.getAll()) {
      await TeamMember.loadFromFirestore(team.teamId, uid: user.uid);
    }

    // Step 3: Load match history from /matchHistories filtered by createdBy == uid
    await MatchHistory.loadFromFirestore(userId: user.uid);

    // Step 4: For any paused/in-progress match, reload live data using nested paths
    for (final h in MatchHistory.getAll()) {
      if (h.isPaused || h.isOnProgress) {
        final tournamentId = h.tournamentId;

        // Load match from /tournaments/{tournamentId}/matches/{matchId}
        await Match.loadFromFirestore(h.matchId, tournamentId: tournamentId);

        // Load innings from /tournaments/{tournamentId}/matches/{matchId}/innings
        await Innings.loadFromFirestore(h.matchId, tournamentId: tournamentId);

        for (final innings in Innings.getByMatchId(h.matchId)) {
          final iId = innings.inningsId;

          // Load score from …/innings/{iId}/scores
          await Score.loadFromFirestore(
            iId,
            tournamentId: tournamentId,
            matchId: h.matchId,
          );

          // Load bowlers from …/innings/{iId}/bowlers
          await Bowler.loadFromFirestore(
            iId,
            tournamentId: tournamentId,
            matchId: h.matchId,
          );

          // Load batsmen from …/innings/{iId}/batsmen
          await Batsman.loadFromFirestore(
            iId,
            tournamentId: tournamentId,
            matchId: h.matchId,
          );
        }
      }
    }

    if (mounted) setState(() {});
  }

  void _handleNavTap(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: Navigation_bar(
        currentIndex: _selectedIndex,
        onTap: _handleNavTap,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
    );
  }
}

//
// ── NavAvatar widget ───────────────────────────────────────────
//
class NavAvatar extends StatelessWidget {
  final double radius;
  const NavAvatar({super.key, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String? photoUrl = user?.photoURL;
    final String displayName =
        (user?.displayName?.isNotEmpty == true) ? user!.displayName! : 'U';

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF5C6BC0),
      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
      child: photoUrl == null
          ? Text(
              displayName[0].toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.85,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}

//
// --- HomeContent Widget ---
//
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String _currentLocationName = "Loading...";

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
     // ── Ask location permission when Home loads ──────────────────
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (mounted) {
      await PermissionService.instance.requestLocationPermission(context);
      // Re-fetch location after permission is granted
      _getCurrentLocation();
    }});
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _currentLocationName = "Enable GPS");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _currentLocationName = "Grant Permission");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _currentLocationName = "Permission Denied");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String name = place.subLocality ?? place.locality ?? "Unknown Location";

        if (name.length > 15) {
          name = "${name.substring(0, 15)}...";
        }

        setState(() {
          _currentLocationName = name;
        });
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
      setState(() => _currentLocationName = "Error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(gradient: Appbg1.mainGradient),
        ),
        Positioned.fill(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(height: 900),

                  /// Location and Icons Row
                  Positioned(
                    top: 50,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on,
                                color: Colors.white, size: 24),
                            const SizedBox(width: 5),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Your Location",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  _currentLocationName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProfileScreen(),
                                  ),
                                );
                              },
                              child: const NavAvatar(radius: 18),
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings,
                                  color: Colors.white),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SettingsScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

             

               /// Sports Slider
Positioned(
  top: 220,  // Changed from 200
  left: 20,
  right: 20,
  height: 160,
  child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
                         InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const InitialTeamPage(), // ← FIXED
                                  ),
                                );
                              },
                            borderRadius: BorderRadius.circular(15.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15.0),
                              child: Image.asset(
                                'assets/images/cri_slider.png',
                                width: 140,
                                height: 160,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(15.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15.0),
                              child: Image.asset(
                                'assets/images/foot_slider.png',
                                width: 140,
                                height: 160,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(15.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15.0),
                              child: Image.asset(
                                'assets/images/badminton_slider.png',
                                width: 140,
                                height: 160,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                 
           
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}