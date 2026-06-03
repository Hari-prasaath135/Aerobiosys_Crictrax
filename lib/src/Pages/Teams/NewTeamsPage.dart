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

class _NewTeamsPageState extends State<NewTeamsPage>
    with SingleTickerProviderStateMixin {
  final _fs = FirestoreService.instance;
  List<Team> _teams = [];
  Map<String, int> _liveCounts = {};
  bool _isLoading = true;

  late AnimationController _fabAnim;

  // Sporty accent colors cycling per team card
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
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _loadTeams();
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    setState(() => _isLoading = true);
    try {
      final teams = await _fs.getMyTeams();
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
        content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Create Team Dialog ─────────────────────────────────────────────────────

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
              color: const Color(0xFF1C2030),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF00C4FF).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00C4FF).withOpacity(0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon header
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C4FF).withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00C4FF).withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: Color(0xFF00C4FF),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Create Team',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Name your squad',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  maxLength: 30,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter team name',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontFamily: 'Poppins',
                    ),
                    prefixIcon: Icon(
                      Icons.group_rounded,
                      color: const Color(0xFF00C4FF).withOpacity(0.7),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF262B3E),
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF00C4FF),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
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
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white54,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
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
                          disabledBackgroundColor:
                              const Color(0xFF00C4FF).withOpacity(0.4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
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
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
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
      _snack('${team.teamName} created!', const Color(0xFF00E676));
    } catch (e) {
      _snack('$e', Colors.red);
    }
  }

  // ── Delete Confirm ─────────────────────────────────────────────────────────

  void _confirmDelete(Team team) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C2030),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever_rounded,
                  color: Colors.red, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Team',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Colors.white60,
              fontFamily: 'Poppins',
              fontSize: 14,
            ),
            children: [
              const TextSpan(text: 'Delete '),
              TextSpan(
                text: '"${team.teamName}"',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: ' and all its players? This cannot be undone.'),
            ],
          ),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54, fontFamily: 'Poppins'),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _fs.deleteTeam(team.teamId);
                setState(() {
                  _teams.removeWhere((t) => t.teamId == team.teamId);
                  _liveCounts.remove(team.teamId);
                });
                _snack('"${team.teamName}" deleted', Colors.orange);
              } catch (e) {
                _snack('Error: $e', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (d) {
        if (d.primaryVelocity != null && d.primaryVelocity! > 500) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
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
                if (!_isLoading && _teams.isNotEmpty) _buildSummaryStrip(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00C4FF),
                            strokeWidth: 2.5,
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
        floatingActionButton: ScaleTransition(
          scale: CurvedAnimation(parent: _fabAnim, curve: Curves.elasticOut),
          child: FloatingActionButton.extended(
            onPressed: _showCreateTeamDialog,
            backgroundColor: const Color(0xFF00C4FF),
            elevation: 8,
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            label: const Text(
              'New Team',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Teams',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'MANAGE YOUR SQUADS',
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
          // Team count pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF00C4FF).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00C4FF).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded,
                    color: Color(0xFF00C4FF), size: 16),
                const SizedBox(width: 6),
                Text(
                  '${_teams.length}',
                  style: const TextStyle(
                    color: Color(0xFF00C4FF),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.white.withOpacity(0.1), width: 1),
            ),
            child: const Icon(Icons.support_agent_rounded,
                color: Colors.white70, size: 22),
          ),
        ],
      ),
    );
  }

  // ── Summary Strip ──────────────────────────────────────────────────────────

  Widget _buildSummaryStrip() {
    final totalPlayers =
        _liveCounts.values.fold(0, (sum, count) => sum + count);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 2),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00C4FF).withOpacity(0.1),
            const Color(0xFF0044AA).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00C4FF).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _summaryItem(
            icon: Icons.shield_rounded,
            value: '${_teams.length}',
            label: 'Teams',
          ),
          Container(
            width: 1,
            height: 28,
            color: Colors.white.withOpacity(0.1),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          _summaryItem(
            icon: Icons.groups_rounded,
            value: '$totalPlayers',
            label: 'Players',
          ),
          const Spacer(),
          Text(
            'TAP TO ENTER',
            style: TextStyle(
              color: const Color(0xFF00C4FF).withOpacity(0.55),
              fontFamily: 'Poppins',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00C4FF), size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontFamily: 'Poppins',
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF00C4FF).withOpacity(0.07),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00C4FF).withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.shield_outlined,
              size: 56,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Squads Yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 22,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first team to get started',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ── Teams List ─────────────────────────────────────────────────────────────

  Widget _buildTeamsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
      itemCount: _teams.length,
      itemBuilder: (context, index) =>
          _buildTeamCard(_teams[index], index),
    );
  }

  // ── Team Card ──────────────────────────────────────────────────────────────

  Widget _buildTeamCard(Team team, int index) {
    final liveCount = _liveCounts[team.teamId] ?? 0;
    final accent = _accentColors[index % _accentColors.length];

    // Team initials (up to 2 words)
    final initials = team.teamName
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return GestureDetector(
   onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => TeamMembersPage(team: team)),
  ).then((_) async {
    await _loadTeams();
    final updatedCount = _liveCounts[team.teamId] ?? 0;
    if (updatedCount < 4 && mounted) {
      _snack(
        '"${team.teamName}" needs ${4 - updatedCount} more player(s) '
        'to be eligible for tournaments (min. 4 required).',
        Colors.orange,
      );
    }
  });
},
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141928),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // Left accent bar
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [accent, accent.withOpacity(0.2)],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
                child: Row(
                  children: [
                    // Team initials avatar
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accent.withOpacity(0.25),
                            accent.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accent.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials.isNotEmpty ? initials : '?',
                        style: TextStyle(
                          color: accent,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Name & player count
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team.teamName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                liveCount == 0
                                    ? Icons.person_add_alt_1_rounded
                                    : Icons.groups_rounded,
                                color: liveCount == 0
                                    ? accent.withOpacity(0.7)
                                    : Colors.white.withOpacity(0.45),
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                             Text(
  liveCount == 0
      ? 'No players yet — tap to add'
      : liveCount < 4
          ? '$liveCount/4 players — needs ${4 - liveCount} more'
          : '$liveCount player${liveCount == 1 ? '' : 's'}',
  style: TextStyle(
    color: liveCount == 0
        ? accent.withOpacity(0.8)
        : liveCount < 4
            ? Colors.orange
            : Colors.white.withOpacity(0.5),
    fontSize: 12,
    fontFamily: 'Poppins',
    fontStyle: liveCount == 0
        ? FontStyle.italic
        : FontStyle.normal,
    fontWeight: FontWeight.w500,
  ),
),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Action buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white.withOpacity(0.25),
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _confirmDelete(team),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.25),
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red,
                              size: 18,
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
    );
  }

  // ── Bottom Nav Bar ─────────────────────────────────────────────────────────

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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                Icons.sports_cricket_rounded,
                'Toss',
                false,
                () => Navigator.pop(context),
              ),
              _navItem(Icons.shield_rounded, 'Teams', true, () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF00C4FF).withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(
                  color: const Color(0xFF00C4FF).withOpacity(0.25),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFF00C4FF) : Colors.white38,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFF00C4FF) : Colors.white38,
                fontSize: 11,
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
}