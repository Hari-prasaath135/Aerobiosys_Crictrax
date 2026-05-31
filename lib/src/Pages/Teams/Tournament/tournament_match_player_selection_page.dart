// lib/src/Pages/Teams/Tournament/tournament_match_player_selection_page.dart
//
// Fetches both teams' players from Firestore, runs toss UI, then:
//  1. Creates a local Match object (so CricketScorerScreen can find it)
//  2. Saves scorerMatchId back to the Firestore tournament match doc
//  3. Launches CricketScorerScreen
// ═══════════════════════════════════════════════════════════════════════════

import 'package:TURF_TOWN_/src/Pages/Teams/cricket_scorer_screen.dart';
import 'package:TURF_TOWN_/src/models/batsman.dart';
import 'package:TURF_TOWN_/src/models/bowler.dart';
import 'package:TURF_TOWN_/src/models/innings.dart';
import 'package:TURF_TOWN_/src/models/match.dart';
import 'package:TURF_TOWN_/src/models/score.dart';
import 'package:TURF_TOWN_/src/models/tournament_model.dart';
import 'package:TURF_TOWN_/src/models/team_member.dart';
import 'package:TURF_TOWN_/src/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TournamentMatchPlayerSelectionPage extends StatefulWidget {
  final Tournament tournament;
  final String matchDocId;
  final String teamId1;
  final String teamId2;
  final String teamId1Name;
  final String teamId2Name;
  final int overs;

  const TournamentMatchPlayerSelectionPage({
    super.key,
    required this.tournament,
    required this.matchDocId,
    required this.teamId1,
    required this.teamId2,
    required this.teamId1Name,
    required this.teamId2Name,
    required this.overs,
  });

  @override
  State<TournamentMatchPlayerSelectionPage> createState() =>
      _TournamentMatchPlayerSelectionPageState();
}

