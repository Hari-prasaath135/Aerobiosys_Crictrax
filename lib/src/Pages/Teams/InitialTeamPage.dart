// lib/src/Pages/Teams/InitialTeamPage.dart — REDESIGNED to match NewTeamsPage aesthetic

import 'package:TURF_TOWN_/src/Pages/Teams/NewTeamsPage.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/TeamPage.dart' show SmoothPageRoute;
import 'package:TURF_TOWN_/src/Pages/Teams/Tournament/tournament_page.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/playerselection_page.dart';
import 'package:TURF_TOWN_/src/models/Tournament_team.dart';
import 'package:TURF_TOWN_/src/models/team_member.dart';
import 'package:TURF_TOWN_/src/models/tournament_model.dart';
import 'package:TURF_TOWN_/src/views/bluetooth_page.dart';
import 'package:TURF_TOWN_/src/views/tv_link_confirm_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:TURF_TOWN_/src/views/history_page.dart';

import 'package:TURF_TOWN_/src/views/Home.dart';
import 'package:TURF_TOWN_/src/models/team.dart';
import 'package:TURF_TOWN_/src/models/match.dart';
import 'package:TURF_TOWN_/src/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class InitialTeamPage extends StatefulWidget {
  final String? tournamentMatchDocId;
  final String? tournamentId;
  final String? prefilledTeamId1;
  final String? prefilledTeamId2;
  final String? prefilledTeamId1Name;
  final String? prefilledTeamId2Name;
  final int? prefilledOvers;

  const InitialTeamPage({
    super.key,
    this.tournamentMatchDocId,
    this.tournamentId,
    this.prefilledTeamId1,
    this.prefilledTeamId2,
    this.prefilledTeamId1Name,
    this.prefilledTeamId2Name,
    this.prefilledOvers,
  });

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
  Map<String, int> _liveCounts = {};
  bool isLoadingTeams = true;

  static const List<Color> _accentColors = [
    Color(0xFF00C4FF),
    Color(0xFF00E676),
    Color(0xFFFF6B35),
    Color(0xFFFFD93D),
    Color(0xFFB388FF),
    Color(0xFFFF4081),
  ];

@override
void initState() {
  super.initState();
  // Pre-fill tournament data if coming from tournament flow
  if (widget.prefilledTeamId1 != null) team1Id = widget.prefilledTeamId1;
  if (widget.prefilledTeamId2 != null) team2Id = widget.prefilledTeamId2;
  if (widget.prefilledOvers != null) {
    oversController.text = widget.prefilledOvers.toString();
  }
  _loadTeams();
}

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  _loadTeams();
}

Future<void> _loadTournamentTeamPlayers(String? tournamentTeamId) async {
  if (tournamentTeamId == null || widget.tournamentId == null) return;
  try {
    final teamDoc = await FirebaseFirestore.instance
        .collection('tournaments')
        .doc(widget.tournamentId)
        .collection('teams')
        .doc(tournamentTeamId)
        .get();
    if (!teamDoc.exists) return;
    final teamData = teamDoc.data() as Map<String, dynamic>;
    final ownerUid = (teamData['ownerUid'] as String?) ?? '';
    final originalTeamId = (teamData['teamId'] as String?) ?? tournamentTeamId;
    if (ownerUid.isEmpty) return;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(ownerUid)
        .collection('teams')
        .doc(originalTeamId)
        .collection('members')
        .get();
    for (final d in snap.docs) {
      TeamMember.fromMap({
        ...d.data(),
        'teamId': tournamentTeamId,
        'teamOwnerUid': ownerUid,
      });
    }
    debugPrint('✅ Loaded ${snap.docs.length} players for $tournamentTeamId');
  } catch (e) {
    debugPrint('❌ Failed to load tournament team players: $e');
  }
}

