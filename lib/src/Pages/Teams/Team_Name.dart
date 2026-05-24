import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:TURF_TOWN_/src/models/team.dart';
import 'package:TURF_TOWN_/src/services/firestore_service.dart';

class TeamNameScreen extends StatefulWidget {
  final int teamNumber;
  final String? tournamentId;
  final Function(Map<String, dynamic>) onTeamCreated;

  const TeamNameScreen({
    super.key,
    required this.teamNumber,
    required this.onTeamCreated,
    this.tournamentId,
  });

  @override
  State<TeamNameScreen> createState() => _TeamNameScreenState();
}

class _TeamNameScreenState extends State<TeamNameScreen> {
  final _fs = FirestoreService.instance;
  List<Team> myTeams = [];
  bool isLoading = true;
  Team? selectedTeam;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadMyTeams();
  }

  Future<void> _loadMyTeams() async {
    setState(() => isLoading = true);
    try {
      // Try Firestore first; fall back to local sqflite teams.
      final teams = await _fs.getMyTeams();
      if (mounted) {
        setState(() {
          myTeams = teams.isNotEmpty ? teams : Team.getAll();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          myTeams = Team.getAll();
          isLoading = false;
        });
      }
    }
  }

  void _confirmSelection() {
    if (selectedTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a team!'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final teamData = {
      'team_id': selectedTeam!.teamId,
      'team_name': selectedTeam!.teamName,
      'team_owner_uid': selectedTeam!.createdBy.isNotEmpty
          ? selectedTeam!.createdBy
          : _uid,
      'team_owner_name': selectedTeam!.ownerName.isNotEmpty
          ? selectedTeam!.ownerName
          : (user?.displayName ?? user?.email ?? ''),
      'player_count': selectedTeam!.teamCount,
    };

    widget.onTeamCreated(teamData);
    Navigator.pop(context, teamData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            return Column(
              children: [
                // ── Header ──────────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.all(w * 0.04),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      SizedBox(width: w * 0.02),
                      Text(
                        'Select Team ${widget.teamNumber}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: w * 0.055,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Team list ────────────────────────────────────────────────
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF00C4FF)),
                        )
                      : myTeams.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.group_add,
                                      size: 60,
                                      color: Colors.white.withOpacity(0.3)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No teams found.\nCreate a team first from the Teams section.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: w * 0.04,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.all(w * 0.04),
                              itemCount: myTeams.length,
                              itemBuilder: (context, index) {
                                final team = myTeams[index];
                                final isSelected =
                                    selectedTeam?.teamId == team.teamId;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => selectedTeam = team),
                                  child: Container(
                                    margin:
                                        EdgeInsets.only(bottom: w * 0.04),
                                    padding: EdgeInsets.all(w * 0.04),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF00C4FF)
                                              .withOpacity(0.2)
                                          : const Color(0xFF1C2026),
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF00C4FF)
                                            : const Color(0xFF00C4FF)
                                                .withOpacity(0.2),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(w * 0.03),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF00C4FF)
                                                : const Color(0xFF00C4FF)
                                                    .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(Icons.group,
                                              color: Colors.white,
                                              size: w * 0.06),
                                        ),
                                        SizedBox(width: w * 0.03),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                team.teamName,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: w * 0.045,
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                '${team.teamCount} players',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.6),
                                                  fontSize: w * 0.035,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(Icons.check_circle,
                                              color: Color(0xFF00C4FF),
                                              size: 24),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),

                // ── Confirm button ───────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.all(w * 0.04),
                  child: InkWell(
                    onTap: _confirmSelection,
                    borderRadius: BorderRadius.circular(22),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C4FF),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: Container(
                        width: double.infinity,
                        padding:
                            EdgeInsets.symmetric(vertical: w * 0.04),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Confirm Team',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: w * 0.045,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: w * 0.02),
                            Icon(Icons.check_circle_outline,
                                color: Colors.white, size: w * 0.06),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}