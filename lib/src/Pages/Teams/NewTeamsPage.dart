// lib/src/Pages/Teams/NewTeamsPage.dart

import 'package:flutter/material.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/team_members_page.dart';
import 'package:TURF_TOWN_/src/models/team.dart';
import 'package:TURF_TOWN_/src/models/team_member.dart';
import 'package:TURF_TOWN_/src/services/firestore_service.dart';

class NewTeamsPage extends StatefulWidget {
  const NewTeamsPage({super.key});

  @override
  State<NewTeamsPage> createState() => _NewTeamsPageState();
}

class _NewTeamsPageState extends State<NewTeamsPage> {
  final _fs = FirestoreService.instance;
  List<Team> _teams = [];

  /// Actual live player counts fetched from the members subcollection.
  /// Keyed by teamId. Shown instead of the stale teamCount field.
  Map<String, int> _liveCounts = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  // ✅ Loads teams + fetches real member counts from subcollection
  Future<void> _loadTeams() async {
    setState(() => _isLoading = true);
    try {
      final teams = await _fs.getMyTeams();

      // Fetch actual member counts in parallel for all teams
      final counts = await Future.wait(
        teams.map((t) async {
       final members = await _fs.getPlayers(t.createdBy, t.teamId);
          return MapEntry(t.teamId, members.length);
        }),
      );

      if (mounted) {
        setState(() {
          _teams = teams;
          _liveCounts = Map.fromEntries(counts);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showCreateTeamDialog() async {
    final ctrl = TextEditingController();
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDs) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2026),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create Team',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  maxLength: 30,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                    color: Colors.black,
                    fontFamily: 'Poppins',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter Team Name',
                    hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
                    filled: true,
                    fillColor: const Color(0xFFD9D9D9),
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF00C4FF),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (_) async {
                    if (!isSaving) {
                      setDs(() => isSaving = true);
                      await _createTeam(ctrl.text, dialogCtx);
                      setDs(() => isSaving = false);
                    }
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white70,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                setDs(() => isSaving = true);
                                await _createTeam(ctrl.text, dialogCtx);
                                setDs(() => isSaving = false);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C4FF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Create',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

Future<void> _createTeam(String rawName, BuildContext dialogCtx) async {
  final name = rawName.trim();
  if (name.isEmpty) {
    _snack('Please enter a team name', Colors.orange);
    return;
  }

  // ✅ Duplicate name check (case-insensitive)
  final isDuplicate = _teams.any(
    (t) => t.teamName.trim().toLowerCase() == name.toLowerCase(),
  );
  if (isDuplicate) {
    _snack('A team named "$name" already exists', Colors.orange);
    return;
  }

  try {
    final team = await _fs.createTeam(name);
    Navigator.of(dialogCtx).pop();
    setState(() {
      _teams.add(team);
      _liveCounts[team.teamId] = 0;
    });
    _snack('Team "${team.teamName}" created!', Colors.green);
  } catch (e) {
    _snack('$e', Colors.red);
  }
}

  void _confirmDelete(Team team) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C2026),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Team',
          style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
        ),
        content: Text(
          'Delete "${team.teamName}" and all its players?',
          style: const TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _fs.deleteTeam(team.teamId);
                setState(() {
                  _teams.removeWhere((t) => t.teamId == team.teamId);
                  _liveCounts.remove(team.teamId); // ✅ clean up count too
                });
                _snack('"${team.teamName}" deleted', Colors.orange);
              } catch (e) {
                _snack('Error: $e', Colors.red);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (d) {
        if (d.primaryVelocity != null && d.primaryVelocity! > 500) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
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
                _buildHeader(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00C4FF),
                          ),
                        )
                      : _teams.isEmpty
                          ? _buildEmptyState()
                          : _buildTeamsList(),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateTeamDialog,
          backgroundColor: const Color(0xFF00C4FF),
          elevation: 6,
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'My Teams',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              Text(
                '${_teams.length} team${_teams.length == 1 ? '' : 's'}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.support_agent, color: Colors.white, size: 26),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_add, size: 80, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'No teams yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 22,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap  +  to create your first team',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTeamsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: _teams.length,
      itemBuilder: (context, index) => _buildTeamCard(_teams[index]),
    );
  }

  Widget _buildTeamCard(Team team) {
    // ✅ Use live count from subcollection, not stale teamCount field
    final liveCount = _liveCounts[team.teamId] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TeamMembersPage(team: team)),
        ).then((_) => _loadTeams()); // refresh everything on return
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2026),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF00C4FF).withOpacity(0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C4FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF00C4FF).withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.group,
                  color: Color(0xFF00C4FF),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.teamName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: Colors.white.withOpacity(0.45),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        // ✅ liveCount used here instead of team.teamCount
                        Text(
                          liveCount == 0
                              ? 'No players yet — tap to add'
                              : '$liveCount player${liveCount == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: liveCount == 0
                                ? const Color(0xFF00C4FF).withOpacity(0.7)
                                : Colors.white.withOpacity(0.55),
                            fontSize: 13,
                            fontFamily: 'Poppins',
                            fontStyle: liveCount == 0
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(0.35),
                    size: 22,
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _confirmDelete(team),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red.withOpacity(0.7),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                Icons.sports_cricket,
                'Toss',
                false,
                () => Navigator.pop(context),
              ),
              _navItem(Icons.group, 'Teams', true, () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF00C4FF).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected ? const Color(0xFF00C4FF) : Colors.white54,
                size: 26),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  color: selected ? const Color(0xFF00C4FF) : Colors.white54,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                )),
          ],
        ),
      ),
    );
  }
}