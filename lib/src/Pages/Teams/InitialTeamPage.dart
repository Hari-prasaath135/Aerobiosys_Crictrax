// lib/src/Pages/Teams/InitialTeamPage.dart — CORRECTED
// ✅ Adds live player count tracking (matches NewTeamsPage pattern)

import 'package:TURF_TOWN_/src/Pages/Teams/NewTeamsPage.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/TeamPage.dart' show SmoothPageRoute;
import 'package:TURF_TOWN_/src/Pages/Teams/playerselection_page.dart';
import 'package:TURF_TOWN_/src/models/Tournament_team.dart';
import 'package:TURF_TOWN_/src/models/team_member.dart';
import 'package:TURF_TOWN_/src/models/tournament_model.dart';
import 'package:TURF_TOWN_/src/views/bluetooth_page.dart';
import 'package:TURF_TOWN_/src/views/history_page.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/tournament_page.dart';
import 'package:TURF_TOWN_/src/views/Home.dart';
import 'package:TURF_TOWN_/src/models/team.dart';
import 'package:TURF_TOWN_/src/models/match.dart'; 
import 'package:TURF_TOWN_/src/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class InitialTeamPage extends StatefulWidget {
  const InitialTeamPage({super.key});

  @override
  State<InitialTeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<InitialTeamPage> {
  final _fs = FirestoreService.instance;
  final TextEditingController oversController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? team1Id;
  String? team2Id;
  String? team1OwnerUid;
  String? team2OwnerUid;
  String? tossWinnerTeamId;
  String? tossDecision;
  Tournament? _selectedTournament;
  bool allowNoball = true;
  bool allowWide = true;

  List<Team> allTeams = [];
  
  /// ✅ NEW: Live player counts from members subcollection (keyed by teamId)
  Map<String, int> _liveCounts = {};
  
  bool isLoadingTeams = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTeams();
  }

  /// ✅ FIXED: Now fetches live player counts in parallel (like NewTeamsPage)
  Future<void> _loadTeams() async {
    try {
      final teams = await _fs.getMyTeams();
      
      // ✅ Fetch actual member counts in parallel for all teams
      final counts = await Future.wait(
        teams.map((t) async {
          final members = await _fs.getPlayers(t.createdBy, t.teamId);
          return MapEntry(t.teamId, members.length);
        }),
      );

      if (mounted) {
        setState(() {
          allTeams = teams;
          _liveCounts = Map.fromEntries(counts);
          isLoadingTeams = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingTeams = false);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  void dispose() {
    oversController.dispose();
    super.dispose();
  }

  // ─── Start Match: validate then go to TournamentPage ──────────────────────

  void _startMatch() async {
    if (team1Id == null || team2Id == null) {
      _showSnackBar('Please select both teams', Colors.red);
      return;
    }
    if (team1Id == team2Id) {
      _showSnackBar('Teams cannot be the same', Colors.red);
      return;
    }
    if (tossWinnerTeamId == null) {
      _showSnackBar('Please select toss winner', Colors.red);
      return;
    }
    if (tossDecision == null) {
      _showSnackBar('Please select toss decision', Colors.red);
      return;
    }
    if (oversController.text.trim().isEmpty) {
      _showSnackBar('Please enter number of overs', Colors.red);
      return;
    }
    final overs = int.tryParse(oversController.text.trim());
    if (overs == null || overs <= 0) {
      _showSnackBar('Please enter a valid number of overs', Colors.red);
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: const Dialog(
          backgroundColor: Colors.transparent,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF00C4FF)),
                SizedBox(height: 16),
                Text(
                  'Creating match...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Load players for both teams before creating match
      await TeamMember.loadFromFirestore(team1Id!);
      await TeamMember.loadFromFirestore(team2Id!);

      // Create a standalone match (no tournament)
      // We use a fixed placeholder tournamentId for non-tournament matches
      // Tournament guard
      if (_selectedTournament != null) {
        await TournamentTeam.addTeamToTournament(
          tournamentId: _selectedTournament!.tournamentId,
          teamId: team1Id!,
          teamName: allTeams.firstWhere((t) => t.teamId == team1Id).teamName,
        );
        await TournamentTeam.addTeamToTournament(
          tournamentId: _selectedTournament!.tournamentId,
          teamId: team2Id!,
          teamName: allTeams.firstWhere((t) => t.teamId == team2Id).teamName,
        );
      }

      final String resolvedTournamentId =
          _selectedTournament?.tournamentId ?? 'standalone';

      final match = Match.create(
        tournamentId: resolvedTournamentId,
        teamId1: team1Id!,
        teamId2: team2Id!,
        overs: overs,
        tossWonBy: tossWinnerTeamId!,
        batBowlFlag: tossDecision == 'bat' ? 1 : 2,
        isNoballAllowed: allowNoball,
        isWideAllowed: allowWide,
      );

      debugPrint('✅ Match created: ${match.matchId}');

      // Determine batting/bowling team names
      final battingTeamId = match.getBattingTeamId();
      final bowlingTeamId = match.getBowlingTeamId();

      final battingTeam = allTeams.firstWhere(
        (t) => t.teamId == battingTeamId,
        orElse: () => allTeams.first,
      );
      final bowlingTeam = allTeams.firstWhere(
        (t) => t.teamId == bowlingTeamId,
        orElse: () => allTeams.first,
      );

      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Navigate to SelectPlayersPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SelectPlayersPage(
            battingTeamName: battingTeam.teamName,
            bowlingTeamName: bowlingTeam.teamName,
            totalOvers: overs,
            matchId: match.matchId,
          ),
        ),
      );
    } catch (e) {
      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      debugPrint('❌ Error creating match: $e');
      _showSnackBar('Error creating match: $e', Colors.red);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
            (route) => false,
          );
        }
      },
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < -500) {
            Navigator.push(context, SmoothPageRoute(page: NewTeamsPage()))
                .then((_) => _loadTeams());
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          extendBody: true,
          drawer: _buildDrawer(),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF283593), Color(0xFF1A237E), Color(0xFF000000)],
                stops: [0.0, 0.0, 0.2],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                    child: _buildHeader(MediaQuery.of(context).size.width),
                  ),
                  Expanded(
                    child: isLoadingTeams
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C4FF)))
                        : _buildTossPage(),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomNavBar(),
        ),
      ),
    );
  }

  // ─── Toss page ─────────────────────────────────────────────────────────────

  Widget _buildTossPage() {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: h),
          child: IntrinsicHeight(
            child: Padding(
              padding: EdgeInsets.only(
                  left: w * 0.04, right: w * 0.04,
                  top: w * 0.02, bottom: w * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTeamsSection(w),
                  SizedBox(height: h * 0.025),
                  _buildTossDetailsSection(w),
                  SizedBox(height: h * 0.025),
                  _buildOversSection(w),
                  SizedBox(height: h * 0.04),
                  _buildBottomRow(w),
                  SizedBox(height: h * 0.025),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ─── Drawer ────────────────────────────────────────────────────────────────

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF1C2026),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF283593), Color(0xFF1A237E)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Row(children: [
                  Icon(Icons.sports_cricket, color: Color(0xFF00C4FF), size: 32),
                  SizedBox(width: 12),
                  Text('Cricket Scorer',
                      style: TextStyle(color: Colors.white, fontSize: 24,
                          fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 8),
                Text('Manage your cricket matches',
                    style: TextStyle(color: Colors.white.withOpacity(0.7),
                        fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Color(0xFF00C4FF)),
            title: const Text('Home', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (context) => const Home()),
                  (route) => false);
            },
          ),
          const Divider(color: Colors.white24, height: 1),
          ListTile(
            leading: const Icon(Icons.add_circle, color: Color(0xFF00C4FF)),
            title: const Text('New Match', style: TextStyle(color: Colors.white)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00C4FF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00C4FF), width: 1),
              ),
              child: const Text('Current',
                  style: TextStyle(color: Color(0xFF00C4FF),
                      fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(color: Colors.white24, height: 1),
          ListTile(
            leading: const Icon(Icons.group, color: Colors.white),
            title: const Text('Teams', style: TextStyle(color: Colors.white)),
            subtitle: Text('Manage teams & players',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(context, SmoothPageRoute(page: NewTeamsPage()));
              _loadTeams();
            },
          ),
          const Divider(color: Colors.white24, height: 1),
          ListTile(
            leading: const Icon(Icons.emoji_events, color: Colors.white),
            title: const Text('Tournaments', style: TextStyle(color: Colors.white)),
            subtitle: Text('View & manage tournaments',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const TournamentPage()));
            },
          ),
          const Divider(color: Colors.white24, height: 1),
          ListTile(
            leading: const Icon(Icons.devices, color: Colors.white),
            title: const Text('Devices', style: TextStyle(color: Colors.white)),
            subtitle: Text('Scan QR or connect via Bluetooth',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
            onTap: () {
              Navigator.pop(context);
              _showDevicesBottomSheet();
            },
          ),
          const Divider(color: Colors.white24, height: 1),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.white),
            title: const Text('Match History', style: TextStyle(color: Colors.white)),
            subtitle: Text('View past matches',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const HistoryPage()));
            },
          ),
          const Divider(color: Colors.white24, height: 1),
          ListTile(
            leading: Icon(Icons.settings, color: Colors.white.withOpacity(0.5)),
            title: Text('Settings',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
            onTap: () {
              Navigator.pop(context);
              _showSettingsDialog();
            },
          ),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: [
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              Text('Cricket Scorer v1.0.0',
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text('© 2026 Turf Town',
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9),
                  textAlign: TextAlign.center),
            ]),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2026),
        title: const Row(children: [
          Icon(Icons.settings, color: Color(0xFF00C4FF)),
          SizedBox(width: 12),
          Text('Settings', style: TextStyle(color: Colors.white)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications, color: Colors.white70),
              title: const Text('Notifications', style: TextStyle(color: Colors.white)),
              trailing: Switch(value: true, onChanged: (_) {},
                  activeColor: const Color(0xFF00C4FF)),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.dark_mode, color: Colors.white70),
              title: const Text('Dark Mode', style: TextStyle(color: Colors.white)),
              trailing: Switch(value: true, onChanged: (_) {},
                  activeColor: const Color(0xFF00C4FF)),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF00C4FF))),
          ),
        ],
      ),
    );
  }

  void _showDevicesBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2026),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.white24,
                      borderRadius: BorderRadius.circular(2))),
              const Text('Connect Device',
                  style: TextStyle(color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C4FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.qr_code_scanner,
                      color: Color(0xFF00C4FF), size: 28),
                ),
                title: const Text('Scan QR',
                    style: TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w600)),
                subtitle: Text('Scan a QR code using your camera',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                onTap: () { Navigator.pop(context); _openQRScanner(); },
              ),
              const Divider(color: Colors.white12, height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bluetooth,
                      color: Colors.blueAccent, size: 28),
                ),
                title: const Text('Bluetooth',
                    style: TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w600)),
                subtitle: Text('Connect to a Bluetooth device',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const BluetoothPage()));
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openQRScanner() async {
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      _showSnackBar('Camera permission is required to scan QR codes', Colors.red);
      return;
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A237E),
            title: const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
            leading: const BackButton(color: Colors.white),
          ),
          body: MobileScanner(
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                final value = barcode.rawValue;
                if (value != null) {
                  Navigator.pop(context);
                  _showSnackBar('QR Scanned: $value', Colors.green);
                }
              }
            },
          ),
        ),
      ),
    );
  }

  // ─── Bottom nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3),
              blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.sports_cricket,
                label: 'Toss',
                isSelected: true,
                onTap: () {},
              ),
              _buildNavItem(
                icon: Icons.group,
                label: 'Teams',
                isSelected: false,
                onTap: () async {
                  await Navigator.push(context, SmoothPageRoute(page: NewTeamsPage()));
                  _loadTeams();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00C4FF).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isSelected ? const Color(0xFF00C4FF) : Colors.white70,
                size: 28),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF00C4FF) : Colors.white70,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                )),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(double w) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: Icon(Icons.menu, color: Colors.white, size: w * 0.07),
        ),
        Expanded(
          child: Center(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: 'Cricket ', style: _textStyle(w * 0.1)),
              TextSpan(text: 'Scorer', style: _textStyle(w * 0.05)),
            ])),
          ),
        ),
        Row(children: [
          _buildSvgIcon('assets/images/ix_support.svg', w * 0.065),
          SizedBox(width: w * 0.025),
          Opacity(opacity: 0.90,
              child: _buildSvgIcon('assets/images/Group.svg', w * 0.065)),
        ]),
      ],
    );
  }

  // ─── Teams section ─────────────────────────────────────────────────────────

  Widget _buildTeamsSection(double w) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Teams', style: _textStyle(w * 0.04)),
          SizedBox(height: w * 0.04),
          _buildTeamDropdown('Team 1', team1Id, w,
              (id, ownerUid) => setState(() { team1Id = id; team1OwnerUid = ownerUid; })),
          SizedBox(height: w * 0.03),
          _buildTeamDropdown('Team 2', team2Id, w,
              (id, ownerUid) => setState(() { team2Id = id; team2OwnerUid = ownerUid; })),
        ],
      ),
    );
  }

  Widget _buildTeamDropdown(
    String label,
    String? selectedTeamId,
    double w,
    Function(String?, String?) onChanged,
  ) {
    final selectedTeam = selectedTeamId != null
        ? allTeams.firstWhere((t) => t.teamId == selectedTeamId,
            orElse: () => allTeams.first)
        : null;

    return Row(
      children: [
        SizedBox(width: w * 0.2, child: Text(label, style: _textStyle(w * 0.034))),
        Expanded(
          child: GestureDetector(
            onTap: () => _showTeamSelectionDialog(label, selectedTeamId, onChanged),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.03),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF5C5C5E), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      selectedTeam?.teamName ?? 'Select Team',
                      style: _textStyle(w * 0.034, null,
                          selectedTeam != null ? Colors.white : Colors.white.withOpacity(0.5)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.7)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTeamSelectionDialog(
    String label,
    String? currentTeamId,
    Function(String?, String?) onChanged,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2026),
        title: Text('Select $label', style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: allTeams.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No teams available.\nPlease create teams first.',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: allTeams.length,
                  itemBuilder: (context, index) {
                    final team = allTeams[index];
                    final isSelected = team.teamId == currentTeamId;
                    final otherTeamId = label == 'Team 1' ? team2Id : team1Id;
                    final isOtherTeam = team.teamId == otherTeamId;
                    
                    /// ✅ FIXED: Use live count from _liveCounts instead of stale team.teamCount
                    final liveCount = _liveCounts[team.teamId] ?? 0;
                    final hasPlayers = liveCount >= 2;

                    return Opacity(
                      opacity: isOtherTeam || !hasPlayers ? 0.4 : 1.0,
                      child: ListTile(
                        enabled: !isOtherTeam && hasPlayers,
                        title: Text(team.teamName,
                            style: TextStyle(
                                color: isSelected ? const Color(0xFF00C4FF) : Colors.white,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                        subtitle: Text(
                          isOtherTeam
                              ? 'Already selected'
                              : !hasPlayers
                                  ? '$liveCount player${liveCount == 1 ? '' : 's'} (min 2 required)'
                                  : '$liveCount player${liveCount == 1 ? '' : 's'}',
                          style: TextStyle(
                              color: !hasPlayers ? Colors.red.shade300 : Colors.white60,
                              fontSize: 12),
                        ),
                        leading: Icon(Icons.group,
                            color: isSelected ? const Color(0xFF00C4FF) : Colors.white70),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Color(0xFF00C4FF))
                            : null,
                        onTap: isOtherTeam || !hasPlayers
                            ? null
                            : () {
                                onChanged(team.teamId, team.createdBy);
                                Navigator.pop(context);
                              },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // ─── Toss details ──────────────────────────────────────────────────────────

  Widget _buildTossDetailsSection(double w) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Toss Details', style: _textStyle(w * 0.04)),
          SizedBox(height: w * 0.04),
          _buildTossWinnerDropdown(w),
          SizedBox(height: w * 0.03),
          _buildTossDecisionDropdown(w),
        ],
      ),
    );
  }

  Widget _buildTossWinnerDropdown(double w) {
    final winner = tossWinnerTeamId != null
        ? allTeams.firstWhere((t) => t.teamId == tossWinnerTeamId,
            orElse: () => allTeams.first)
        : null;

    return Row(
      children: [
        SizedBox(width: w * 0.2, child: Text('Winner', style: _textStyle(w * 0.034))),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (team1Id == null || team2Id == null) {
                _showSnackBar('Please select both teams first', Colors.orange);
                return;
              }
              _showTossWinnerDialog();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.03),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF5C5C5E), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      winner?.teamName ?? 'Select Winner',
                      style: _textStyle(w * 0.034, null,
                          winner != null ? Colors.white : Colors.white.withOpacity(0.5)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.7)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTossWinnerDialog() {
    final tossTeams = allTeams
        .where((t) => t.teamId == team1Id || t.teamId == team2Id)
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2026),
        title: const Text('Select Toss Winner', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: tossTeams.map((team) {
            final isSelected = team.teamId == tossWinnerTeamId;
            return ListTile(
              title: Text(team.teamName,
                  style: TextStyle(
                      color: isSelected ? const Color(0xFF00C4FF) : Colors.white,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
              leading: Icon(Icons.emoji_events,
                  color: isSelected ? const Color(0xFF00C4FF) : Colors.white70),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Color(0xFF00C4FF))
                  : null,
              onTap: () {
                setState(() => tossWinnerTeamId = team.teamId);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
        ],
      ),
    );
  }

  Widget _buildTossDecisionDropdown(double w) {
    return Row(
      children: [
        SizedBox(width: w * 0.2, child: Text('Decision', style: _textStyle(w * 0.034))),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (tossWinnerTeamId == null) {
                _showSnackBar('Please select toss winner first', Colors.orange);
                return;
              }
              _showTossDecisionDialog();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.03),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF5C5C5E), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tossDecision != null
                          ? (tossDecision == 'bat' ? 'Bat First' : 'Bowl First')
                          : 'Select Decision',
                      style: _textStyle(w * 0.034, null,
                          tossDecision != null ? Colors.white : Colors.white.withOpacity(0.5)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.7)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTossDecisionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2026),
        title: const Text('Select Toss Decision', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Bat First',
                  style: TextStyle(
                      color: tossDecision == 'bat' ? const Color(0xFF00C4FF) : Colors.white)),
              leading: Icon(Icons.sports_cricket,
                  color: tossDecision == 'bat' ? const Color(0xFF00C4FF) : Colors.white70),
              trailing: tossDecision == 'bat'
                  ? const Icon(Icons.check_circle, color: Color(0xFF00C4FF))
                  : null,
              onTap: () {
                setState(() => tossDecision = 'bat');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Bowl First',
                  style: TextStyle(
                      color: tossDecision == 'bowl' ? const Color(0xFF00C4FF) : Colors.white)),
              leading: Icon(Icons.sports_baseball,
                  color: tossDecision == 'bowl' ? const Color(0xFF00C4FF) : Colors.white70),
              trailing: tossDecision == 'bowl'
                  ? const Icon(Icons.check_circle, color: Color(0xFF00C4FF))
                  : null,
              onTap: () {
                setState(() => tossDecision = 'bowl');
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
        ],
      ),
    );
  }

  // ─── Overs + bottom row ────────────────────────────────────────────────────

  Widget _buildOversSection(double w) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        borderRadius: BorderRadius.circular(10),
      ),
      child: _buildLabeledTextField('Overs', 'Enter the overs', w),
    );
  }

  Widget _buildBottomRow(double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Icon(Icons.sports_cricket, color: Colors.white70, size: w * 0.05),
          SizedBox(width: w * 0.03),
          SizedBox(width: w * 0.2, child: Text('No-ball', style: _textStyle(w * 0.034))),
          Switch(
            value: allowNoball,
            onChanged: (v) => setState(() => allowNoball = v),
            activeColor: const Color(0xFF00C4FF),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
        ]),
        SizedBox(height: w * 0.02),
        Row(children: [
          Icon(Icons.sports_baseball, color: Colors.white70, size: w * 0.05),
          SizedBox(width: w * 0.03),
          SizedBox(width: w * 0.2, child: Text('Wide', style: _textStyle(w * 0.034))),
          Switch(
            value: allowWide,
            onChanged: (v) => setState(() => allowWide = v),
            activeColor: const Color(0xFF00C4FF),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
        ]),
        SizedBox(height: w * 0.04),
        Center(
          child: GestureDetector(
            onTap: _startMatch,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: w * 0.08, vertical: w * 0.035),
              decoration: BoxDecoration(
                color: const Color(0xFF00C4FF),
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 10,
                      offset: Offset(0, 4))
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Start Match',
                      style: _textStyle(w * 0.042, FontWeight.w600)),
                  SizedBox(width: w * 0.025),
                  _buildSvgIcon('assets/images/mdi_cricket.svg', w * 0.062),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledTextField(String label, String placeholder, double w) {
    return Row(
      children: [
        SizedBox(width: w * 0.26, child: Text(label, style: _textStyle(w * 0.034))),
        Expanded(
          child: TextField(
            controller: oversController,
            keyboardType: TextInputType.number,
            style: _textStyle(w * 0.034, null, Colors.black),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: _textStyle(w * 0.034, null, const Color(0xFF9E9E9E)),
              filled: true,
              fillColor: const Color(0xFFD9D9D9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD1D1D1))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD1D1D1))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00C4FF), width: 2)),
              contentPadding: EdgeInsets.symmetric(
                  horizontal: w * 0.04, vertical: w * 0.025),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Utility ───────────────────────────────────────────────────────────────

  Widget _buildSvgIcon(String path, double size, {bool colored = true}) {
    return SvgPicture.asset(path, width: size, height: size,
        colorFilter: colored
            ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
            : null);
  }

  TextStyle _textStyle(double size, [FontWeight? weight, Color? color]) {
    return TextStyle(
      color: color ?? Colors.white,
      fontSize: size,
      fontFamily: 'Poppins',
      fontWeight: weight ?? FontWeight.w400,
    );
  }
}