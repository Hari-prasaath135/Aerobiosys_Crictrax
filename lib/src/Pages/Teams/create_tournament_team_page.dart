import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:TURF_TOWN_/src/models/tournament_model.dart';
import 'package:TURF_TOWN_/src/models/tournament_team.dart';
import 'package:TURF_TOWN_/src/services/firestore_service.dart';

class CreateTournamentTeamPage extends StatefulWidget {
  final Tournament tournament;
  final VoidCallback onTeamAdded;

  const CreateTournamentTeamPage({
    super.key,
    required this.tournament,
    required this.onTeamAdded,
  });

  @override
  State<CreateTournamentTeamPage> createState() =>
      _CreateTournamentTeamPageState();
}

class _CreateTournamentTeamPageState extends State<CreateTournamentTeamPage> {
  final _fs = FirestoreService.instance;
  final _teamNameCtrl = TextEditingController();
  final _playerCtrl = TextEditingController();
  final List<String> _players = [];
  bool _isSaving = false;

  static const int _minPlayers = 4;

  @override
  void dispose() {
    _teamNameCtrl.dispose();
    _playerCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  void _addPlayer() {
    final name = _playerCtrl.text.trim();
    if (name.isEmpty) return;
    if (_players.any((p) => p.toLowerCase() == name.toLowerCase())) {
      _snack('Player "$name" already added', Colors.orange);
      return;
    }
    setState(() => _players.add(name));
    _playerCtrl.clear();
  }

  void _removePlayer(int index) {
    setState(() => _players.removeAt(index));
  }

  Future<void> _saveTeam() async {
    final teamName = _teamNameCtrl.text.trim();

    if (teamName.isEmpty) {
      _snack('Please enter a team name', Colors.red);
      return;
    }

    if (_players.length < _minPlayers) {
      final needed = _minPlayers - _players.length;
      _snack(
        'Add at least $needed more player${needed == 1 ? '' : 's'} '
        '(minimum $_minPlayers required to join a tournament)',
        Colors.red,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    setState(() => _isSaving = true);

    try {
      // ── BUG 1 FIX: Only check for duplicate teamName in this tournament ──
      // Removed the ownerUid restriction that blocked a user from adding
      // more than one team. Now only prevents the exact same team being
      // added twice (by teamName match).
      final existing = await FirebaseFirestore.instance
          .collection('tournaments')
          .doc(widget.tournament.tournamentId)
          .collection('teams')
          .where('teamName', isEqualTo: teamName)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        _snack(
          'A team named "$teamName" is already in this tournament.',
          Colors.orange,
        );
        return;
      }
      // ──────────────────────────────────────────────────────────────────────

      // 1. Create the team in Firestore under user's teams
      final team = await _fs.createTeam(teamName);

      // 2. Add all players to the team
      for (final playerName in _players) {
        await _fs.addPlayer(
          teamId: team.teamId,
          playerName: playerName,
          teamName: team.teamName,
        );
      }

      // 3. Register team to tournament
      await TournamentTeam.addTeamToTournament(
        tournamentId: widget.tournament.tournamentId,
        teamId: team.teamId,
        teamName: team.teamName,
        ownerUid: user.uid,
        ownerName: user.displayName ?? '',
        playerCount: _players.length,
      );

      widget.onTeamAdded();
      if (mounted) {
        _snack('"$teamName" added to tournament!', Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      _snack('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final needed = _minPlayers - _players.length;
    final hasEnough = _players.length >= _minPlayers;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        title: const Text(
          'Create Team',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: const BackButton(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveTeam,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Color(0xFF00BCD4),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Tournament context chip ──────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events,
                      color: Color(0xFF00BCD4), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Adding to: ${widget.tournament.name}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Minimum players info banner ──────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: hasEnough
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasEnough
                      ? Colors.green.withOpacity(0.4)
                      : Colors.orange.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasEnough ? Icons.check_circle_outline : Icons.info_outline,
                    color: hasEnough ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasEnough
                          ? 'Minimum player requirement met ($_minPlayers/$_minPlayers)'
                          : 'Minimum $_minPlayers players required  •  Add $needed more',
                      style: TextStyle(
                        color: hasEnough ? Colors.green : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Team name ────────────────────────────────────────────────
            _sectionLabel('Team Name'),
            const SizedBox(height: 8),
            TextField(
              controller: _teamNameCtrl,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Enter team name',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.group_outlined,
                    color: Color(0xFF00BCD4), size: 20),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Players section header ───────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionLabel('Players'),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasEnough
                        ? Colors.green.withOpacity(0.15)
                        : Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_players.length} / $_minPlayers min',
                    style: TextStyle(
                      color: hasEnough ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Add player row ───────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _playerCtrl,
                    style: const TextStyle(color: Colors.white),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _addPlayer(),
                    decoration: InputDecoration(
                      hintText: 'Player name',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.person_outline,
                          color: Color(0xFF00BCD4), size: 20),
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _addPlayer,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCD4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 26),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Players list ─────────────────────────────────────────────
            if (_players.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.person_add_outlined,
                        color: Colors.white24, size: 36),
                    const SizedBox(height: 8),
                    const Text(
                      'No players added yet.',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You need at least $_minPlayers players to join this tournament.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.orange, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(
                _players.length,
                (i) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: i < _minPlayers
                          ? Colors.green.withOpacity(0.25)
                          : Colors.white12,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: i < _minPlayers
                              ? Colors.green.withOpacity(0.15)
                              : const Color(0xFF00BCD4).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: i < _minPlayers
                                  ? Colors.green
                                  : const Color(0xFF00BCD4),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _players[i],
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _removePlayer(i),
                        child: const Icon(Icons.close,
                            color: Colors.red, size: 20),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // ── Save button ──────────────────────────────────────────────
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: hasEnough
                    ? const Color(0xFF00BCD4)
                    : const Color(0xFF00BCD4).withOpacity(0.4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving ? null : _saveTeam,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      hasEnough
                          ? 'Save Team & Add to Tournament'
                          : 'Add $needed more player${needed == 1 ? '' : 's'} to continue',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );
}