class _TournamentMatchPlayerSelectionPageState
    extends State<TournamentMatchPlayerSelectionPage> {
  final _fs = FirestoreService.instance;

  // ── Toss state ────────────────────────────────────────────────────────
  String? _tossWinnerTeamId;
  String? _tossDecision; // 'bat' | 'bowl'

  // ── Player state ──────────────────────────────────────────────────────
  List<TeamMember> _team1Players = [];
  List<TeamMember> _team2Players = [];
  String? _selectedStriker;
  String? _selectedNonStriker;
  String? _selectedBowler;

  bool _isLoading = true;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  // ─── Load players for both teams from Firestore ───────────────────────
Future<void> _loadPlayers() async {
  try {
    final tournamentId = widget.tournament.tournamentId;

    // Step 1: Get team metadata from tournament to find ownerUid + original teamId
    Future<List<TeamMember>> fetchTeamPlayers(
        String tournamentTeamId, String teamDisplayName) async {
      
      // Get the tournament team doc to find ownerUid and original teamId
      final teamDoc = await FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tournamentId)
          .collection('teams')
          .doc(tournamentTeamId)
          .get();

      if (!teamDoc.exists) {
        debugPrint('⚠️ Tournament team doc not found: $tournamentTeamId');
        return [];
      }

      final teamData = teamDoc.data() as Map<String, dynamic>;
      final ownerUid = (teamData['ownerUid'] as String?) ?? '';
      final originalTeamId = (teamData['teamId'] as String?) ?? tournamentTeamId;

      debugPrint('📋 Team: $teamDisplayName | ownerUid: $ownerUid | originalTeamId: $originalTeamId');

      if (ownerUid.isEmpty || originalTeamId.isEmpty) {
        debugPrint('⚠️ Missing ownerUid or teamId for $teamDisplayName');
        return [];
      }

      // Fetch from users/{ownerUid}/teams/{originalTeamId}/members
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerUid)
          .collection('teams')
          .doc(originalTeamId)
          .collection('members')
          .get();

      debugPrint('✅ $teamDisplayName: ${snap.docs.length} members found');

      return snap.docs.map((d) {
        final data = d.data();
        // Use fromMap so cache is populated and playerName getter works
        return TeamMember.fromMap({
          ...data,
          'teamId': tournamentTeamId, // remap to tournament teamId for lookups
          'teamOwnerUid': ownerUid,
        });
      }).toList();
    }

    final results = await Future.wait([
      fetchTeamPlayers(widget.teamId1, widget.teamId1Name),
      fetchTeamPlayers(widget.teamId2, widget.teamId2Name),
    ]);

    final finalT1 = results[0];
    final finalT2 = results[1];

    debugPrint('✅ ${widget.teamId1Name}: ${finalT1.length} players');
    debugPrint('✅ ${widget.teamId2Name}: ${finalT2.length} players');

    if (mounted) {
      setState(() {
        _team1Players = finalT1;
        _team2Players = finalT2;
        _isLoading = false;
      });

      if (finalT1.isEmpty) {
        _snack('⚠️ ${widget.teamId1Name} has no players!', Colors.orange);
      }
      if (finalT2.isEmpty) {
        _snack('⚠️ ${widget.teamId2Name} has no players!', Colors.orange);
      }
    }
  } catch (e) {
    debugPrint('❌ Error loading players: $e');
    if (mounted) {
      setState(() => _isLoading = false);
      _snack('Error loading players: $e', Colors.red);
    }
  }
}

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));

  // ─── Derived helpers ──────────────────────────────────────────────────
  String get _battingTeamId {
    if (_tossWinnerTeamId == null || _tossDecision == null) return '';
    if (_tossDecision == 'bat') return _tossWinnerTeamId!;
    return _tossWinnerTeamId == widget.teamId1
        ? widget.teamId2
        : widget.teamId1;
  }

  String get _bowlingTeamId {
    if (_battingTeamId.isEmpty) return '';
    return _battingTeamId == widget.teamId1 ? widget.teamId2 : widget.teamId1;
  }

  List<TeamMember> get _battingPlayers =>
      _battingTeamId == widget.teamId1 ? _team1Players : _team2Players;

  List<TeamMember> get _bowlingPlayers =>
      _bowlingTeamId == widget.teamId1 ? _team1Players : _team2Players;

  String get _battingTeamName =>
      _battingTeamId == widget.teamId1
          ? widget.teamId1Name
          : widget.teamId2Name;

  String get _bowlingTeamName =>
      _bowlingTeamId == widget.teamId1
          ? widget.teamId1Name
          : widget.teamId2Name;

  // ─── Validate & start ─────────────────────────────────────────────────
  bool _validate() {
    if (_tossWinnerTeamId == null) {
      _snack('Select toss winner', Colors.orange);
      return false;
    }
    if (_tossDecision == null) {
      _snack('Select bat or bowl', Colors.orange);
      return false;
    }
    if (_selectedStriker == null ||
        _selectedNonStriker == null ||
        _selectedBowler == null) {
      _snack('Select striker, non-striker and bowler', Colors.orange);
      return false;
    }
    if (_selectedStriker == _selectedNonStriker) {
      _snack('Striker and non-striker cannot be the same', Colors.red);
      return false;
    }
    return true;
  }

  Future<void> _startMatch() async {
    if (!_validate()) return;
    setState(() => _isStarting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final tournamentId = widget.tournament.tournamentId;

      // ── 1. Load players into local cache (required by Match model) ────
      await TeamMember.loadFromFirestore(widget.teamId1);
      await TeamMember.loadFromFirestore(widget.teamId2);

      // ── 2. Create a local Match object so CricketScorerScreen can find it
      //       batBowlFlag: 1 = batting team won toss and bats,
      //                    2 = batting team won toss and bowls
      final int batBowlFlag = _tossDecision == 'bat' ? 1 : 2;

      final match = Match.create(
        tournamentId: tournamentId,
        teamId1: widget.teamId1,
        teamId2: widget.teamId2,
        overs: widget.overs,
        tossWonBy: _tossWinnerTeamId!,
        batBowlFlag: batBowlFlag,
        isNoballAllowed: true,
        isWideAllowed: true,
        createdBy: uid,
      );

      // ── 3. Save scorerMatchId back to the Firestore tournament match doc
      //       so _updateTournamentMatchResult can look it up later
      await FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .doc(widget.matchDocId)
          .update({
        'scorerMatchId': match.matchId,
        'status': 'live',
        'matchStartTime': Timestamp.now(),
        'tossWonBy': _tossWinnerTeamId,
        'tossDecision': _tossDecision,
        'battingTeamId': _battingTeamId,
        'bowlingTeamId': _bowlingTeamId,
      });

      // ── 4. Create innings ─────────────────────────────────────────────
      final innings = Innings.createFirstInnings(
        matchId: match.matchId,
        battingTeamId: _battingTeamId,
        bowlingTeamId: _bowlingTeamId,
        tournamentId: tournamentId,
        createdBy: uid,
      );

      // ── 5. Create batsmen & bowler ────────────────────────────────────
      final striker = Batsman.create(
        inningsId: innings.inningsId,
        teamId: _battingTeamId,
        playerId: _selectedStriker!,
        tournamentId: tournamentId,
        matchId: match.matchId,
        createdBy: uid,
      );
      final nonStriker = Batsman.create(
        inningsId: innings.inningsId,
        teamId: _battingTeamId,
        playerId: _selectedNonStriker!,
        tournamentId: tournamentId,
        matchId: match.matchId,
        createdBy: uid,
      );
      final bowler = Bowler.create(
        inningsId: innings.inningsId,
        teamId: _bowlingTeamId,
        playerId: _selectedBowler!,
        tournamentId: tournamentId,
        matchId: match.matchId,
        createdBy: uid,
      );

      // ── 6. Create score ───────────────────────────────────────────────
      final score = Score.create(
        innings.inningsId,
        tournamentId: tournamentId,
        matchId: match.matchId,
        createdBy: uid,
      );
      score.strikeBatsmanId = striker.batId;
      score.nonStrikeBatsmanId = nonStriker.batId;
      score.currentBowlerId = bowler.bowlerId;
      score.save();

      if (!mounted) return;

      // ── 7. Navigate to CricketScorerScreen ────────────────────────────
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CricketScorerScreen(
            matchId: match.matchId,       // ← local Match ID, not Firestore doc ID
            inningsId: innings.inningsId,
            strikeBatsmanId: striker.batId,
            nonStrikeBatsmanId: nonStriker.batId,
            bowlerId: bowler.bowlerId,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isStarting = false);
      _snack('Error starting match: $e', Colors.red);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        title: Text(
          '${widget.teamId1Name} vs ${widget.teamId2Name}',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          overflow: TextOverflow.ellipsis,
        ),
        leading: const BackButton(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00BCD4)))
          : SingleChildScrollView(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 16, bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Toss section ───────────────────────────────────────
                  _sectionHeader('Toss', Icons.emoji_events_outlined),
                  const SizedBox(height: 10),
                  _tossWinnerCard(),
                  const SizedBox(height: 10),
                  _tossDecisionCard(),
                  const SizedBox(height: 24),

                  // ── Player selection (only when toss is done) ──────────
                  if (_tossWinnerTeamId != null && _tossDecision != null) ...[
                    _sectionHeader(
                        'Batting: $_battingTeamName', Icons.sports_cricket),
                    const SizedBox(height: 10),
                    _playerSelector(
                      label: 'Striker',
                      players: _battingPlayers,
                      selectedId: _selectedStriker,
                      exclude: _selectedNonStriker,
                      onPicked: (id) => setState(() => _selectedStriker = id),
                    ),
                    const SizedBox(height: 10),
                    _playerSelector(
                      label: 'Non-Striker',
                      players: _battingPlayers,
                      selectedId: _selectedNonStriker,
                      exclude: _selectedStriker,
                      onPicked: (id) =>
                          setState(() => _selectedNonStriker = id),
                    ),
                    const SizedBox(height: 24),
                    _sectionHeader(
                        'Bowling: $_bowlingTeamName', Icons.sports_baseball),
                    const SizedBox(height: 10),
                    _playerSelector(
                      label: 'Opening Bowler',
                      players: _bowlingPlayers,
                      selectedId: _selectedBowler,
                      onPicked: (id) => setState(() => _selectedBowler = id),
                    ),
                    const SizedBox(height: 32),

                    // ── Start button ───────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BCD4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: _isStarting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.play_arrow_rounded, size: 22),
                        label: Text(
                          _isStarting ? 'Starting…' : 'Start Match',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        onPressed: _isStarting ? null : _startMatch,
                      ),
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.white38, size: 18),
                          SizedBox(width: 10),
                          Text(
                            'Complete the toss to select players.',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  // ─── Toss: winner card ────────────────────────────────────────────────
  Widget _tossWinnerCard() {
    return _selectCard(
      title: 'Toss Winner',
      options: [
        (widget.teamId1, widget.teamId1Name),
        (widget.teamId2, widget.teamId2Name),
      ],
      selectedValue: _tossWinnerTeamId,
      onSelected: (v) => setState(() {
        _tossWinnerTeamId = v;
        _tossDecision = null;
        _selectedStriker = null;
        _selectedNonStriker = null;
        _selectedBowler = null;
      }),
    );
  }

  // ─── Toss: decision card ──────────────────────────────────────────────
  Widget _tossDecisionCard() {
    if (_tossWinnerTeamId == null) return const SizedBox.shrink();
    final winnerName = _tossWinnerTeamId == widget.teamId1
        ? widget.teamId1Name
        : widget.teamId2Name;
    return _selectCard(
      title: '$winnerName chose to…',
      options: const [('bat', 'Bat First'), ('bowl', 'Bowl First')],
      selectedValue: _tossDecision,
      onSelected: (v) => setState(() {
        _tossDecision = v;
        _selectedStriker = null;
        _selectedNonStriker = null;
        _selectedBowler = null;
      }),
    );
  }

  // ─── Generic horizontal option card ──────────────────────────────────
  Widget _selectCard({
    required String title,
    required List<(String, String)> options,
    required String? selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFF00BCD4).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            children: options.map((opt) {
              final (value, label) = opt;
              final selected = value == selectedValue;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelected(value),
                  child: Container(
                    margin: EdgeInsets.only(
                        right: opt == options.last ? 0 : 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF00BCD4)
                          : const Color(0xFF0D0D1A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: selected
                              ? const Color(0xFF00BCD4)
                              : Colors.white12),
                    ),
                    child: Text(label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white54,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        )),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Player picker row ────────────────────────────────────────────────
  Widget _playerSelector({
    required String label,
    required List<TeamMember> players,
    required String? selectedId,
    String? exclude,
    required ValueChanged<String> onPicked,
  }) {
    final selected = selectedId != null
        ? players.where((p) => p.playerId == selectedId).firstOrNull
        : null;

    return GestureDetector(
      onTap: () => _showPlayerPicker(
          label: label,
          players: players,
          selectedId: selectedId,
          exclude: exclude,
          onPicked: onPicked),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected != null
                  ? const Color(0xFF00BCD4).withOpacity(0.4)
                  : Colors.white12),
        ),
        child: Row(
          children: [
            Icon(Icons.person_outline,
                color: selected != null
                    ? const Color(0xFF00BCD4)
                    : Colors.white38,
                size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    selected?.playerName ?? 'Tap to select',
                    style: TextStyle(
                      color:
                          selected != null ? Colors.white : Colors.white38,
                      fontSize: 14,
                      fontWeight: selected != null
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  // ─── Player picker bottom sheet ───────────────────────────────────────
  void _showPlayerPicker({
    required String label,
    required List<TeamMember> players,
    required String? selectedId,
    String? exclude,
    required ValueChanged<String> onPicked,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Select $label',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 12),
            Expanded(
              child: players.isEmpty
                  ? const Center(
                      child: Text('No players found.',
                          style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: players.length,
                      itemBuilder: (_, i) {
                        final p = players[i];
                        final isSelected = p.playerId == selectedId;
                        final isExcluded = p.playerId == exclude;
                        return Opacity(
                          opacity: isExcluded ? 0.4 : 1,
                          child: GestureDetector(
                            onTap: isExcluded
                                ? null
                                : () {
                                    Navigator.pop(context);
                                    onPicked(p.playerId);
                                  },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF00BCD4)
                                        .withOpacity(0.15)
                                    : const Color(0xFF0D0D1A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF00BCD4)
                                        : Colors.white12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.person,
                                      color: Color(0xFF00BCD4), size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(p.playerName,
                                        style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.white70,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal)),
                                  ),
                                  if (isExcluded)
                                    const Text('Already selected',
                                        style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 11)),
                                  if (isSelected)
                                    const Icon(Icons.check_circle,
                                        color: Color(0xFF00BCD4), size: 18),
                                ],
                              ),
                            ),
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

  // ─── Section header ───────────────────────────────────────────────────
  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00BCD4), size: 18),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
      ],
    );
  }
}