Future<void> _loadTeams() async {
  try {
    final teams = await _fs.getMyTeams();
    final counts = await Future.wait(
      teams.map((t) async {
        final members = await _fs.getPlayers(t.createdBy, t.teamId);
        return MapEntry(t.teamId, members.length);
      }),
    );

    // Tournament mode: load players into cache + inject teams into list
    if (widget.tournamentId != null) {
      await _loadTournamentTeamPlayers(widget.prefilledTeamId1);
      await _loadTournamentTeamPlayers(widget.prefilledTeamId2);
    }

    if (mounted) {
      setState(() {
        allTeams = teams;
        _liveCounts = Map.fromEntries(counts);

    if (widget.prefilledTeamId1 != null &&
            !allTeams.any((t) => t.teamId == widget.prefilledTeamId1)) {
          allTeams.add(Team(
            teamId: widget.prefilledTeamId1!,
            teamName: widget.prefilledTeamId1Name ?? 'Team 1',
            teamCount: 11,
            createdBy: FirebaseAuth.instance.currentUser?.uid ?? '',
            ownerName: widget.prefilledTeamId1Name ?? 'Team 1',
          ));
          _liveCounts[widget.prefilledTeamId1!] = 11;
        }
        if (widget.prefilledTeamId2 != null &&
            !allTeams.any((t) => t.teamId == widget.prefilledTeamId2)) {
          allTeams.add(Team(
            teamId: widget.prefilledTeamId2!,
            teamName: widget.prefilledTeamId2Name ?? 'Team 2',
            teamCount: 11,
            createdBy: FirebaseAuth.instance.currentUser?.uid ?? '',
            ownerName: widget.prefilledTeamId2Name ?? 'Team 2',
          ));
          _liveCounts[widget.prefilledTeamId2!] = 11;
        }

        isLoadingTeams = false;
      });
    }
  } catch (e) {
    if (mounted) setState(() => isLoadingTeams = false);
  }
}

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  void dispose() {
    oversController.dispose();
    super.dispose();
  }

  // ─── Start Match ───────────────────────────────────────────────────────────

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

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnackBar('User not authenticated. Please sign in.', Colors.red);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2030),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00C4FF).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFF00C4FF),
                  strokeWidth: 2.5,
                ),
                SizedBox(height: 20),
                Text(
                  'Creating match...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Standalone: load from personal teams path
      // Tournament: already loaded into cache by _loadTournamentTeamPlayers
      if (widget.tournamentId == null) {
        await TeamMember.loadFromFirestore(team1Id!);
        await TeamMember.loadFromFirestore(team2Id!);
      }

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
          widget.tournamentId ?? _selectedTournament?.tournamentId ?? 'standalone';

      final match = Match.create(
        tournamentId: resolvedTournamentId,
        teamId1: team1Id!,
        teamId2: team2Id!,
        overs: overs,
        tossWonBy: tossWinnerTeamId!,
        batBowlFlag: tossDecision == 'bat' ? 1 : 2,
        isNoballAllowed: allowNoball,
        isWideAllowed: allowWide,
        createdBy: currentUser.uid,
      );

      // Tournament only: save scorerMatchId back to Firestore match doc
      if (widget.tournamentMatchDocId != null && widget.tournamentId != null) {
        await FirebaseFirestore.instance
            .collection('tournaments')
            .doc(widget.tournamentId)
            .collection('matches')
            .doc(widget.tournamentMatchDocId)
            .update({
          'scorerMatchId': match.matchId,
          'status': 'live',
          'matchStartTime': Timestamp.now(),
          'tossWonBy': tossWinnerTeamId,
          'tossDecision': tossDecision,
          'battingTeamId': match.getBattingTeamId(),
          'bowlingTeamId': match.getBowlingTeamId(),
        });
      }

      final battingTeamId = match.getBattingTeamId();
      final bowlingTeamId = match.getBowlingTeamId();

      // Works for both personal teams and injected tournament teams
      String getTeamName(String teamId) {
        final found = allTeams.where((t) => t.teamId == teamId).firstOrNull;
        if (found != null) return found.teamName;
        if (teamId == widget.prefilledTeamId1) return widget.prefilledTeamId1Name ?? 'Team 1';
        if (teamId == widget.prefilledTeamId2) return widget.prefilledTeamId2Name ?? 'Team 2';
        return 'Team';
      }

      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SelectPlayersPage(
            battingTeamName: getTeamName(battingTeamId),
            bowlingTeamName: getTeamName(bowlingTeamId),
            totalOvers: overs,
            matchId: match.matchId,
          ),
        ),
      );
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
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
          if (details.primaryVelocity != null &&
              details.primaryVelocity! < -500) {
            Navigator.push(context, SmoothPageRoute(page: NewTeamsPage()))
                .then((_) => _loadTeams());
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          extendBody: true,
          drawer: _buildDrawer(),
          backgroundColor: const Color(0xFF0A0E1A),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D1B3E),
                  Color(0xFF0A0E1A),
                  Color(0xFF000000),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: isLoadingTeams
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF00C4FF),
                              strokeWidth: 2.5,
                            ),
                          )
                        : _buildBody(),
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

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF00C4FF).withOpacity(0.12),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withOpacity(0.1), width: 1),
              ),
              child: const Icon(Icons.menu_rounded,
                  color: Colors.white70, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Match',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'SET UP YOUR GAME',
                  style: TextStyle(
                    color: const Color(0xFF00C4FF).withOpacity(0.6),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: (team1Id != null &&
                      team2Id != null &&
                      tossWinnerTeamId != null &&
                      tossDecision != null)
                  ? const Color(0xFF00E676).withOpacity(0.15)
                  : const Color(0xFF00C4FF).withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (team1Id != null &&
                        team2Id != null &&
                        tossWinnerTeamId != null &&
                        tossDecision != null)
                    ? const Color(0xFF00E676).withOpacity(0.4)
                    : const Color(0xFF00C4FF).withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sports_cricket_rounded,
                  color: (team1Id != null &&
                          team2Id != null &&
                          tossWinnerTeamId != null &&
                          tossDecision != null)
                      ? const Color(0xFF00E676)
                      : const Color(0xFF00C4FF),
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  (team1Id != null &&
                          team2Id != null &&
                          tossWinnerTeamId != null &&
                          tossDecision != null)
                      ? 'Ready'
                      : 'Setup',
                  style: TextStyle(
                    color: (team1Id != null &&
                            team2Id != null &&
                            tossWinnerTeamId != null &&
                            tossDecision != null)
                        ? const Color(0xFF00E676)
                        : const Color(0xFF00C4FF),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('TEAMS'),
          const SizedBox(height: 12),
          _buildTeamsCard(),
          const SizedBox(height: 20),
          _buildSectionLabel('TOSS DETAILS'),
          const SizedBox(height: 12),
          _buildTossCard(),
          const SizedBox(height: 20),
          _buildSectionLabel('MATCH SETTINGS'),
          const SizedBox(height: 12),
          _buildSettingsCard(),
          const SizedBox(height: 28),
          _buildStartButton(),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: const Color(0xFF00C4FF).withOpacity(0.6),
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        fontSize: 10,
        letterSpacing: 2.5,
      ),
    );
  }

  // ─── Teams Card ────────────────────────────────────────────────────────────

  Widget _buildTeamsCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141928),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00C4FF).withOpacity(0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C4FF).withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
  _buildTeamRow(
            'Team 1', team1Id, 0,
            widget.tournamentId != null
                ? null
                : (id, uid) => setState(() {
                      team1Id = id;
                      team1OwnerUid = uid;
                      if (tossWinnerTeamId != null &&
                          tossWinnerTeamId != team2Id) {
                        tossWinnerTeamId = null;
                      }
                    }),
          ),
          Divider(
              color: const Color(0xFF00C4FF).withOpacity(0.08),
              height: 1,
              indent: 16,
              endIndent: 16),
          _buildTeamRow(
            'Team 2', team2Id, 1,
            widget.tournamentId != null
                ? null
                : (id, uid) => setState(() {
                      team2Id = id;
                      team2OwnerUid = uid;
                      if (tossWinnerTeamId != null &&
                          tossWinnerTeamId != team1Id) {
                        tossWinnerTeamId = null;
                      }
                    }),
          ),
        ],
      ),
    );
  }

 Widget _buildTeamRow(
    String label,
    String? selectedId,
    int accentIndex,
    Function(String?, String?)? onChanged,
  ) {
    final accent = _accentColors[accentIndex];
    final selectedTeam = selectedId != null
        ? allTeams.firstWhere((t) => t.teamId == selectedId,
            orElse: () => allTeams.first)
        : null;

    final initials = selectedTeam != null
        ? selectedTeam.teamName
            .trim()
            .split(' ')
            .where((w) => w.isNotEmpty)
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join()
        : label == 'Team 1'
            ? 'T1'
            : 'T2';

    return GestureDetector(
     onTap: (onChanged == null || widget.tournamentId != null)
          ? null
          : () => _showTeamSelectionDialog(label, selectedId, onChanged),      child: Padding(
        // ↑ Taller row padding
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Row(
          children: [
            // ↑ Larger avatar
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: selectedTeam != null
                      ? [
                          accent.withOpacity(0.25),
                          accent.withOpacity(0.08),
                        ]
                      : [
                          Colors.white.withOpacity(0.06),
                          Colors.white.withOpacity(0.02),
                        ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selectedTeam != null
                      ? accent.withOpacity(0.5)
                      : Colors.white.withOpacity(0.15),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(
                  color: selectedTeam != null ? accent : Colors.white38,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                  // ↑ Larger initials font
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    selectedTeam?.teamName ?? 'Select Team',
                    style: TextStyle(
                      color: selectedTeam != null
                          ? Colors.white
                          : Colors.white38,
                      fontFamily: 'Poppins',
                      // ↑ Slightly larger team name
                      fontSize: 16,
                      fontWeight: selectedTeam != null
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                  if (selectedTeam != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      '${_liveCounts[selectedTeam.teamId] ?? 0} players',
                      style: TextStyle(
                        color: accent.withOpacity(0.7),
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // ↑ Larger action button
         Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: widget.tournamentId != null
                    ? Colors.white.withOpacity(0.04)
                    : const Color(0xFF00C4FF).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.tournamentId != null
                    ? Icons.lock_outline_rounded
                    : selectedTeam != null
                        ? Icons.swap_horiz_rounded
                        : Icons.add_rounded,
                color: widget.tournamentId != null
                    ? Colors.white24
                    : const Color(0xFF00C4FF),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Toss Card ─────────────────────────────────────────────────────────────

  Widget _buildTossCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141928),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD93D).withOpacity(0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD93D).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTossRow(
            icon: Icons.emoji_events_rounded,
            label: 'Winner',
            value: tossWinnerTeamId != null
                ? allTeams
                    .firstWhere((t) => t.teamId == tossWinnerTeamId,
                        orElse: () => allTeams.first)
                    .teamName
                : null,
            placeholder: 'Select toss winner',
            accentColor: const Color(0xFFFFD93D),
            onTap: () {
              if (team1Id == null || team2Id == null) {
                _showSnackBar('Please select both teams first', Colors.orange);
                return;
              }
              _showTossWinnerDialog();
            },
          ),
          Divider(
              color: const Color(0xFFFFD93D).withOpacity(0.08),
              height: 1,
              indent: 16,
              endIndent: 16),
          _buildTossRow(
            icon: Icons.sports_cricket_rounded,
            label: 'Decision',
            value: tossDecision != null
                ? (tossDecision == 'bat' ? 'Bat First' : 'Bowl First')
                : null,
            placeholder: 'Select bat / bowl',
            accentColor: const Color(0xFFFF6B35),
            onTap: () {
              if (tossWinnerTeamId == null) {
                _showSnackBar(
                    'Please select toss winner first', Colors.orange);
                return;
              }
              _showTossDecisionDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTossRow({
    required IconData icon,
    required String label,
    required String? value,
    required String placeholder,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        // ↑ Taller row padding
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Row(
          children: [
            // ↑ Larger icon box
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: accentColor.withOpacity(0.3), width: 1),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value ?? placeholder,
                    style: TextStyle(
                      color: value != null ? Colors.white : Colors.white38,
                      fontFamily: 'Poppins',
                      // ↑ Slightly larger value text
                      fontSize: 16,
                      fontWeight: value != null
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.2),
              size: 26,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Settings Card ─────────────────────────────────────────────────────────

  Widget _buildSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141928),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFB388FF).withOpacity(0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB388FF).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Overs row
          Padding(
            // ↑ Taller overs row padding
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Row(
              children: [
                // ↑ Larger icon box
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB388FF).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFB388FF).withOpacity(0.3),
                        width: 1),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.timer_outlined,
                      color: Color(0xFFB388FF), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OVERS',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 5),
                      TextField(
                        controller: oversController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          // ↑ Larger input text
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter number of overs',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.25),
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
              color: const Color(0xFFB388FF).withOpacity(0.08),
              height: 1,
              indent: 16,
              endIndent: 16),
          _buildToggleRow(
            icon: Icons.sports_cricket,
            label: 'No-ball',
            subtitle: 'Allow no-ball deliveries',
            value: allowNoball,
            accentColor: const Color(0xFF00E676),
            onChanged: (v) => setState(() => allowNoball = v),
          ),
          Divider(
              color: const Color(0xFFB388FF).withOpacity(0.08),
              height: 1,
              indent: 16,
              endIndent: 16),
          _buildToggleRow(
            icon: Icons.sports_baseball,
            label: 'Wide',
            subtitle: 'Allow wide deliveries',
            value: allowWide,
            accentColor: const Color(0xFF00E676),
            onChanged: (v) => setState(() => allowWide = v),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required Color accentColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      // ↑ Taller toggle row padding
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          // ↑ Larger icon box
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: accentColor.withOpacity(0.25), width: 1),
            ),
            alignment: Alignment.center,
            child: Icon(icon,
                color: value ? accentColor : Colors.white38, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    // ↑ Larger label
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontFamily: 'Poppins',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: accentColor,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  // ─── Start Button ──────────────────────────────────────────────────────────

  Widget _buildStartButton() {
    final isReady = team1Id != null &&
        team2Id != null &&
        tossWinnerTeamId != null &&
        tossDecision != null;

    return GestureDetector(
      onTap: _startMatch,
      child: Container(
        width: double.infinity,
        // ↑ Taller button
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isReady
                ? [
                    const Color(0xFF00C4FF),
                    const Color(0xFF0066CC),
                  ]
                : [
                    const Color(0xFF00C4FF).withOpacity(0.4),
                    const Color(0xFF0066CC).withOpacity(0.4),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isReady
              ? [
                  BoxShadow(
                    color: const Color(0xFF00C4FF).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 26),
            const SizedBox(width: 10),
            const Text(
              'Start Match',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                // ↑ Larger button label
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 10),
            SvgPicture.asset(
              'assets/images/mdi_cricket.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                  Colors.white, BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Team Selection Dialog ─────────────────────────────────────────────────

 void _showTeamSelectionDialog(
    String label,
    String? currentTeamId,
    Function(String?, String?)? onChanged,
  ) {
    // Block team changes in tournament mode
    if (widget.tournamentId != null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 520),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2030),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF00C4FF).withOpacity(0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C4FF).withOpacity(0.10),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C4FF).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shield_rounded,
                          color: Color(0xFF00C4FF), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Select $label',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white54, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                  color: const Color(0xFF00C4FF).withOpacity(0.1),
                  height: 1),
              if (allTeams.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 48, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 12),
                      Text(
                        'No teams yet.\nCreate teams first.',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontFamily: 'Poppins',
                            fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: allTeams.length,
                    separatorBuilder: (_, __) => Divider(
                      color: Colors.white.withOpacity(0.05),
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final team = allTeams[index];
                      final isSelected = team.teamId == currentTeamId;
                      final otherTeamId =
                          label == 'Team 1' ? team2Id : team1Id;
                      final isOtherTeam = team.teamId == otherTeamId;
                      final liveCount = _liveCounts[team.teamId] ?? 0;
                      final hasPlayers = liveCount >= 2;
                      final accent =
                          _accentColors[index % _accentColors.length];
                      final initials = team.teamName
                          .trim()
                          .split(' ')
                          .where((w) => w.isNotEmpty)
                          .take(2)
                          .map((w) => w[0].toUpperCase())
                          .join();

                      return Opacity(
                        opacity: isOtherTeam || !hasPlayers ? 0.4 : 1.0,
                        child: GestureDetector(
                       onTap: isOtherTeam || !hasPlayers || onChanged == null
                              ? null
                              : () {
                                  onChanged!(team.teamId, team.createdBy);
                                  Navigator.pop(context);
                                },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        accent.withOpacity(0.22),
                                        accent.withOpacity(0.07),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(13),
                                    border: Border.all(
                                        color: accent.withOpacity(0.4),
                                        width: 1.5),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    initials.isNotEmpty ? initials : '?',
                                    style: TextStyle(
                                      color: accent,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        team.teamName,
                                        style: TextStyle(
                                          color: isSelected
                                              ? const Color(0xFF00C4FF)
                                              : Colors.white,
                                          fontFamily: 'Poppins',
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isOtherTeam
                                            ? 'Already selected'
                                            : !hasPlayers
                                                ? '$liveCount player${liveCount == 1 ? '' : 's'} (min 2)'
                                                : '$liveCount player${liveCount == 1 ? '' : 's'}',
                                        style: TextStyle(
                                          color: !hasPlayers
                                              ? Colors.red.shade300
                                              : Colors.white38,
                                          fontSize: 12,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded,
                                      color: Color(0xFF00C4FF), size: 22),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Toss Winner Dialog ────────────────────────────────────────────────────

  void _showTossWinnerDialog() {
    final tossTeams = allTeams
        .where((t) => t.teamId == team1Id || t.teamId == team2Id)
        .toList();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C2030),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: const Color(0xFFFFD93D).withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD93D).withOpacity(0.08),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD93D).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.emoji_events_rounded,
                          color: Color(0xFFFFD93D), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Toss Winner',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white54, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                  color: const Color(0xFFFFD93D).withOpacity(0.1),
                  height: 1),
              ...tossTeams.asMap().entries.map((entry) {
                final team = entry.value;
                final isSelected = team.teamId == tossWinnerTeamId;
                final accent = _accentColors[entry.key];
                final initials = team.teamName
                    .trim()
                    .split(' ')
                    .where((w) => w.isNotEmpty)
                    .take(2)
                    .map((w) => w[0].toUpperCase())
                    .join();

                return GestureDetector(
                  onTap: () {
                    setState(() => tossWinnerTeamId = team.teamId);
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              accent.withOpacity(0.22),
                              accent.withOpacity(0.07),
                            ]),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: accent.withOpacity(0.4),
                                width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials.isNotEmpty ? initials : '?',
                            style: TextStyle(
                              color: accent,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            team.teamName,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF00C4FF)
                                  : Colors.white,
                              fontFamily: 'Poppins',
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF00C4FF), size: 24),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Toss Decision Dialog ──────────────────────────────────────────────────

  void _showTossDecisionDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C2030),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: const Color(0xFFFF6B35).withOpacity(0.3), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.sports_cricket_rounded,
                          color: Color(0xFFFF6B35), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Toss Decision',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white54, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  height: 1),
              _buildDecisionTile('bat', 'Bat First',
                  Icons.sports_cricket_rounded, const Color(0xFF00C4FF)),
              Divider(
                  color: Colors.white.withOpacity(0.05),
                  height: 1,
                  indent: 16,
                  endIndent: 16),
              _buildDecisionTile('bowl', 'Bowl First',
                  Icons.sports_baseball_rounded, const Color(0xFFFF6B35)),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecisionTile(
      String value, String label, IconData icon, Color accent) {
    final isSelected = tossDecision == value;
    return GestureDetector(
      onTap: () {
        setState(() => tossDecision = value);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: accent.withOpacity(0.3), width: 1.5),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: accent, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF00C4FF) : Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF00C4FF), size: 24),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E1220),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF00C4FF).withOpacity(0.12),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.sports_cricket_rounded, 'Toss', true, () {}),
              _navItem(Icons.shield_rounded, 'Teams', false, () async {
                await Navigator.push(
                    context, SmoothPageRoute(page: NewTeamsPage()));
                _loadTeams();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
      IconData icon, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF00C4FF).withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(
                  color: const Color(0xFF00C4FF).withOpacity(0.25),
                  width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected ? const Color(0xFF00C4FF) : Colors.white38,
                size: 26),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFF00C4FF) : Colors.white38,
                fontSize: 12,
                fontFamily: 'Poppins',
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: selected ? 0.5 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Drawer ────────────────────────────────────────────────────────────────

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0E1220),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D1B3E), Color(0xFF1A237E)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C4FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.sports_cricket_rounded,
                      color: Color(0xFF00C4FF), size: 28),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Cricket Scorer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'v1.0.0  •  Turf Town',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          _drawerItem(Icons.home_rounded, 'Home', () {
            Navigator.pop(context);
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const Home()),
                (route) => false);
          }),
          _drawerDivider(),
          _drawerItem(Icons.add_circle_rounded, 'New Match',
              () => Navigator.pop(context),
              trailing: _drawerBadge('Current', const Color(0xFF00C4FF))),
          _drawerDivider(),
          _drawerItem(Icons.shield_rounded, 'Teams', () async {
            Navigator.pop(context);
            await Navigator.push(
                context, SmoothPageRoute(page: NewTeamsPage()));
            _loadTeams();
          }, subtitle: 'Manage teams & players'),
          _drawerDivider(),
          _drawerItem(Icons.emoji_events_rounded, 'Tournaments', () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TournamentPage()));
          }, subtitle: 'View & manage tournaments'),
          _drawerDivider(),
          _drawerItem(Icons.devices_rounded, 'Devices', () {
            Navigator.pop(context);
            _showDevicesBottomSheet();
          }, subtitle: 'Scan QR or Bluetooth'),
          _drawerDivider(),
          _drawerItem(Icons.history_rounded, 'Match History', () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HistoryPage()));
          }, subtitle: 'View past matches'),
          _drawerDivider(),
          _drawerItem(Icons.settings_rounded, 'Settings', () {
            Navigator.pop(context);
            _showSettingsDialog();
          }),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap,
      {String? subtitle, Widget? trailing}) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontFamily: 'Poppins',
                  fontSize: 11))
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _drawerDivider() => Divider(
      color: Colors.white.withOpacity(0.06),
      height: 1,
      indent: 16,
      endIndent: 16);

  Widget _drawerBadge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4), width: 1),
        ),
        child: Text(text,
            style: TextStyle(
                color: color,
                fontSize: 10,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700)),
      );

  // ─── Settings / Devices dialogs ───────────────────────────────────────────

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2030),
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(children: [
                Icon(Icons.settings_rounded, color: Color(0xFF00C4FF)),
                SizedBox(width: 12),
                Text('Settings',
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 18)),
              ]),
              const SizedBox(height: 20),
              _settingsTile(
                  Icons.notifications_rounded, 'Notifications', true),
              const Divider(color: Colors.white12),
              _settingsTile(Icons.dark_mode_rounded, 'Dark Mode', true),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close',
                      style: TextStyle(
                          color: Color(0xFF00C4FF),
                          fontFamily: 'Poppins')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsTile(IconData icon, String label, bool value) {
    return Row(children: [
      Icon(icon, color: Colors.white60, size: 22),
      const SizedBox(width: 12),
      Expanded(
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontSize: 14))),
      Switch(
          value: value,
          onChanged: (_) {},
          activeColor: const Color(0xFF00C4FF)),
    ]);
  }

  void _showDevicesBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2030),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2))),
              const Text('Connect Device',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              _deviceTile(
                icon: Icons.qr_code_scanner_rounded,
                color: const Color(0xFF00C4FF),
                title: 'Scan QR',
                subtitle: 'Scan a QR code using your camera',
                onTap: () {
                  Navigator.pop(context);
                  _openQRScanner();
                },
              ),
              Divider(color: Colors.white.withOpacity(0.06), height: 1),
              _deviceTile(
                icon: Icons.bluetooth_rounded,
                color: Colors.blueAccent,
                title: 'Bluetooth',
                subtitle: 'Connect to a Bluetooth device',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BluetoothPage()));
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deviceTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Icon(icon, color: color, size: 26),
      ),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 15)),
      subtitle: Text(subtitle,
          style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontFamily: 'Poppins',
              fontSize: 12)),
    );
  }

  Future<void> _openQRScanner() async {
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      _showSnackBar('Camera permission required', Colors.red);
      return;
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: const Color(0xFF0D1B3E),
            title: const Text('Scan QR Code',
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600)),
            leading: const BackButton(color: Colors.white),
          ),
         body: MobileScanner(
onDetect: (capture) {
  for (final barcode in capture.barcodes) {
    final value = barcode.rawValue;
    if (value == null) continue;

    final uri = Uri.tryParse(value);
    if (uri != null &&
        uri.scheme == 'crictrax' &&   // ← must match TV app
        uri.host == 'link-tv') {
      final sessionId = uri.queryParameters['session'];
      if (sessionId != null) {
        Navigator.pop(context); // close scanner
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TvLinkConfirmScreen(sessionId: sessionId),
          ),
        );
        return;
      }
    }

    // fallback — this is what's currently happening
    Navigator.pop(context);
    _showSnackBar('QR Scanned: $value', Colors.green);
  }
},
),
        ),
      ),
    );
  }
}