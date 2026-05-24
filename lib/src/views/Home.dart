// Added these imports for location
import 'package:TURF_TOWN_/src/Pages/Teams/tournament_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/TeamPage.dart' show TeamPage;
import 'package:TURF_TOWN_/src/Screens/privacy.dart';
import 'package:TURF_TOWN_/src/views/Venue.dart';
import 'package:flutter/material.dart';
import 'package:TURF_TOWN_/src/CommonParameters/AppBackGround1/Appbg1.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:TURF_TOWN_/src/Scorecard/ScoreCard.dart';
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

    // Step 1: Load teams and their players
    await Team.loadFromFirestore(user.uid);
    for (final team in Team.getAll()) {
      await TeamMember.loadFromFirestore(team.teamId);
    }

    // Step 2: Load match history
    await MatchHistory.loadFromFirestore();

    // Step 3: For any paused/in-progress match, reload live data
    for (final h in MatchHistory.getAll()) {
      if (h.isPaused || h.isOnProgress) {
        await Match.loadFromFirestore(h.matchId);
        await Innings.loadFromFirestore(h.matchId);

        for (final innings in Innings.getByMatchId(h.matchId)) {
          await Score.loadFromFirestore(innings.inningsId);
          await Bowler.loadFromFirestore(innings.inningsId);

          // Load batsmen from flat collection
          await FirebaseFirestore.instance
              .collection('batsmen_global')
              .where('inningsId', isEqualTo: innings.inningsId)
              .get()
              .then((snap) {
            for (final doc in snap.docs) {
              Batsman.fromMap(doc.data());
            }
          }).catchError((_) {});
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

                  /// Search Bar
                  Positioned(
                    top: 120,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF545454),
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          icon: Icon(
                            Icons.search,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          hintText: "Search...",
                          hintStyle:
                              TextStyle(color: Colors.white.withOpacity(0.7)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  /// Sports Slider
                  Positioned(
                    top: 200,
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

                  /// Book Venue Header
                  Positioned(
                    top: 370,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text(
                          "Book a nearby Venue",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 80),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CricketScorerHeader(),
                              ),
                            );
                          },
                          child: Text(
                            "See All",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// Venue Grid
                  Positioned(
                    top: 410,
                    left: 20,
                    right: 20,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15.0),
                                  child: Image.asset(
                                    'assets/images/cricket_ground_1.png.jpg',
                                    height: 85,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 5),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15.0),
                                  child: Image.asset(
                                    'assets/images/cricket_ground_2.png.jpg',
                                    height: 85,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15.0),
                                  child: Image.asset(
                                    'assets/images/cricket_ground_3.png.jpg',
                                    height: 85,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 5),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15.0),
                                  child: Image.asset(
                                    'assets/images/cricket_ground_4.png.jpg',
                                    height: 85,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15.0),
                                  child: Image.asset(
                                    'assets/images/cricket_ground_5.png.png',
                                    height: 85,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 5),
                                child: Container(
                                  height: 85,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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