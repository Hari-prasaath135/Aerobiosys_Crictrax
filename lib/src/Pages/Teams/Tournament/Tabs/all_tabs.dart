import 'dart:math' as math;
import 'package:TURF_TOWN_/src/Pages/Teams/InitialTeamPage.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/Tournament/tournament_formats.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/Tournament/tournament_match_player_selection_page.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/Tournament/tournament_schedule_helpers.dart';
import 'package:TURF_TOWN_/src/models/team_member.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:TURF_TOWN_/src/models/tournament_model.dart';
import 'package:TURF_TOWN_/src/models/Tournament_team.dart';
import 'package:TURF_TOWN_/src/models/team.dart';
import 'package:TURF_TOWN_/src/services/firestore_service.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/create_tournament_team_page.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/TeamPage.dart';


// ═══════════════════════════════════════════════════════════════════════════
// MATCHES TAB
// ═══════════════════════════════════════════════════════════════════════════

class MatchesTab extends StatefulWidget {
  final Tournament tournament;
  const MatchesTab({super.key, required this.tournament});

  @override
  State<MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends State<MatchesTab>
    with SingleTickerProviderStateMixin {
  late TabController _matchTabController;
  final List<String> _matchTabs = ['Live', 'Upcoming', 'Past'];

  bool get _isKnockout => widget.tournament.format == 'single_elimination';

  @override
  void initState() {
    super.initState();
    _matchTabController = TabController(length: _matchTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _matchTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isKnockout) {
      return KnockoutBracketView(tournament: widget.tournament);
    }

    return Column(
      children: [
      Container(
  color: const Color(0xFF0D0D1A),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  child: AnimatedBuilder(
    animation: _matchTabController,
    builder: (_, __) {
      return Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF12122A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              alignment: Alignment(
                -1.0 + (_matchTabController.index * (2 / (_matchTabs.length - 1))),
                0,
              ),
              child: FractionallySizedBox(
                widthFactor: 1 / _matchTabs.length,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00BCD4).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: List.generate(_matchTabs.length, (i) {
                final selected = _matchTabController.index == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _matchTabController.animateTo(i)),
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white38,
                          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                          letterSpacing: selected ? 0.3 : 0,
                        ),
                        child: Text(_matchTabs[i]),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    },
  ),
),
        Expanded(
          child: TabBarView(
            controller: _matchTabController,
            children: [
              ScheduledMatchList(tournament: widget.tournament, filter: 'live'),
              ScheduledMatchList(tournament: widget.tournament, filter: 'upcoming'),
              ScheduledMatchList(tournament: widget.tournament, filter: 'past'),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// KNOCKOUT BRACKET VIEW
// ═══════════════════════════════════════════════════════════════════════════

class KnockoutBracketView extends StatelessWidget {
  final Tournament tournament;
  const KnockoutBracketView({super.key, required this.tournament});

  bool get _isCreator {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return tournament.createdBy == uid;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tournament.tournamentId)
          .collection('matches')
          .orderBy('roundNo')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00BCD4)));
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.account_tree_outlined,
                    color: Color(0xFF00BCD4), size: 52),
                SizedBox(height: 12),
                Text('No bracket generated yet.',
                    style: TextStyle(color: Colors.white38, fontSize: 14)),
                SizedBox(height: 6),
                Text('Go to Teams tab and tap Auto-Generate Schedule.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white24, fontSize: 12)),
              ],
            ),
          );
        }

        final Map<int, List<QueryDocumentSnapshot>> roundMap = {};
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final r = (data['roundNo'] as int?) ?? 0;
          roundMap.putIfAbsent(r, () => []).add(doc);
        }

        final sortedRounds = roundMap.keys.toList()..sort();
        final finalRound = sortedRounds.last;
        final finalMatches = roundMap[finalRound]!;
        String? champion;
        if (finalMatches.length == 1) {
          final fd = finalMatches.first.data() as Map<String, dynamic>;
          if ((fd['isCompleted'] as bool?) == true) {
            champion = (fd['winnerName'] as String?)?.isNotEmpty == true
                ? fd['winnerName'] as String
                : null;
          }
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
          children: [
            if (champion != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFFB300), Color(0xFFFF6F00)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events,
                        color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🏆 Tournament Champion',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          Text(champion,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            for (final r in sortedRounds) ...[
              RoundHeader(
                roundName: (roundMap[r]!.first.data()
                    as Map<String, dynamic>)['roundName'] as String? ??
                    'Round ${r + 1}',
                matchCount: roundMap[r]!.length,
              ),
              const SizedBox(height: 8),
              for (final doc in roundMap[r]!)
                KnockoutMatchCard(
                  doc: doc,
                  tournament: tournament,
                  isCreator: _isCreator,
                ),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}

// ─── Round Header ──────────────────────────────────────────────────────────

class RoundHeader extends StatelessWidget {
  final String roundName;
  final int matchCount;
  const RoundHeader(
      {super.key, required this.roundName, required this.matchCount});

  @override
  Widget build(BuildContext context) {
 return Padding(
  padding: const EdgeInsets.only(bottom: 2),
  child: Row(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF283593)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00BCD4).withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_tree_outlined,
                color: Color(0xFF00BCD4), size: 12),
            const SizedBox(width: 5),
            Text(
              roundName,
              style: const TextStyle(
                color: Color(0xFF00BCD4),
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 10),
      Text(
        '$matchCount match${matchCount == 1 ? '' : 'es'}',
        style: const TextStyle(color: Colors.white38, fontSize: 11),
      ),
      const SizedBox(width: 8),
      const Expanded(
        child: Divider(color: Colors.white10, thickness: 1),
      ),
    ],
  ),
);
  }
}

// ─── Knockout Match Card ───────────────────────────────────────────────────

// ─── Knockout Match Card ───────────────────────────────────────────────────

class KnockoutMatchCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final Tournament tournament;
  final bool isCreator;

  const KnockoutMatchCard({
    super.key,
    required this.doc,
    required this.tournament,
    required this.isCreator,
  });

  Future<void> _declareWinner(
      BuildContext context, String winnerId, String winnerName) async {
    final data = doc.data() as Map<String, dynamic>;
    final nextMatchId = (data['nextMatchId'] as String?) ?? '';
    final nextMatchSlot = (data['nextMatchSlot'] as int?) ?? 1;
    final batch = FirebaseFirestore.instance.batch();

    final matchRef = FirebaseFirestore.instance
        .collection('tournaments')
        .doc(tournament.tournamentId)
        .collection('matches')
        .doc(doc.id);

    batch.update(matchRef, {
      'winnerId': winnerId,
      'winnerName': winnerName,
      'isCompleted': true,
      'status': 'completed',
    });

    if (nextMatchId.isNotEmpty) {
      final nextRef = FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tournament.tournamentId)
          .collection('matches')
          .doc(nextMatchId);

      if (nextMatchSlot == 1) {
        batch.update(nextRef, {'teamId1': winnerId, 'teamId1Name': winnerName});
      } else {
        batch.update(nextRef, {'teamId2': winnerId, 'teamId2Name': winnerName});
      }
    }

    try {
      await batch.commit();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$winnerName advances!'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showWinnerPicker(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final t1Id = (data['teamId1'] as String?) ?? '';
    final t1Name = (data['teamId1Name'] as String?) ?? 'Team 1';
    final t2Id = (data['teamId2'] as String?) ?? '';
    final t2Name = (data['teamId2Name'] as String?) ?? 'Team 2';

    if (t1Id.isEmpty || t2Id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Both teams must be set before declaring a winner.'),
          backgroundColor: Colors.orange));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const Text('Declare Match Winner',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Select the winning team to advance them.',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 20),
            _winnerTile(context, t1Id, t1Name),
            const SizedBox(height: 10),
            _winnerTile(context, t2Id, t2Name),
          ],
        ),
      ),
    );
  }

  Widget _winnerTile(BuildContext context, String teamId, String teamName) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _declareWinner(context, teamId, teamName);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events, color: Color(0xFF00BCD4), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(teamName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  bool _isWithinMatchWindow(DateTime scheduledAt) {
    final diff = DateTime.now().difference(scheduledAt).inMinutes;
    return diff >= -30 && diff <= 360;
  }

  void _onStartMatchTapped(BuildContext context, String matchDocId) async {
    final data = doc.data() as Map<String, dynamic>;
    final scheduledAt = (data['scheduledAt'] as Timestamp?)?.toDate();

    if (scheduledAt != null) {
      final diff = DateTime.now().difference(scheduledAt).inMinutes;
      if (diff < -30) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: const Text('Start Early?',
                style: TextStyle(color: Colors.white)),
            content: Text(
              'This match is scheduled for ${scheduledAt.day}/${scheduledAt.month} '
              '${scheduledAt.hour}:${scheduledAt.minute.toString().padLeft(2, '0')}.\n\n'
              'Are you sure you want to start it now?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Start Anyway',
                    style: TextStyle(color: Color(0xFF00E676))),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
      }
    }

    final t1Id = (data['teamId1'] as String?) ?? '';
    final t2Id = (data['teamId2'] as String?) ?? '';
    final t1Name = (data['teamId1Name'] as String?) ?? 'Team 1';
    final t2Name = (data['teamId2Name'] as String?) ?? 'Team 2';
    final overs = (data['overs'] as int?) ?? 20;

    if (t1Id.isEmpty || t2Id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Both teams must be assigned before starting.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    if (!context.mounted) return;
    await FirebaseFirestore.instance
        .collection('tournaments')
        .doc(tournament.tournamentId)
        .collection('matches')
        .doc(matchDocId)
        .update({'status': 'live'});

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InitialTeamPage(
          tournamentMatchDocId: matchDocId,
          tournamentId: tournament.tournamentId,
          prefilledTeamId1: t1Id,
          prefilledTeamId2: t2Id,
          prefilledTeamId1Name: t1Name,
          prefilledTeamId2Name: t2Name,
          prefilledOvers: overs,
        ),
      ),
    );
  }

  void _editMatchSchedule(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime? scheduledDate = (data['scheduledAt'] as Timestamp?)?.toDate();
    TimeOfDay? scheduledTime = scheduledDate != null
        ? TimeOfDay(hour: scheduledDate.hour, minute: scheduledDate.minute)
        : null;
    final oversCtrl = TextEditingController(
        text: ((data['overs'] as int?) ?? 20).toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                const Text('Set Match Schedule',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                TextField(
                  controller: oversCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Overs',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.sports_cricket,
                        color: Color(0xFF00BCD4), size: 20),
                    filled: true,
                    fillColor: const Color(0xFF0D0D1A),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final today = DateTime.now();
                          final picked = await showDatePicker(
                            context: sheetCtx,
                            initialDate: scheduledDate ?? today,
                            firstDate:
                                DateTime(today.year, today.month, today.day),
                            lastDate: tournament.endDate,
                            builder: (ctx, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFF00BCD4),
                                  surface: Color(0xFF1A1A2E),
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setSheet(() => scheduledDate = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                  scheduledTime?.hour ?? 0,
                                  scheduledTime?.minute ?? 0,
                                ));
                          }
                        },
                        child: _dateTimeBox(
                          icon: Icons.calendar_today,
                          label: scheduledDate != null
                              ? '${scheduledDate!.day}/${scheduledDate!.month}/${scheduledDate!.year}'
                              : 'Pick Date',
                          hasValue: scheduledDate != null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: sheetCtx,
                            initialTime: scheduledTime ?? TimeOfDay.now(),
                            builder: (ctx, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFF00BCD4),
                                  surface: Color(0xFF1A1A2E),
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setSheet(() {
                              scheduledTime = picked;
                              scheduledDate = DateTime(
                                scheduledDate?.year ?? DateTime.now().year,
                                scheduledDate?.month ?? DateTime.now().month,
                                scheduledDate?.day ?? DateTime.now().day,
                                picked.hour,
                                picked.minute,
                              );
                            });
                          }
                        },
                        child: _dateTimeBox(
                          icon: Icons.access_time,
                          label: scheduledTime != null
                              ? scheduledTime!.format(sheetCtx)
                              : 'Pick Time',
                          hasValue: scheduledTime != null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final overs = int.tryParse(oversCtrl.text.trim()) ?? 20;
                    final updateData = <String, dynamic>{'overs': overs};
                    if (scheduledDate != null) {
                      updateData['scheduledAt'] =
                          Timestamp.fromDate(scheduledDate!);
                      updateData['status'] = 'scheduled';
                    }
                    try {
                      await FirebaseFirestore.instance
                          .collection('tournaments')
                          .doc(tournament.tournamentId)
                          .collection('matches')
                          .doc(doc.id)
                          .update(updateData);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Schedule saved.'),
                                backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red));
                      }
                    }
                  },
                  child: const Text('Save',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateTimeBox(
      {required IconData icon, required String label, required bool hasValue}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00BCD4), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: hasValue ? Colors.white : Colors.white38,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── Team chip helper ────────────────────────────────────────────────────
  Widget _teamChip({
    required String name,
    required bool isWinner,
    required bool isPending,
    bool alignRight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isWinner
            ? const Color(0xFFFFB300).withOpacity(0.10)
            : isPending
                ? Colors.white.withOpacity(0.03)
                : const Color(0xFF00BCD4).withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isWinner
              ? const Color(0xFFFFB300).withOpacity(0.4)
              : isPending
                  ? Colors.white10
                  : const Color(0xFF00BCD4).withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!alignRight && isWinner)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.emoji_events,
                      color: Color(0xFFFFB300), size: 12),
                ),
              Flexible(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isPending
                        ? Colors.white30
                        : isWinner
                            ? Colors.white
                            : Colors.white70,
                    fontWeight:
                        isWinner ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              if (alignRight && isWinner)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.emoji_events,
                      color: Color(0xFFFFB300), size: 12),
                ),
            ],
          ),
          if (isWinner)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Winner ✓',
                style: TextStyle(
                  color: const Color(0xFFFFB300).withOpacity(0.85),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Status badge helper ─────────────────────────────────────────────────
  Widget _statusBadge({required bool isCompleted, required String status}) {
    final Color color = isCompleted
        ? const Color(0xFFFFB300)
        : status == 'pending'
            ? Colors.white24
            : Colors.green;
    final String label = isCompleted
        ? '✓  Completed'
        : status == 'pending'
            ? '⏳  Waiting'
            : '📅  Scheduled';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.45)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // ── BUILD ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final team1Id = (data['teamId1'] as String?) ?? '';
    final team2Id = (data['teamId2'] as String?) ?? '';
    final team1Name = (data['teamId1Name'] as String?) ?? 'TBD';
    final team2Name = (data['teamId2Name'] as String?) ?? 'TBD';
    final isCompleted = (data['isCompleted'] as bool?) ?? false;
    final isBye = (data['isBye'] as bool?) ?? false;
    final winnerId = (data['winnerId'] as String?) ?? '';
    final winnerName = (data['winnerName'] as String?) ?? '';
    final overs = (data['overs'] as int?) ?? 20;
    final scheduledAt = (data['scheduledAt'] as Timestamp?)?.toDate();
    final status = (data['status'] as String?) ?? 'pending';
    final team1IsWinner = isCompleted && winnerId == team1Id;
    final team2IsWinner = isCompleted && winnerId == team2Id;

    // ── Bye row ─────────────────────────────────────────────────────────
    if (isBye) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            const Icon(Icons.fast_forward, color: Colors.white38, size: 16),
            const SizedBox(width: 8),
            Text('$winnerName  — BYE (advances automatically)',
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      );
    }

    // ── Normal match card ───────────────────────────────────────────────
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFFFFB300).withOpacity(0.45)
              : const Color(0xFF00BCD4).withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: isCompleted
                ? const Color(0xFFFFB300).withOpacity(0.07)
                : const Color(0xFF00BCD4).withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // ── Single child: Column with teams + footer ─────────────────────
      child: Column(
        children: [
          // ── Side-by-side team chips ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: _teamChip(
                    name: team1Name,
                    isWinner: team1IsWinner,
                    isPending: status == 'pending',
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Text(
                    'VS',
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: _teamChip(
                    name: team2Name,
                    isWinner: team2IsWinner,
                    isPending: status == 'pending',
                    alignRight: true,
                  ),
                ),
              ],
            ),
          ),

          // ── Footer bar ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.22),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                _statusBadge(isCompleted: isCompleted, status: status),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: isCreator && !isCompleted
                      ? () => _editMatchSchedule(context)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isCreator && !isCompleted
                          ? const Color(0xFF00BCD4).withOpacity(0.1)
                          : Colors.transparent,
                      border: Border.all(
                        color: isCreator && !isCompleted
                            ? const Color(0xFF00BCD4).withOpacity(0.35)
                            : Colors.transparent,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sports_cricket,
                            color: Color(0xFF00BCD4), size: 11),
                        const SizedBox(width: 3),
                        Text(
                          '$overs ov',
                          style: TextStyle(
                            color: isCreator && !isCompleted
                                ? const Color(0xFF00BCD4)
                                : Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (scheduledAt != null)
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Colors.white38, size: 11),
                      const SizedBox(width: 4),
                      Text(
                        '${scheduledAt.day}/${scheduledAt.month}  '
                        '${scheduledAt.hour}:${scheduledAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  )
                else
                  const Text('No date set',
                      style:
                          TextStyle(color: Colors.white24, fontSize: 10)),
                if (isCreator &&
                    !isCompleted &&
                    (status != 'pending' ||
                        (team1Id.isNotEmpty && team2Id.isNotEmpty))) ...[
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    color: const Color(0xFF1A1A2E),
                    icon: const Icon(Icons.more_vert,
                        color: Colors.white38, size: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onSelected: (v) {
                      if (v == 'schedule') _editMatchSchedule(context);
                      if (v == 'winner') _showWinnerPicker(context);
                      if (v == 'start') _onStartMatchTapped(context, doc.id);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'start',
                        child: Row(children: [
                          Icon(Icons.play_arrow,
                              color: Color(0xFF00E676), size: 16),
                          SizedBox(width: 8),
                          Text('Start Match',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'schedule',
                        child: Row(children: [
                          Icon(Icons.calendar_month,
                              color: Color(0xFF00BCD4), size: 16),
                          SizedBox(width: 8),
                          Text('Set Schedule',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'winner',
                        child: Row(children: [
                          Icon(Icons.emoji_events,
                              color: Color(0xFFFFB300), size: 16),
                          SizedBox(width: 8),
                          Text('Declare Winner',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}



class ScheduledMatchList extends StatelessWidget {
  final Tournament tournament;
  final String filter;
  const ScheduledMatchList(
      {super.key, required this.tournament, required this.filter});

  bool get _isCreator {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return tournament.createdBy == uid;
  }

  void _editMatch(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final t1Ctrl =
        TextEditingController(text: (data['teamId1Name'] as String?) ?? '');
    final t2Ctrl =
        TextEditingController(text: (data['teamId2Name'] as String?) ?? '');
    final oversCtrl = TextEditingController(
        text: ((data['overs'] as int?) ?? 20).toString());

    DateTime? scheduledDate = (data['scheduledAt'] as Timestamp?)?.toDate();
    TimeOfDay? scheduledTime = scheduledDate != null
        ? TimeOfDay(hour: scheduledDate.hour, minute: scheduledDate.minute)
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                const Text('Edit Match',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _sheetField(t1Ctrl, 'Team 1 Name', Icons.group_outlined),
                const SizedBox(height: 10),
                _sheetField(t2Ctrl, 'Team 2 Name', Icons.group_outlined),
                const SizedBox(height: 10),
                _sheetField(oversCtrl, 'Overs', Icons.sports_cricket,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final today = DateTime.now();
                          final picked = await showDatePicker(
                            context: sheetCtx,
                            initialDate: scheduledDate ?? today,
                            firstDate: DateTime(
                                today.year, today.month, today.day),
                            lastDate: tournament.endDate,
                            builder: (ctx, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFF00BCD4),
                                  surface: Color(0xFF1A1A2E),
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setSheet(() => scheduledDate = DateTime(
                                  picked.year, picked.month, picked.day,
                                  scheduledTime?.hour ?? 0,
                                  scheduledTime?.minute ?? 0,
                                ));
                          }
                        },
                        child: _dateTimeBox(
                          icon: Icons.calendar_today,
                          label: scheduledDate != null
                              ? '${scheduledDate!.day}/${scheduledDate!.month}/${scheduledDate!.year}'
                              : 'Pick Date',
                          hasValue: scheduledDate != null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: sheetCtx,
                            initialTime:
                                scheduledTime ?? TimeOfDay.now(),
                            builder: (ctx, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFF00BCD4),
                                  surface: Color(0xFF1A1A2E),
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setSheet(() {
                              scheduledTime = picked;
                              scheduledDate = DateTime(
                                scheduledDate?.year ?? DateTime.now().year,
                                scheduledDate?.month ?? DateTime.now().month,
                                scheduledDate?.day ?? DateTime.now().day,
                                picked.hour,
                                picked.minute,
                              );
                            });
                          }
                        },
                        child: _dateTimeBox(
                          icon: Icons.access_time,
                          label: scheduledTime != null
                              ? scheduledTime!.format(sheetCtx)
                              : 'Pick Time',
                          hasValue: scheduledTime != null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final overs =
                        int.tryParse(oversCtrl.text.trim()) ?? 20;
                    final updateData = <String, dynamic>{
                      'teamId1Name': t1Ctrl.text.trim(),
                      'teamId2Name': t2Ctrl.text.trim(),
                      'overs': overs,
                      'matchStartTime': scheduledDate != null
                          ? Timestamp.fromDate(scheduledDate!)
                          : null,
                    };
                    if (scheduledDate != null) {
                      updateData['scheduledAt'] =
                          Timestamp.fromDate(scheduledDate!);
                      updateData['status'] = 'scheduled';
                    }
                    try {
                      await FirebaseFirestore.instance
                          .collection('tournaments')
                          .doc(tournament.tournamentId)
                          .collection('matches')
                          .doc(doc.id)
                          .update(updateData);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Match updated.'),
                                backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red));
                      }
                    }
                  },
                  child: const Text('Save Changes',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon:
            Icon(icon, color: const Color(0xFF00BCD4), size: 20),
        filled: true,
        fillColor: const Color(0xFF0D0D1A),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _dateTimeBox(
      {required IconData icon,
      required String label,
      required bool hasValue}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00BCD4), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: hasValue ? Colors.white : Colors.white38,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMatch(BuildContext context, String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Delete Match',
            style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this match?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('tournaments')
            .doc(tournament.tournamentId)
            .collection('matches')
            .doc(docId)
            .delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Match deleted.'),
              backgroundColor: Colors.orange));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error deleting match: $e'),
              backgroundColor: Colors.red));
        }
      }
    }
  }
  bool _isWithinMatchWindow(DateTime scheduledAt) {
  final diff = DateTime.now().difference(scheduledAt).inMinutes;
  return diff >= -30 && diff <= 360;
}

void _onStartMatchTapped(BuildContext context, String matchDocId) async {
  final docSnap = await FirebaseFirestore.instance
      .collection('tournaments')
      .doc(tournament.tournamentId)
      .collection('matches')
      .doc(matchDocId)
      .get();

  if (!docSnap.exists) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Match not found.'),
        backgroundColor: Colors.red,
      ));
    }
    return;
  }

  final data = docSnap.data() as Map<String, dynamic>;
  final scheduledAt = (data['scheduledAt'] as Timestamp?)?.toDate();

  // If scheduled in the future (more than 30 min away), ask confirmation
  if (scheduledAt != null && context.mounted) {
    final diff = DateTime.now().difference(scheduledAt).inMinutes;
    if (diff < -30) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Start Early?',
              style: TextStyle(color: Colors.white)),
          content: Text(
            'This match is scheduled for ${scheduledAt.day}/${scheduledAt.month} '
            '${scheduledAt.hour}:${scheduledAt.minute.toString().padLeft(2, '0')}.\n\n'
            'Are you sure you want to start it now?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Start Anyway',
                  style: TextStyle(color: Color(0xFF00E676))),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
  }

  final t1Id   = (data['teamId1'] as String?) ?? '';
  final t2Id   = (data['teamId2'] as String?) ?? '';
  final t1Name = (data['teamId1Name'] as String?) ?? 'Team 1';
  final t2Name = (data['teamId2Name'] as String?) ?? 'Team 2';
  final overs  = (data['overs'] as int?) ?? 20;

  if (t1Id.isEmpty || t2Id.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Both teams must be assigned before starting.'),
        backgroundColor: Colors.orange,
      ));
    }
    return;
  }

if (!context.mounted) return;
 Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => InitialTeamPage(
      tournamentMatchDocId: matchDocId,
      tournamentId: tournament.tournamentId,
      prefilledTeamId1: t1Id,
      prefilledTeamId2: t2Id,
      prefilledTeamId1Name: t1Name,
      prefilledTeamId2Name: t2Name,
      prefilledOvers: overs,
    ),
  ),
);
}

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tournament.tournamentId)
          .collection('matches')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00BCD4)));
        }

        final docs = snap.data?.docs ?? [];
        final now = DateTime.now();

        final filtered = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final isCompleted = (data['isCompleted'] as bool?) ?? false;
          final scheduledAt =
              (data['scheduledAt'] as Timestamp?)?.toDate() ??
                  (data['createdAt'] as Timestamp?)?.toDate();

          if (filter == 'past') return isCompleted;
     if (filter == 'live') {
  if (isCompleted) return false;
  final status = (data['status'] as String?) ?? '';
  if (status == 'live') return true;  // explicit live flag
  if (scheduledAt == null) return false;
  final diff = now.difference(scheduledAt).inMinutes;
  return diff >= 0 && diff <= 360;
}
          return !isCompleted &&
              (scheduledAt == null || scheduledAt.isAfter(now));
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  filter == 'live'
                      ? Icons.sports_cricket
                      : filter == 'upcoming'
                          ? Icons.schedule
                          : Icons.history,
                  color: (filter == 'live'
                          ? Colors.green
                          : filter == 'upcoming'
                              ? const Color(0xFF00BCD4)
                              : Colors.grey)
                      .withOpacity(0.4),
                  size: 52,
                ),
                const SizedBox(height: 12),
                Text(
                  filter == 'live'
                      ? 'No live matches right now.'
                      : filter == 'upcoming'
                          ? 'No upcoming matches scheduled.'
                          : 'No past matches yet.',
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 14),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: const Text('Schedule Match'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeamPage(
                        tournamentId: tournament.tournamentId,
                        tournamentName: tournament.name,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filtered.length + 1,
          itemBuilder: (context, i) {
            if (i == filtered.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 20),
                child: Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Schedule Match'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeamPage(
                          tournamentId: tournament.tournamentId,
                          tournamentName: tournament.name,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            final doc = filtered[i];
            final data = doc.data() as Map<String, dynamic>;
            final team1Name = (data['teamId1Name'] as String?) ?? 'Team 1';
            final team2Name = (data['teamId2Name'] as String?) ?? 'Team 2';
            final overs = (data['overs'] as int?) ?? 0;
            final isCompleted = (data['isCompleted'] as bool?) ?? false;
            final scheduledAt =
                (data['scheduledAt'] as Timestamp?)?.toDate();
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            final matchFormatId = (data['format'] as String?) ?? '';
            final matchFormat = matchFormatId.isNotEmpty
                ? kFormats.firstWhere((f) => f.id == matchFormatId,
                    orElse: () => kFormats.first)
                : null;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF00BCD4).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('$team1Name  vs  $team2Name',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: isCompleted ? Colors.grey : Colors.green),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isCompleted ? 'Completed' : 'Scheduled',
                          style: TextStyle(
                              color: isCompleted ? Colors.grey : Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    // AFTER
if (_isCreator)
  PopupMenuButton<String>(
    color: const Color(0xFF1A1A2E),
    icon: const Icon(Icons.more_vert,
        color: Colors.white54, size: 20),
    onSelected: (value) {
      if (value == 'start')
        _onStartMatchTapped(context, doc.id);
      if (value == 'edit') _editMatch(context, doc);
      if (value == 'delete')
        _deleteMatch(context, doc.id);
    },
    itemBuilder: (_) => const [
      PopupMenuItem(
        value: 'start',
        child: Row(children: [
          Icon(Icons.play_arrow,
              color: Color(0xFF00E676), size: 18),
          SizedBox(width: 8),
          Text('Start Match',
              style: TextStyle(color: Colors.white)),
        ]),
      ),
      PopupMenuItem(
        value: 'edit',
        child: Row(children: [
          Icon(Icons.edit_outlined,
              color: Color(0xFF00BCD4), size: 18),
          SizedBox(width: 8),
          Text('Edit',
              style: TextStyle(color: Colors.white)),
        ]),
      ),
      PopupMenuItem(
        value: 'delete',
        child: Row(children: [
          Icon(Icons.delete_outline,
              color: Colors.red, size: 18),
          SizedBox(width: 8),
          Text('Delete',
              style: TextStyle(color: Colors.red)),
        ]),
      ),
    ],
  ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('$overs overs',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                  if (matchFormat != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(matchFormat.icon,
                            color: const Color(0xFF00BCD4), size: 12),
                        const SizedBox(width: 5),
                        Text(matchFormat.label,
                            style: const TextStyle(
                                color: Color(0xFF00BCD4), fontSize: 11)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month,
                          color: Colors.white38, size: 13),
                      const SizedBox(width: 5),
                      scheduledAt != null
                          ? Text(
                              'Match: ${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year}'
                              '  ${scheduledAt.hour}:${scheduledAt.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 11))
                          : const Text('Date/time not set — tap ⋮ to edit',
                              style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic)),
                    ],
                  ),
                  if (createdAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                          'Added: ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                          style: const TextStyle(
                              color: Colors.white24, fontSize: 10)),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LEADERBOARD TAB
// ═══════════════════════════════════════════════════════════════════════════

// REPLACE WITH:
class LeaderboardTab extends StatefulWidget {
  final Tournament tournament;
  const LeaderboardTab({super.key, required this.tournament});

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab>
    with SingleTickerProviderStateMixin {
  late TabController _lbTabController;
  final _tabs = const ['Batsmen', 'Bowlers'];

  @override
  void initState() {
    super.initState();
    _lbTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _lbTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
      Container(
  color: const Color(0xFF0D0D1A),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  child: AnimatedBuilder(
    animation: _lbTabController,
    builder: (_, __) {
      return Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF12122A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              alignment: Alignment(
                _lbTabController.index == 0 ? -1.0 : 1.0,
                0,
              ),
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00BCD4).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: List.generate(_tabs.length, (i) {
                final selected = _lbTabController.index == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _lbTabController.animateTo(i)),
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white38,
                          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                        child: Text(_tabs[i]),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    },
  ),
),
        Expanded(
          child: TabBarView(
            controller: _lbTabController,
            children: [
              _BatsmenLeaderboard(tournament: widget.tournament),
              _BowlersLeaderboard(tournament: widget.tournament),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaderboardHeader extends StatelessWidget {
  final String title;
  const _LeaderboardHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(title,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Color(0xFF00BCD4),
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// POINTS TABLE TAB
// ═══════════════════════════════════════════════════════════════════════════

class PointsTableTab extends StatelessWidget {
  final Tournament tournament;
  const PointsTableTab({super.key, required this.tournament});

  bool get _isKnockout => tournament.format == 'single_elimination';

  @override
  Widget build(BuildContext context) {
    if (_isKnockout) {
      return KnockoutStandingsTable(tournament: tournament);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('League Matches',
                style: TextStyle(color: Colors.white60, fontSize: 13)),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1A237E),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10)),
            ),
            child: const Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('Team',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold))),
                TableHeaderCell('M'),
                TableHeaderCell('W'),
                TableHeaderCell('L'),
                TableHeaderCell('T'),
                TableHeaderCell('NR'),
                TableHeaderCell('Pt.'),
                TableHeaderCell('NRR'),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10)),
            ),
            child: const Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('—',
                        style: TextStyle(
                            color: Colors.white38, fontSize: 12))),
                TableCell('0'),
                TableCell('0'),
                TableCell('0'),
                TableCell('0'),
                TableCell('0'),
                TableCell('0'),
                TableCell('0.00'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KnockoutTeamStat {
  final String name;
  int played = 0;
  int wins = 0;
  int losses = 0;
  _KnockoutTeamStat({required this.name});
}

class KnockoutStandingsTable extends StatelessWidget {
  final Tournament tournament;
  const KnockoutStandingsTable({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tournament.tournamentId)
          .collection('matches')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00BCD4)));
        }

        final docs = snap.data?.docs ?? [];
        final Map<String, _KnockoutTeamStat> stats = {};

        void ensureTeam(String id, String name) {
          if (id.isNotEmpty && name.isNotEmpty && name != 'TBD') {
            stats.putIfAbsent(id, () => _KnockoutTeamStat(name: name));
          }
        }

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final isBye = (data['isBye'] as bool?) ?? false;
          if (isBye) continue;

          final isCompleted = (data['isCompleted'] as bool?) ?? false;
          final t1Id = (data['teamId1'] as String?) ?? '';
          final t1Name = (data['teamId1Name'] as String?) ?? '';
          final t2Id = (data['teamId2'] as String?) ?? '';
          final t2Name = (data['teamId2Name'] as String?) ?? '';
          final winnerId = (data['winnerId'] as String?) ?? '';

          ensureTeam(t1Id, t1Name);
          ensureTeam(t2Id, t2Name);

          if (isCompleted && winnerId.isNotEmpty) {
            final loserId = (winnerId == t1Id) ? t2Id : t1Id;
            stats[winnerId]?.wins++;
            stats[loserId]?.losses++;
            stats[t1Id]?.played++;
            stats[t2Id]?.played++;
          }
        }

        final sorted = stats.entries.toList()
          ..sort((a, b) {
            final wCmp = b.value.wins.compareTo(a.value.wins);
            if (wCmp != 0) return wCmp;
            return a.value.losses.compareTo(b.value.losses);
          });

        if (sorted.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Standings will appear once matches are completed.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text('Knockout Standings',
                    style:
                        TextStyle(color: Colors.white60, fontSize: 13)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A237E),
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10)),
                ),
                child: const Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Text('Team',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold))),
                    TableHeaderCell('P'),
                    TableHeaderCell('W'),
                    TableHeaderCell('L'),
                    TableHeaderCell('Status'),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10)),
                ),
                child: Column(
                  children: sorted.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final teamStat = entry.value.value;
                    final isEliminated = teamStat.losses > 0;
                    final isChampion = teamStat.losses == 0 &&
                        teamStat.wins > 0 &&
                        idx == 0 &&
                        sorted.length > 1;

                    return Column(
                      children: [
                        if (idx > 0)
                          const Divider(color: Colors.white12, height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                child: Text('${idx + 1}',
                                    style: TextStyle(
                                        color: idx == 0
                                            ? const Color(0xFFFFB300)
                                            : Colors.white38,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    if (isChampion)
                                      const Icon(Icons.emoji_events,
                                          color: Color(0xFFFFB300),
                                          size: 14),
                                    if (isChampion)
                                      const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(teamStat.name,
                                          style: TextStyle(
                                            color: isEliminated
                                                ? Colors.white38
                                                : Colors.white,
                                            fontWeight: isChampion
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 13,
                                            decoration: isEliminated
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              ),
                              TableCell(teamStat.played.toString()),
                              TableCell(teamStat.wins.toString()),
                              TableCell(teamStat.losses.toString()),
                              Expanded(
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isEliminated
                                          ? Colors.red.withOpacity(0.1)
                                          : Colors.green.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isEliminated ? 'Out' : 'In',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isEliminated
                                            ? Colors.red
                                            : Colors.green,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '* Strikethrough = eliminated. In = still competing.',
                style: TextStyle(color: Colors.white24, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Shared Table Cells ────────────────────────────────────────────────────

class TableHeaderCell extends StatelessWidget {
  final String text;
  const TableHeaderCell(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      );
}

class TableCell extends StatelessWidget {
  final String text;
  const TableCell(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// LEADERBOARD & STATS HELPERS
// ═══════════════════════════════════════════════════════════════════════════

class _BatsmenLeaderboard extends StatefulWidget {
  final Tournament tournament;
  const _BatsmenLeaderboard({required this.tournament});

  @override
  State<_BatsmenLeaderboard> createState() => _BatsmenLeaderboardState();
}

class _BatsmenLeaderboardState extends State<_BatsmenLeaderboard> {
  bool _loading = true;
  List<MapEntry<String, Map<String, dynamic>>> _byRuns = [];
  List<MapEntry<String, Map<String, dynamic>>> _byHighScore = [];
  List<MapEntry<String, Map<String, dynamic>>> _bySR = [];

  // ── Helper: detect UUID ──────────────────────────────────────────
  // REPLACE WITH:
bool _looksLikeUUID(String s) =>
    s.length > 15 && (s.contains('-') || RegExp(r'^[a-f0-9]{20,}$').hasMatch(s));

  // ── Helper: resolve player name with 3-tier fallback ────────────
 // REPLACE WITH:
Future<String> _resolvePlayerName(
    String playerId, String storedName, {String? matchDocId}) async {
  // Tier 1: stored name is already a real human name
  if (storedName.isNotEmpty && !_looksLikeUUID(storedName)) {
    return storedName;
  }

  // Tier 2: TeamMember in-memory cache
  final cached = TeamMember.getByPlayerId(playerId);
  if (cached != null) {
    final name = cached.playerName;
    if (name.isNotEmpty && !_looksLikeUUID(name)) return name;
    final alt = cached.teamName;
    if (alt.isNotEmpty && !_looksLikeUUID(alt)) return alt;
  }

  // Tier 3: Firestore collectionGroup 'players'
  try {
    final snap = await FirebaseFirestore.instance
        .collectionGroup('players')
        .where('playerId', isEqualTo: playerId)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data();
      for (final field in ['playerName', 'name', 'displayName', 'userName']) {
        final val = (data[field] as String?) ?? '';
        if (val.isNotEmpty && !_looksLikeUUID(val)) return val;
      }
    }
  } catch (_) {}

  // Tier 4: Firestore collectionGroup 'members'
  try {
    final snap = await FirebaseFirestore.instance
        .collectionGroup('members')
        .where('playerId', isEqualTo: playerId)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data();
      for (final field in ['playerName', 'name', 'displayName']) {
        final val = (data[field] as String?) ?? '';
        if (val.isNotEmpty && !_looksLikeUUID(val)) return val;
      }
    }
  } catch (_) {}

  // Tier 5: Search ALL users collection for this playerId (Firebase Auth uid match)
  try {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(playerId)
        .get();
    if (snap.exists) {
      final data = snap.data() ?? {};
      for (final field in ['displayName', 'name', 'playerName', 'userName']) {
        final val = (data[field] as String?) ?? '';
        if (val.isNotEmpty && !_looksLikeUUID(val)) return val;
      }
    }
  } catch (_) {}

  // Tier 6: Search teamMembers collection group by uid field
  try {
    final snap = await FirebaseFirestore.instance
        .collectionGroup('players')
        .where('uid', isEqualTo: playerId)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data();
      for (final field in ['playerName', 'name', 'displayName']) {
        final val = (data[field] as String?) ?? '';
        if (val.isNotEmpty && !_looksLikeUUID(val)) return val;
      }
    }
  } catch (_) {}

  // Final fallback: shorten UUID for cleaner display
  if (_looksLikeUUID(playerId)) {
    return 'Player #${playerId.substring(0, 6)}';
  }
  return storedName.isNotEmpty ? storedName : playerId;
}

  @override
  void initState() {
    super.initState();
    _load();
  }
  /// Picks the best non-UUID name from a Firestore document map.
String _pickBestName(Map<String, dynamic> data) {
  for (final field in ['playerName', 'name', 'displayName', 'userName']) {
    final val = (data[field] as String?) ?? '';
    if (val.isNotEmpty && !_looksLikeUUID(val)) return val;
  }
  return '';
}


  Future<void> _load() async {
  try {
    final db = FirebaseFirestore.instance;
    final matchesSnap = await db
        .collection('tournaments')
        .doc(widget.tournament.tournamentId)
        .collection('matches')
        .get();

    // ── Pre-build a playerId → name cache from all team rosters ──
    final Map<String, String> rosterCache = {};
    try {
      final teamsSnap = await db
          .collection('tournaments')
          .doc(widget.tournament.tournamentId)
          .collection('teams')
          .get();
      for (final teamDoc in teamsSnap.docs) {
        final teamId = teamDoc['teamId'] as String? ?? '';
        if (teamId.isEmpty) continue;
        // Try subcollection 'players' under the team
        try {
          final playersSnap = await db
              .collection('teams')
              .doc(teamId)
              .collection('players')
              .get();
          for (final p in playersSnap.docs) {
            final pid = (p.data()['playerId'] as String?) ??
                (p.data()['uid'] as String?) ?? '';
            if (pid.isEmpty) continue;
            for (final field in ['playerName', 'name', 'displayName']) {
              final val = (p.data()[field] as String?) ?? '';
              if (val.isNotEmpty && !_looksLikeUUID(val)) {
                rosterCache[pid] = val;
                break;
              }
            }
          }
        } catch (_) {}
      }
    } catch (_) {}

    final Map<String, Map<String, dynamic>> playerStats = {};

    for (final matchDoc in matchesSnap.docs) {
      final inningsSnap =
          await matchDoc.reference.collection('innings').get();
      for (final inningsDoc in inningsSnap.docs) {
        final batsmenSnap =
            await inningsDoc.reference.collection('batsmen').get();
        for (final d in batsmenSnap.docs) {
          final b = d.data();
          final playerId = (b['playerId'] as String?) ?? '';
          // Use roster cache first, then _pickBestName
          final storedName = rosterCache[playerId] ?? _pickBestName(b);
          final runs = (b['runs'] as num?)?.toInt() ?? 0;
          final balls = (b['ballsFaced'] as num?)?.toInt() ?? 0;
          final fours = (b['fours'] as num?)?.toInt() ?? 0;
          final sixes = (b['sixes'] as num?)?.toInt() ?? 0;
          if (playerId.isEmpty) continue;

          if (!playerStats.containsKey(playerId)) {
            playerStats[playerId] = {
              'name': storedName,
              'totalRuns': 0,
              'totalBalls': 0,
              'totalFours': 0,
              'totalSixes': 0,
              'highScore': 0,
              'highScoreBalls': 0,
              'innings': 0,
            };
          }

          final existing = playerStats[playerId]!;
          existing['totalRuns'] = (existing['totalRuns'] as int) + runs;
          existing['totalBalls'] = (existing['totalBalls'] as int) + balls;
          existing['totalFours'] = (existing['totalFours'] as int) + fours;
          existing['totalSixes'] = (existing['totalSixes'] as int) + sixes;
          existing['innings'] = (existing['innings'] as int) + 1;
          if (runs > (existing['highScore'] as int)) {
            existing['highScore'] = runs;
            existing['highScoreBalls'] = balls;
          }
          // Upgrade name if roster cache has better value
          if (_looksLikeUUID(existing['name'] as String) &&
              storedName.isNotEmpty &&
              !_looksLikeUUID(storedName)) {
            existing['name'] = storedName;
          }
        }
      }
    }

    // ── Resolve remaining unresolved names ──────────────────────
    for (final entry in playerStats.entries) {
      if (_looksLikeUUID(entry.value['name'] as String) ||
          (entry.value['name'] as String).isEmpty) {
        entry.value['name'] =
            await _resolvePlayerName(entry.key, entry.value['name'] as String);
      }
    }

    // Compute strike rate
    for (final stat in playerStats.values) {
      final balls = stat['totalBalls'] as int;
      final runs = stat['totalRuns'] as int;
      stat['strikeRate'] = balls > 0 ? (runs / balls * 100) : 0.0;
    }

    final entries = playerStats.entries.toList();

    final byRuns = List.of(entries)
      ..sort((a, b) => (b.value['totalRuns'] as int)
          .compareTo(a.value['totalRuns'] as int));

    final byHighScore = List.of(entries)
      ..sort((a, b) => (b.value['highScore'] as int)
          .compareTo(a.value['highScore'] as int));

    final bySR = entries
        .where((e) => (e.value['totalBalls'] as int) >= 6)
        .toList()
      ..sort((a, b) => (b.value['strikeRate'] as double)
          .compareTo(a.value['strikeRate'] as double));

    if (mounted) {
      setState(() {
        _byRuns = byRuns;
        _byHighScore = byHighScore;
        _bySR = bySR;
        _loading = false;
      });
    }
  } catch (e) {
    if (mounted) setState(() => _loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF00BCD4)));
    }
    if (_byRuns.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No batting data yet.',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
      children: [
        _buildBattingSection(
          title: '🏏 Most Runs',
          subtitle: 'Total runs across all matches',
          entries: _byRuns.take(5).toList(),
          valueBuilder: (s) => '${s['totalRuns']} runs',
          subValueBuilder: (s) {
            final balls = s['totalBalls'] as int;
            final sr = s['strikeRate'] as double;
            return '${s['innings']} inn • $balls balls • SR ${sr.toStringAsFixed(1)}';
          },
          highlightColor: const Color(0xFFFFB300),
        ),
        const SizedBox(height: 16),
        _buildBattingSection(
          title: '⭐ Highest Score',
          subtitle: 'Best individual innings score',
          entries: _byHighScore.take(5).toList(),
          valueBuilder: (s) => '${s['highScore']}*',
          subValueBuilder: (s) => '${s['highScoreBalls']} balls',
          highlightColor: const Color(0xFF00BCD4),
        ),
        const SizedBox(height: 16),
        _buildBattingSection(
          title: '⚡ Best Strike Rate',
          subtitle: 'Min. 6 balls faced',
          entries: _bySR.take(5).toList(),
          valueBuilder: (s) =>
              (s['strikeRate'] as double).toStringAsFixed(1),
          subValueBuilder: (s) =>
              '${s['totalRuns']} runs • ${s['totalBalls']} balls',
          highlightColor: const Color(0xFF4CAF50),
        ),
      ],
    );
  }

  Widget _buildBattingSection({
    required String title,
    required String subtitle,
    required List<MapEntry<String, Map<String, dynamic>>> entries,
    required String Function(Map<String, dynamic>) valueBuilder,
    required String Function(Map<String, dynamic>) subValueBuilder,
    required Color highlightColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF1A237E),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: const Color(0xFF1A1A2E),
          child: Row(
            children: const [
              SizedBox(width: 24),
              Expanded(
                flex: 3,
                child: Text('Player',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                width: 80,
                child: Text('Value',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
          child: Column(
            children: entries.asMap().entries.map((entry) {
              final idx = entry.key;
              final stat = entry.value.value;
              final name = stat['name'] as String;
              final displayName =
                  name.length > 30 ? '${name.substring(0, 12)}...' : name;

              return Column(
                children: [
                  if (idx > 0)
                    const Divider(color: Colors.white12, height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Text('${idx + 1}',
                              style: TextStyle(
                                  color: idx == 0
                                      ? highlightColor
                                      : Colors.white38,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(displayName,
                                  style: TextStyle(
                                      color: idx == 0
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 13,
                                      fontWeight: idx == 0
                                          ? FontWeight.bold
                                          : FontWeight.normal),
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(subValueBuilder(stat),
                                  style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(valueBuilder(stat),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: idx == 0
                                      ? highlightColor
                                      : Colors.white54,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _BowlersLeaderboard extends StatefulWidget {
  final Tournament tournament;
  const _BowlersLeaderboard({required this.tournament});

  @override
  State<_BowlersLeaderboard> createState() => _BowlersLeaderboardState();
}

class _BowlersLeaderboardState extends State<_BowlersLeaderboard> {
  bool _loading = true;
  List<MapEntry<String, Map<String, dynamic>>> _byWickets = [];
  List<MapEntry<String, Map<String, dynamic>>> _byFigures = [];
  List<MapEntry<String, Map<String, dynamic>>> _byEconomy = [];

  // ── Helper: detect UUID ──────────────────────────────────────────
bool _looksLikeUUID(String s) =>
    s.length > 15 && (s.contains('-') || RegExp(r'^[a-f0-9]{20,}$').hasMatch(s));

  // ── Helper: resolve player name with 3-tier fallback ────────────
  // REPLACE WITH:
Future<String> _resolvePlayerName(
    String playerId, String storedName) async {
  // Tier 1: stored name is already a real human name
  if (storedName.isNotEmpty && !_looksLikeUUID(storedName)) {
    return storedName;
  }
  // Tier 2: TeamMember in-memory cache
  final cached = TeamMember.getByPlayerId(playerId);
  if (cached != null) {
    final name = cached.playerName;
    if (name.isNotEmpty && !_looksLikeUUID(name)) return name;
    final alt = cached.teamName;
    if (alt.isNotEmpty && !_looksLikeUUID(alt)) return alt;
  }
  // Tier 3: Firestore collectionGroup 'players'
  try {
    final snap = await FirebaseFirestore.instance
        .collectionGroup('players')
        .where('playerId', isEqualTo: playerId)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data();
      for (final field in ['playerName', 'name', 'displayName', 'userName']) {
        final val = (data[field] as String?) ?? '';
        if (val.isNotEmpty && !_looksLikeUUID(val)) return val;
      }
    }
  } catch (_) {}
  // Tier 4: Firestore collectionGroup 'members' fallback
  try {
    final snap = await FirebaseFirestore.instance
        .collectionGroup('members')
        .where('playerId', isEqualTo: playerId)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data();
      for (final field in ['playerName', 'name', 'displayName']) {
        final val = (data[field] as String?) ?? '';
        if (val.isNotEmpty && !_looksLikeUUID(val)) return val;
      }
    }
  } catch (_) {}
  // Final fallback: shorten UUID for cleaner display
  if (_looksLikeUUID(playerId)) {
    return 'Player #${playerId.substring(0, 6)}';
  }
  return storedName.isNotEmpty ? storedName : playerId;
}
  @override
  void initState() {
    super.initState();
    _load();
  }
  /// Picks the best non-UUID name from a Firestore document map.
String _pickBestName(Map<String, dynamic> data) {
  for (final field in ['playerName', 'name', 'displayName', 'userName']) {
    final val = (data[field] as String?) ?? '';
    if (val.isNotEmpty && !_looksLikeUUID(val)) return val;
  }
  return '';
}
 Future<void> _load() async {
  try {
    final db = FirebaseFirestore.instance;
    final matchesSnap = await db
        .collection('tournaments')
        .doc(widget.tournament.tournamentId)
        .collection('matches')
        .get();

    // ── Pre-build a playerId → name cache from all team rosters ──
    final Map<String, String> rosterCache = {};
    try {
      final teamsSnap = await db
          .collection('tournaments')
          .doc(widget.tournament.tournamentId)
          .collection('teams')
          .get();
      for (final teamDoc in teamsSnap.docs) {
        final teamId = teamDoc['teamId'] as String? ?? '';
        if (teamId.isEmpty) continue;
        try {
          final playersSnap = await db
              .collection('teams')
              .doc(teamId)
              .collection('players')
              .get();
          for (final p in playersSnap.docs) {
            final pid = (p.data()['playerId'] as String?) ??
                (p.data()['uid'] as String?) ?? '';
            if (pid.isEmpty) continue;
            for (final field in ['playerName', 'name', 'displayName']) {
              final val = (p.data()[field] as String?) ?? '';
              if (val.isNotEmpty && !_looksLikeUUID(val)) {
                rosterCache[pid] = val;
                break;
              }
            }
          }
        } catch (_) {}
      }
    } catch (_) {}

    final Map<String, Map<String, dynamic>> playerStats = {};

    for (final matchDoc in matchesSnap.docs) {
      final inningsSnap =
          await matchDoc.reference.collection('innings').get();
      for (final inningsDoc in inningsSnap.docs) {
        final bowlersSnap =
            await inningsDoc.reference.collection('bowlers').get();
        for (final d in bowlersSnap.docs) {
          final b = d.data();
          final playerId = (b['playerId'] as String?) ?? '';
          // Use roster cache first, then _pickBestName
          final storedName = rosterCache[playerId] ?? _pickBestName(b);
          final wickets = (b['wickets'] as num?)?.toInt() ?? 0;
          final runs = (b['runsConceded'] as num?)?.toInt() ?? 0;
          final balls = (b['balls'] as num?)?.toInt() ?? 0;
          final maidens = (b['maidens'] as num?)?.toInt() ?? 0;
          if (playerId.isEmpty) continue;

          if (!playerStats.containsKey(playerId)) {
            playerStats[playerId] = {
              'name': storedName,
              'totalWickets': 0,
              'totalRuns': 0,
              'totalBalls': 0,
              'totalMaidens': 0,
              'bestWickets': 0,
              'bestRuns': 999,
              'innings': 0,
            };
          }

          final existing = playerStats[playerId]!;
          existing['totalWickets'] =
              (existing['totalWickets'] as int) + wickets;
          existing['totalRuns'] = (existing['totalRuns'] as int) + runs;
          existing['totalBalls'] = (existing['totalBalls'] as int) + balls;
          existing['totalMaidens'] =
              (existing['totalMaidens'] as int) + maidens;
          existing['innings'] = (existing['innings'] as int) + 1;

          final bestW = existing['bestWickets'] as int;
          final bestR = existing['bestRuns'] as int;
          if (wickets > bestW || (wickets == bestW && runs < bestR)) {
            existing['bestWickets'] = wickets;
            existing['bestRuns'] = runs;
          }

          if (_looksLikeUUID(existing['name'] as String) &&
              storedName.isNotEmpty &&
              !_looksLikeUUID(storedName)) {
            existing['name'] = storedName;
          }
        }
      }
    }

    // ── Resolve remaining unresolved names ──────────────────────
    for (final entry in playerStats.entries) {
      if (_looksLikeUUID(entry.value['name'] as String) ||
          (entry.value['name'] as String).isEmpty) {
        entry.value['name'] =
            await _resolvePlayerName(entry.key, entry.value['name'] as String);
      }
    }

    // Compute economy & overs string
    for (final stat in playerStats.values) {
      final balls = stat['totalBalls'] as int;
      final runs = stat['totalRuns'] as int;
      final completedOvers = balls ~/ 6;
      final remBalls = balls % 6;
      final totalOvers = completedOvers + (remBalls / 6.0);
      stat['economy'] = totalOvers > 0 ? runs / totalOvers : 0.0;
      stat['overs'] =
          '$completedOvers${remBalls > 0 ? '.$remBalls' : ''}';
    }

    final entries = playerStats.entries.toList();

    final byWickets = List.of(entries)
      ..sort((a, b) {
        final wCmp = (b.value['totalWickets'] as int)
            .compareTo(a.value['totalWickets'] as int);
        if (wCmp != 0) return wCmp;
        return (a.value['totalRuns'] as int)
            .compareTo(b.value['totalRuns'] as int);
      });

    final byFigures = List.of(entries)
      ..sort((a, b) {
        final wCmp = (b.value['bestWickets'] as int)
            .compareTo(a.value['bestWickets'] as int);
        if (wCmp != 0) return wCmp;
        return (a.value['bestRuns'] as int)
            .compareTo(b.value['bestRuns'] as int);
      });

    final byEconomy = entries
        .where((e) => (e.value['totalBalls'] as int) >= 6)
        .toList()
      ..sort((a, b) => (a.value['economy'] as double)
          .compareTo(b.value['economy'] as double));

    if (mounted) {
      setState(() {
        _byWickets = byWickets;
        _byFigures = byFigures;
        _byEconomy = byEconomy;
        _loading = false;
      });
    }
  } catch (e) {
    if (mounted) setState(() => _loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF00BCD4)));
    }
    if (_byWickets.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No bowling data yet.',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
      children: [
        _buildBowlingSection(
          title: '🎯 Most Wickets',
          subtitle: 'Total wickets across all matches',
          entries: _byWickets.take(5).toList(),
          valueBuilder: (s) => '${s['totalWickets']} wkts',
          subValueBuilder: (s) {
            final eco = (s['economy'] as double).toStringAsFixed(2);
            return '${s['overs']} ov • ${s['totalRuns']} runs • Eco $eco';
          },
          highlightColor: const Color(0xFFFFB300),
        ),
        const SizedBox(height: 16),
        _buildBowlingSection(
          title: '📊 Best Bowling Figures',
          subtitle: 'Best wickets/runs in a single spell',
          entries: _byFigures.take(5).toList(),
          valueBuilder: (s) => '${s['bestWickets']}/${s['bestRuns']}',
          subValueBuilder: (s) => '${s['totalWickets']} total wkts',
          highlightColor: const Color(0xFF00BCD4),
        ),
        const SizedBox(height: 16),
        _buildBowlingSection(
          title: '💚 Best Economy Rate',
          subtitle: 'Min. 1 over bowled',
          entries: _byEconomy.take(5).toList(),
          valueBuilder: (s) =>
              (s['economy'] as double).toStringAsFixed(2),
          subValueBuilder: (s) =>
              '${s['overs']} ov • ${s['totalWickets']} wkts • ${s['totalMaidens']} maidens',
          highlightColor: const Color(0xFF4CAF50),
        ),
      ],
    );
  }

  Widget _buildBowlingSection({
    required String title,
    required String subtitle,
    required List<MapEntry<String, Map<String, dynamic>>> entries,
    required String Function(Map<String, dynamic>) valueBuilder,
    required String Function(Map<String, dynamic>) subValueBuilder,
    required Color highlightColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF1A237E),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: const Color(0xFF1A1A2E),
          child: Row(
            children: const [
              SizedBox(width: 24),
              Expanded(
                flex: 3,
                child: Text('Player',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                width: 80,
                child: Text('Value',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
          child: Column(
            children: entries.asMap().entries.map((entry) {
              final idx = entry.key;
              final stat = entry.value.value;
              final name = stat['name'] as String;
              final displayName =
                  name.length > 30 ? '${name.substring(0, 12)}...' : name;

              return Column(
                children: [
                  if (idx > 0)
                    const Divider(color: Colors.white12, height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Text('${idx + 1}',
                              style: TextStyle(
                                  color: idx == 0
                                      ? highlightColor
                                      : Colors.white38,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(displayName,
                                  style: TextStyle(
                                      color: idx == 0
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 13,
                                      fontWeight: idx == 0
                                          ? FontWeight.bold
                                          : FontWeight.normal),
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(subValueBuilder(stat),
                                  style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(valueBuilder(stat),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: idx == 0
                                      ? highlightColor
                                      : Colors.white54,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS TAB — intentionally empty
// ─────────────────────────────────────────────────────────────────────────────

// ═══════════════════════════════════════════════════════════════════════════
// STATS TAB  —  Live / Upcoming / Past
// ═══════════════════════════════════════════════════════════════════════════

class StatsTab extends StatefulWidget {
  final Tournament tournament;
  const StatsTab({super.key, required this.tournament});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab>
    with SingleTickerProviderStateMixin {
  late TabController _statsTabController;
  final List<String> _tabs = ['Live', 'Upcoming', 'Past'];

  @override
  void initState() {
    super.initState();
    _statsTabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _statsTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
       Container(
  color: const Color(0xFF0D0D1A),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  child: AnimatedBuilder(
    animation: _statsTabController,
    builder: (_, __) {
      final List<Color> tabColors = [
        Colors.green,
        const Color(0xFF00BCD4),
        Colors.grey,
      ];
      final selectedColor = tabColors[_statsTabController.index];

      return Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF12122A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              alignment: Alignment(
                -1.0 + (_statsTabController.index * (2 / (_tabs.length - 1))),
                0,
              ),
              child: FractionallySizedBox(
                widthFactor: 1 / _tabs.length,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        selectedColor,
                        selectedColor.withOpacity(0.65),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: selectedColor.withOpacity(0.45),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: List.generate(_tabs.length, (i) {
                final selected = _statsTabController.index == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _statsTabController.animateTo(i)),
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (i == 0 && selected)
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 220),
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.white38,
                              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                            ),
                            child: Text(_tabs[i]),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    },
  ),
),
        Expanded(
          child: TabBarView(
            controller: _statsTabController,
            children: [
              _LiveStatsView(tournament: widget.tournament),
              _UpcomingStatsView(tournament: widget.tournament),
              _PastStatsView(tournament: widget.tournament),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Live Stats View ───────────────────────────────────────────────────────

class _LiveStatsView extends StatelessWidget {
  final Tournament tournament;
  const _LiveStatsView({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tournament.tournamentId)
          .collection('matches')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00BCD4)));
        }

        final now = DateTime.now();
     final docs = (snap.data?.docs ?? []).where((doc) {
  final data = doc.data() as Map<String, dynamic>;
  final isCompleted = (data['isCompleted'] as bool?) ?? false;
  if (isCompleted) return false;
  final status = (data['status'] as String?) ?? '';
  if (status == 'live') return true;
  final scheduledAt = (data['scheduledAt'] as Timestamp?)?.toDate();
  if (scheduledAt == null) return false;
  final diff = now.difference(scheduledAt).inMinutes;
  return diff >= 0 && diff <= 360;
}).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sports_cricket,
                    color: Colors.green.withOpacity(0.3), size: 52),
                const SizedBox(height: 12),
                const Text('No live matches right now.',
                    style: TextStyle(color: Colors.white38, fontSize: 14)),
                const SizedBox(height: 6),
                const Text('Live scores will appear here during a match.',
                    style: TextStyle(color: Colors.white24, fontSize: 12)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) =>
              _LiveScoreCard(doc: docs[i], tournament: tournament),
        );
      },
    );
  }
}

class _LiveScoreCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final Tournament tournament;
  const _LiveScoreCard({required this.doc, required this.tournament});

  @override
  Widget build(BuildContext context) {
    final matchId = doc.id;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tournament.tournamentId)
          .collection('matches')
          .doc(matchId)
          .collection('innings')
          .snapshots(),
      builder: (context, inningsSnap) {
        final data = doc.data() as Map<String, dynamic>;
        final team1Name = (data['teamId1Name'] as String?) ?? 'Team 1';
        final team2Name = (data['teamId2Name'] as String?) ?? 'Team 2';
        final overs = (data['overs'] as int?) ?? 20;
        final scheduledAt = (data['scheduledAt'] as Timestamp?)?.toDate();

        final inningsDocs = inningsSnap.data?.docs ?? [];

        // Parse innings data
        Map<String, dynamic>? inn1Data;
        Map<String, dynamic>? inn2Data;
        for (final d in inningsDocs) {
          final idata = d.data() as Map<String, dynamic>;
          final no = (idata['inningsNumber'] as int?) ?? 1;
          if (no == 1) inn1Data = idata;
          if (no == 2) inn2Data = idata;
        }

        final inn1Runs = (inn1Data?['totalRuns'] as num?)?.toInt() ?? 0;
        final inn1Wickets = (inn1Data?['wickets'] as num?)?.toInt() ?? 0;
        final inn1Balls = (inn1Data?['ballsBowled'] as num?)?.toInt() ?? 0;
        final inn1BattingTeam = (inn1Data?['battingTeamName'] as String?) ?? team1Name;

        final inn2Runs = (inn2Data?['totalRuns'] as num?)?.toInt() ?? 0;
        final inn2Wickets = (inn2Data?['wickets'] as num?)?.toInt() ?? 0;
        final inn2Balls = (inn2Data?['ballsBowled'] as num?)?.toInt() ?? 0;

        String _oversStr(int balls) {
          final o = balls ~/ 6;
          final b = balls % 6;
          return b > 0 ? '$o.$b' : '$o';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.green.withOpacity(0.5), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Live header ────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: Colors.green, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    const Text('LIVE',
                        style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1)),
                    const Spacer(),
                    Text('$overs ov match',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                    if (scheduledAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${scheduledAt.hour}:${scheduledAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Innings 1 ─────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(inn1BattingTeam,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ),
                        if (inn1Data != null)
                          Text(
                            '$inn1Runs/$inn1Wickets',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22),
                          ),
                        if (inn1Data == null)
                          const Text('Yet to bat',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 13)),
                      ],
                    ),
                    if (inn1Data != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '(${_oversStr(inn1Balls)}/$overs ov)',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 8),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 8),
                    // ── Innings 2 ──────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            inn1BattingTeam == team1Name
                                ? team2Name
                                : team1Name,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 15),
                          ),
                        ),
                        if (inn2Data != null)
                          Text(
                            '$inn2Runs/$inn2Wickets',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22),
                          ),
                        if (inn2Data == null)
                          const Text('Yet to bat',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 13)),
                      ],
                    ),
                    if (inn2Data != null) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '(${_oversStr(inn2Balls)}/$overs ov)',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      ),
                      // Required runs indicator
                      if (inn1Data != null) ...[
                        const SizedBox(height: 6),
                        Builder(builder: (_) {
                          final target = inn1Runs + 1;
                          final runsNeeded = target - inn2Runs;
                          final ballsLeft =
                              (overs * 6) - inn2Balls;
                          if (runsNeeded > 0 && ballsLeft > 0) {
                            final rr = (runsNeeded / ballsLeft * 6)
                                .toStringAsFixed(2);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Text(
                                '$runsNeeded runs needed from $ballsLeft balls • RRR $rr',
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Upcoming Stats View ───────────────────────────────────────────────────

class _UpcomingStatsView extends StatelessWidget {
  final Tournament tournament;
  const _UpcomingStatsView({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tournament.tournamentId)
          .collection('matches')
          .orderBy('scheduledAt')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00BCD4)));
        }

        final now = DateTime.now();
        final docs = (snap.data?.docs ?? []).where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final isCompleted = (data['isCompleted'] as bool?) ?? false;
          if (isCompleted) return false;
          final scheduledAt = (data['scheduledAt'] as Timestamp?)?.toDate();
          if (scheduledAt == null) return true; // unscheduled = upcoming
          return scheduledAt.isAfter(now);
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule,
                    color: const Color(0xFF00BCD4).withOpacity(0.3),
                    size: 52),
                const SizedBox(height: 12),
                const Text('No upcoming matches.',
                    style: TextStyle(color: Colors.white38, fontSize: 14)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final team1Name =
                (data['teamId1Name'] as String?) ?? 'Team 1';
            final team2Name =
                (data['teamId2Name'] as String?) ?? 'Team 2';
            final overs = (data['overs'] as int?) ?? 20;
            final scheduledAt =
                (data['scheduledAt'] as Timestamp?)?.toDate();
            final roundName =
                (data['roundName'] as String?) ?? 'Match ${i + 1}';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF00BCD4).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  // Date block
                  Container(
                    width: 48,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: scheduledAt != null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                scheduledAt.day.toString(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18),
                              ),
                              Text(
                                _monthShort(scheduledAt.month),
                                style: const TextStyle(
                                    color: Color(0xFF00BCD4),
                                    fontSize: 11),
                              ),
                            ],
                          )
                        : const Icon(Icons.calendar_today,
                            color: Colors.white38, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$team1Name  vs  $team2Name',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        const SizedBox(height: 3),
                        Text(
                          scheduledAt != null
                              ? '${scheduledAt.hour}:${scheduledAt.minute.toString().padLeft(2, '0')}  •  $overs overs  •  $roundName'
                              : '$overs overs  •  $roundName  •  Date TBD',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xFF00BCD4).withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Upcoming',
                        style: TextStyle(
                            color: Color(0xFF00BCD4),
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _monthShort(int m) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m];
  }
}

// ─── Past Stats View ───────────────────────────────────────────────────────

class _PastStatsView extends StatelessWidget {
  final Tournament tournament;
  const _PastStatsView({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tournament.tournamentId)
          .collection('matches')
          .where('isCompleted', isEqualTo: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00BCD4)));
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history,
                    color: Colors.grey.withOpacity(0.3), size: 52),
                const SizedBox(height: 12),
                const Text('No completed matches yet.',
                    style: TextStyle(color: Colors.white38, fontSize: 14)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) =>
              _PastMatchCard(doc: docs[i], tournament: tournament),
        );
      },
    );
  }
}

class _PastMatchCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final Tournament tournament;
  const _PastMatchCard({required this.doc, required this.tournament});

  @override
  State<_PastMatchCard> createState() => _PastMatchCardState();
}

class _PastMatchCardState extends State<_PastMatchCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final team1Name = (data['teamId1Name'] as String?) ?? 'Team 1';
    final team2Name = (data['teamId2Name'] as String?) ?? 'Team 2';
    final winnerName = (data['winnerName'] as String?) ?? '';
    final overs = (data['overs'] as int?) ?? 20;
    final scheduledAt = (data['scheduledAt'] as Timestamp?)?.toDate();
    final roundName = (data['roundName'] as String?) ?? 'Match';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // ── Summary row ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_events,
                        color: Color(0xFFFFB300), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        winnerName.isNotEmpty
                            ? '$winnerName won'
                            : 'Match completed',
                        style: const TextStyle(
                            color: Color(0xFFFFB300),
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.grey.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Completed',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('$team1Name  vs  $team2Name',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 3),
                Text(
                  scheduledAt != null
                      ? '${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year}  •  $overs overs  •  $roundName'
                      : '$overs overs  •  $roundName',
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Row(
                    children: [
                      Text(
                        _expanded ? 'Hide scorecard' : 'View scorecard',
                        style: const TextStyle(
                            color: Color(0xFF00BCD4),
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: const Color(0xFF00BCD4),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Expanded scorecard ────────────────────────────────────────
          if (_expanded)
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('tournaments')
                  .doc(widget.tournament.tournamentId)
                  .collection('matches')
                  .doc(widget.doc.id)
                  .collection('innings')
                  .get(),
              builder: (context, inningsSnap) {
                if (inningsSnap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF00BCD4), strokeWidth: 2)),
                  );
                }

                final inningsDocs = inningsSnap.data?.docs ?? [];
                if (inningsDocs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Center(
                      child: Text('No innings data available.',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 12)),
                    ),
                  );
                }

                return Column(
                  children: inningsDocs.map((inningsDoc) {
                    final idata = inningsDoc.data() as Map<String, dynamic>;
                    final inningsNum =
                        (idata['inningsNumber'] as int?) ?? 1;
                    final battingTeam =
                        (idata['battingTeamName'] as String?) ??
                            'Team $inningsNum';
                    final totalRuns =
                        (idata['totalRuns'] as num?)?.toInt() ?? 0;
                    final wickets =
                        (idata['wickets'] as num?)?.toInt() ?? 0;
                    final ballsBowled =
                        (idata['ballsBowled'] as num?)?.toInt() ?? 0;
                    final completedOvers = ballsBowled ~/ 6;
                    final remBalls = ballsBowled % 6;
                    final oversStr = remBalls > 0
                        ? '$completedOvers.$remBalls'
                        : '$completedOvers';

                    return FutureBuilder<List<QuerySnapshot>>(
                      future: Future.wait([
                        inningsDoc.reference.collection('batsmen').get(),
                        inningsDoc.reference.collection('bowlers').get(),
                      ]),
                      builder: (context, playerSnap) {
                        final batsmenDocs =
                            playerSnap.data?[0].docs ?? [];
                        final bowlerDocs =
                            playerSnap.data?[1].docs ?? [];

                        return Container(
                          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D0D1A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Innings header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1A237E),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '$battingTeam  —  Innings $inningsNum',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '$totalRuns/$wickets  ($oversStr ov)',
                                      style: const TextStyle(
                                          color: Color(0xFF00BCD4),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),

                              // Batting table
                              if (batsmenDocs.isNotEmpty) ...[
                                _scorecardSectionHeader(
                                    'Batting', 'R', 'B', 'SR'),
                                ...batsmenDocs.map((d) {
                                  final b =
                                      d.data() as Map<String, dynamic>;
                                  final name =
                                      (b['playerName'] as String?) ??
                                          (b['name'] as String?) ??
                                          'Player';
                                  final runs =
                                      (b['runs'] as num?)?.toInt() ?? 0;
                                  final balls =
                                      (b['ballsFaced'] as num?)
                                              ?.toInt() ??
                                          0;
                                  final sr = balls > 0
                                      ? (runs / balls * 100)
                                          .toStringAsFixed(1)
                                      : '0.0';
                                  final fours =
                                      (b['fours'] as num?)?.toInt() ?? 0;
                                  final sixes =
                                      (b['sixes'] as num?)?.toInt() ?? 0;
                                  final dismissal =
                                      (b['dismissalType'] as String?) ??
                                          '';

                                  return _ScorecardRow(
                                    name: name,
                                    sub: dismissal.isNotEmpty
                                        ? dismissal
                                        : '${fours}×4  ${sixes}×6',
                                    col1: runs.toString(),
                                    col2: balls.toString(),
                                    col3: sr,
                                    highlight: runs >= 50,
                                  );
                                }),
                              ],

                              // Bowling table
                              if (bowlerDocs.isNotEmpty) ...[
                                _scorecardSectionHeader(
                                    'Bowling', 'W', 'R', 'Eco'),
                                ...bowlerDocs.map((d) {
                                  final b =
                                      d.data() as Map<String, dynamic>;
                                  final name =
                                      (b['playerName'] as String?) ??
                                          (b['name'] as String?) ??
                                          'Player';
                                  final wickets =
                                      (b['wickets'] as num?)?.toInt() ??
                                          0;
                                  final runsConceded =
                                      (b['runsConceded'] as num?)
                                              ?.toInt() ??
                                          0;
                                  final balls =
                                      (b['balls'] as num?)?.toInt() ?? 0;
                                  final completedO = balls ~/ 6;
                                  final remB = balls % 6;
                                  final oversB = remB > 0
                                      ? '$completedO.$remB'
                                      : '$completedO';
                                  final totalOv = completedO +
                                      (remB / 6.0);
                                  final eco = totalOv > 0
                                      ? (runsConceded / totalOv)
                                          .toStringAsFixed(2)
                                      : '0.00';

                                  return _ScorecardRow(
                                    name: name,
                                    sub: '$oversB ov',
                                    col1: wickets.toString(),
                                    col2: runsConceded.toString(),
                                    col3: eco,
                                    highlight: wickets >= 3,
                                  );
                                }),
                              ],

                              const SizedBox(height: 4),
                            ],
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

Widget _scorecardSectionHeader(
    String label, String c1, String c2, String c3) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    color: Colors.white.withOpacity(0.04),
    child: Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
        _headerCell(c1),
        _headerCell(c2),
        _headerCell(c3),
      ],
    ),
  );
}

Widget _headerCell(String t) => SizedBox(
      width: 44,
      child: Text(t,
          textAlign: TextAlign.right,
          style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );

class _ScorecardRow extends StatelessWidget {
  final String name;
  final String sub;
  final String col1;
  final String col2;
  final String col3;
  final bool highlight;

  const _ScorecardRow({
    required this.name,
    required this.sub,
    required this.col1,
    required this.col2,
    required this.col3,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        color: highlight ? Colors.white : Colors.white70,
                        fontSize: 12,
                        fontWeight: highlight
                            ? FontWeight.bold
                            : FontWeight.normal),
                    overflow: TextOverflow.ellipsis),
                if (sub.isNotEmpty)
                  Text(sub,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 10),
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(col1,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: highlight
                        ? const Color(0xFFFFB300)
                        : Colors.white54,
                    fontSize: 12,
                    fontWeight: highlight
                        ? FontWeight.bold
                        : FontWeight.normal)),
          ),
          SizedBox(
            width: 44,
            child: Text(col2,
                textAlign: TextAlign.right,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 12)),
          ),
          SizedBox(
            width: 44,
            child: Text(col3,
                textAlign: TextAlign.right,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════
// STATS TAB
// ═══════════════════════════════════════════════════════════════════════════


// ═══════════════════════════════════════════════════════════════════════════
// TEAMS TAB
// ═══════════════════════════════════════════════════════════════════════════

class TeamsTab extends StatefulWidget {
  final Tournament tournament;
  const TeamsTab({super.key, required this.tournament});

  @override
  State<TeamsTab> createState() => _TeamsTabState();
}

class _TeamsTabState extends State<TeamsTab> {
  final _fs = FirestoreService.instance;
  List<TournamentTeam> _registeredTeams = [];
  bool _isLoading = true;
  bool _scheduleAlreadyGenerated = false;
  int _lastGeneratedTeamCount = 0;

  bool get _isCreator {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return widget.tournament.createdBy == uid;
  }

  bool get _isKnockout => widget.tournament.format == 'single_elimination';

  @override
  void initState() {
    super.initState();
    _loadRegisteredTeams();
  }

  Future<void> _loadRegisteredTeams() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('tournaments')
            .doc(widget.tournament.tournamentId)
            .collection('teams')
            .orderBy('addedAt', descending: false)
            .get(),
        FirebaseFirestore.instance
            .collection('tournaments')
            .doc(widget.tournament.tournamentId)
            .collection('matches')
            .limit(1)
            .get(),
      ]);

      final teamsSnap = results[0];
      final matchesSnap = results[1];

      if (mounted) {
        setState(() {
          _registeredTeams = teamsSnap.docs
              .map((d) => TournamentTeam(
                    tournamentId: d['tournamentId'] as String,
                    teamId: d['teamId'] as String,
                    teamName: d['teamName'] as String,
                    ownerUid: (d['ownerUid'] as String?) ?? '',
                    ownerName: (d['ownerName'] as String?) ?? '',
                    playerCount: (d['playerCount'] as int?) ?? 0,
                  ))
              .toList();
          _scheduleAlreadyGenerated = matchesSnap.docs.isNotEmpty;
          if (matchesSnap.docs.isNotEmpty) {
            _lastGeneratedTeamCount = teamsSnap.docs.length;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showScheduleOptions() {
    if (_registeredTeams.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'You need at least 2 teams to generate a knockout bracket.'),
          backgroundColor: Colors.orange));
      return;
    }

    if (_isKnockout) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const Text('Generate Knockout Bracket',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${_registeredTeams.length} teams registered.',
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 4),
              _bracketPreviewInfo(_registeredTeams.length),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF00BCD4).withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.account_tree_outlined,
                        color: Color(0xFF00BCD4), size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Single Elimination',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          Text('Lose once and you\'re out',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),
                    Icon(Icons.lock_outline,
                        color: Color(0xFF00BCD4), size: 16),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BCD4),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _generateKnockoutSchedule();
                },
                child: const Text('Generate Bracket',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final tournamentFormat = widget.tournament.format;
    final lockedFormat = (tournamentFormat?.isNotEmpty == true)
        ? kFormats.firstWhere((f) => f.id == tournamentFormat,
            orElse: () => kFormats.first)
        : null;

    if (lockedFormat != null) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const Text('Generate Schedule',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('${_registeredTeams.length} teams registered.',
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF00BCD4).withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(lockedFormat.icon,
                        color: const Color(0xFF00BCD4), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lockedFormat.label,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          Text(lockedFormat.tagline,
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(Icons.lock_outline,
                        color: Color(0xFF00BCD4), size: 16),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BCD4),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _generateAndSaveSchedule(lockedFormat.id);
                },
                child: const Text('Generate Now',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // Fallback free-pick
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const Text('Generate Schedule',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              '${_registeredTeams.length} teams registered. Choose a format.',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ...kFormats.map((fmt) => GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _generateAndSaveSchedule(fmt.id);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              const Color(0xFF00BCD4).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(fmt.icon,
                            color: const Color(0xFF00BCD4), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fmt.label,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              Text(fmt.tagline,
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 11)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: Colors.white38),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _bracketPreviewInfo(int n) {
    final bracketSize = nextPowerOfTwo(n);
    final byes = bracketSize - n;
    final totalMatches = n - 1;
    final totalRounds =
        (math.log(bracketSize) / math.log(2)).round();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Bracket size', '$bracketSize slots'),
          if (byes > 0) _infoRow('Byes (top seeds)', '$byes teams'),
          _infoRow('Total matches', '$totalMatches'),
          _infoRow('Rounds', '$totalRounds'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12))),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ],
        ),
      );

  Future<void> _generateKnockoutSchedule() async {
    final matches = generateKnockoutBracket(_registeredTeams);
    if (matches.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not generate bracket.'),
            backgroundColor: Colors.red));
      }
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final col = FirebaseFirestore.instance
        .collection('tournaments')
        .doc(widget.tournament.tournamentId)
        .collection('matches');

    final batch = FirebaseFirestore.instance.batch();
    for (final match in matches) {
      final matchId = match['matchId'] as String;
      batch.set(col.doc(matchId), {
        ...match,
        'tournamentId': widget.tournament.tournamentId,
        'createdBy': uid,
      });
    }

    try {
      await batch.commit();
      await _resolveByeChains(matches, col);

      if (mounted) {
        setState(() {
          _scheduleAlreadyGenerated = true;
          _lastGeneratedTeamCount = _registeredTeams.length;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${matches.where((m) => !(m['isBye'] as bool)).length} matches + '
              '${matches.where((m) => m['isBye'] as bool).length} byes generated!'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error generating bracket: $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _resolveByeChains(
      List<Map<String, dynamic>> matches, CollectionReference col) async {
    final byeMatches = matches.where((m) => m['isBye'] as bool).toList();
    if (byeMatches.isEmpty) return;

    final batch2 = FirebaseFirestore.instance.batch();
    for (final bye in byeMatches) {
      final nextMatchId = (bye['nextMatchId'] as String?) ?? '';
      final nextSlot = (bye['nextMatchSlot'] as int?) ?? 1;
      final winnerId = (bye['winnerId'] as String?) ?? '';
      final winnerName = (bye['winnerName'] as String?) ?? '';

      if (nextMatchId.isEmpty || winnerId.isEmpty) continue;

      final nextRef = col.doc(nextMatchId);
      if (nextSlot == 1) {
        batch2.update(nextRef, {'team1Id': winnerId, 'team1Name': winnerName});
      } else {
        batch2.update(nextRef, {'team2Id': winnerId, 'team2Name': winnerName});
      }
    }
    await batch2.commit();
  }

  Future<void> _generateAndSaveSchedule(String formatId) async {
    final matchups = generateScheduleFromTeams(formatId, _registeredTeams);
    if (matchups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not generate schedule for selected format.'),
          backgroundColor: Colors.red));
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final batch = FirebaseFirestore.instance.batch();
    final col = FirebaseFirestore.instance
        .collection('tournaments')
        .doc(widget.tournament.tournamentId)
        .collection('matches');

    for (final pair in matchups) {
      final ref = col.doc();
      batch.set(ref, {
        'matchId': ref.id,
        'tournamentId': widget.tournament.tournamentId,
        'teamId1': pair[0].teamId,
        'teamId2': pair[1].teamId,
        'teamId1Name': pair[0].teamName,
        'teamId2Name': pair[1].teamName,
        'teamId1OwnerUid': pair[0].ownerUid,
        'teamId2OwnerUid': pair[1].ownerUid,
        'overs': 20,
        'isCompleted': false,
        'status': 'scheduled',
        'scheduledAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
        'format': formatId,
        'roundNo': 0,
        'roundName': 'League',
        'isBye': false,
      });
    }

    try {
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('${matchups.length} matches scheduled successfully!'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error generating schedule: $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  void _showAddTeamModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
              alignment: Alignment.center,
            ),
            const Text('Add Team to Tournament',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            _modalOption(
              icon: Icons.group,
              label: 'Add from My Teams',
              subtitle: 'Pick a team you already created',
              onTap: () {
                Navigator.pop(context);
                _showMyTeamsPicker();
              },
            ),
            const SizedBox(height: 12),
            _modalOption(
              icon: Icons.add_circle_outline,
              label: 'Create Team Manually',
              subtitle: 'Create a new team with players',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateTournamentTeamPage(
                      tournament: widget.tournament,
                      onTeamAdded: _loadRegisteredTeams,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _modalOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF00BCD4).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF00BCD4), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Future<void> _showMyTeamsPicker() async {
    final alreadyAddedNames =
        _registeredTeams.map((t) => t.teamName.toLowerCase()).toSet();
    List<Team> myTeams = [];
    bool loading = true;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          if (loading) {
            _fs.getMyTeams().then((teams) {
              if (ctx.mounted) {
                setSheet(() {
                  myTeams = teams;
                  loading = false;
                });
              }
            });
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.65,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Select a Team',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Expanded(
                  child: loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF00BCD4)))
                      : myTeams.isEmpty
                          ? const Center(
                              child: Text(
                                'No teams found.\nCreate one first from the Teams section.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 14),
                              ),
                            )
                          : ListView.builder(
                              itemCount: myTeams.length,
                              itemBuilder: (_, i) {
                                final team = myTeams[i];
                                final alreadyIn = alreadyAddedNames
                                    .contains(team.teamName.toLowerCase());
                                return GestureDetector(
                                  onTap: alreadyIn
                                      ? null
                                      : () async {
                                          Navigator.pop(sheetCtx);
                                          await _addExistingTeam(team);
                                        },
                                  child: Container(
                                    margin:
                                        const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: alreadyIn
                                          ? const Color(0xFF0D0D1A)
                                              .withOpacity(0.5)
                                          : const Color(0xFF0D0D1A),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: alreadyIn
                                            ? Colors.white12
                                            : const Color(0xFF00BCD4)
                                                .withOpacity(0.4),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.group,
                                            color: Color(0xFF00BCD4),
                                            size: 22),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(team.teamName,
                                              style: TextStyle(
                                                color: alreadyIn
                                                    ? Colors.white38
                                                    : Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              )),
                                        ),
                                        if (alreadyIn)
                                          const Text('Added',
                                              style: TextStyle(
                                                  color: Colors.white38,
                                                  fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _addExistingTeam(Team team) async {
    final user = FirebaseAuth.instance.currentUser!;
    try {
      final members = await _fs.getPlayers(user.uid, team.teamId);
      await TournamentTeam.addTeamToTournament(
        tournamentId: widget.tournament.tournamentId,
        teamId: team.teamId,
        teamName: team.teamName,
        ownerUid: user.uid,
        ownerName: user.displayName ?? '',
        playerCount: members.length,
      );
      await _loadRegisteredTeams();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('"${team.teamName}" added to tournament!'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF00BCD4)));
    }

    final minTeams = _isKnockout ? 2 : 3;

    return Stack(
      children: [
        _registeredTeams.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.group_outlined,
                        color: Color(0xFF00BCD4), size: 52),
                    const SizedBox(height: 12),
                    const Text('No teams registered yet.',
                        style: TextStyle(
                            color: Colors.white38, fontSize: 14)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Team'),
                      onPressed: _showAddTeamModal,
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(12, 12, 12, 100),
                      itemCount: _registeredTeams.length,
                      itemBuilder: (_, i) =>
                          _buildTeamCard(_registeredTeams[i]),
                    ),
                  ),
                  if (_isCreator && _registeredTeams.length >= minTeams)
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _scheduleAlreadyGenerated
                          ? Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        Colors.orange.withOpacity(0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lock_outline,
                                      color: Colors.orange, size: 16),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Schedule already generated. '
                                      'Add more teams to regenerate.',
                                      style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12),
                                    ),
                                  ),
                                  if (_registeredTeams.length >
                                      _lastGeneratedTeamCount)
                                    TextButton(
                                      onPressed: _showScheduleOptions,
                                      child: const Text('Regenerate',
                                          style: TextStyle(
                                              color: Color(0xFF00BCD4),
                                              fontSize: 12,
                                              fontWeight:
                                                  FontWeight.bold)),
                                    ),
                                ],
                              ),
                            )
                          : ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF1A237E),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(46),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                                side: const BorderSide(
                                    color: Color(0xFF00BCD4), width: 1),
                              ),
                              icon: const Icon(Icons.auto_fix_high,
                                  color: Color(0xFF00BCD4), size: 18),
                              label: Text(
                                _isKnockout
                                    ? 'Generate Knockout Bracket'
                                    : 'Auto-Generate Schedule',
                                style: const TextStyle(
                                    color: Color(0xFF00BCD4),
                                    fontWeight: FontWeight.bold),
                              ),
                              onPressed: _showScheduleOptions,
                            ),
                    ),
                  if (_isCreator &&
                      _registeredTeams.length < minTeams)
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.orange.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Add ${minTeams - _registeredTeams.length} more team(s) to unlock '
                                '${_isKnockout ? 'bracket generation' : 'auto-scheduling'}.',
                                style: const TextStyle(
                                    color: Colors.orange, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
        if (_registeredTeams.isNotEmpty)
          Positioned(
            bottom: 70,
            right: 16,
            child: FloatingActionButton.extended(
              backgroundColor: const Color(0xFF00BCD4),
              onPressed: _showAddTeamModal,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Team',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
      ],
    );
  }

  Widget _buildTeamCard(TournamentTeam team) {
    final isOwner = team.ownerUid ==
        (FirebaseAuth.instance.currentUser?.uid ?? '');
   return Container(
  margin: const EdgeInsets.only(bottom: 10),
  decoration: BoxDecoration(
    color: const Color(0xFF1A1A2E),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: isOwner
          ? const Color(0xFF00BCD4).withOpacity(0.35)
          : Colors.white.withOpacity(0.06),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.18),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  ),
  child: ListTile(
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    leading: Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00BCD4).withOpacity(0.22),
            const Color(0xFF1A237E).withOpacity(0.45),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFF00BCD4).withOpacity(0.2),
        ),
      ),
      child: const Icon(Icons.shield_outlined,
          color: Color(0xFF00BCD4), size: 22),
    ),
    title: Text(
      team.teamName,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    ),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          const Icon(Icons.people_outline,
              color: Colors.white38, size: 13),
          const SizedBox(width: 4),
          Text(
            '${team.playerCount} player${team.playerCount == 1 ? '' : 's'}',
            style: const TextStyle(
                color: Colors.white38, fontSize: 12),
          ),
          if (team.ownerName.isNotEmpty) ...[
            const Text('  ·  ',
                style:
                    TextStyle(color: Colors.white24, fontSize: 12)),
            Flexible(
              child: Text(
                team.ownerName,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    ),
    trailing: isOwner
        ? Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00BCD4).withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'You',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        : null,
  ),
);
   }
} 

// ═══════════════════════════════════════════════════════════════════════════
// ABOUT TAB
// ═══════════════════════════════════════════════════════════════════════════

class AboutTab extends StatelessWidget {
  final Tournament tournament;
  const AboutTab({super.key, required this.tournament});

  String _fmt(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
          left: 16, right: 16, top: 16, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AboutSection(
            icon: Icons.emoji_events_outlined,
            title: 'Tournament Info',
            rows: [
              _AboutRow(label: 'Name', value: tournament.name),
              _AboutRow(label: 'City', value: tournament.city),
              _AboutRow(label: 'Venue', value: tournament.ground),
            ],
          ),
          const SizedBox(height: 12),
          _AboutSection(
            icon: Icons.calendar_month,
            title: 'Schedule',
            rows: [
              _AboutRow(
                  label: 'Start Date', value: _fmt(tournament.startDate)),
              _AboutRow(
                  label: 'End Date', value: _fmt(tournament.endDate)),
              _AboutRow(
                label: 'Duration',
                value:
                    '${tournament.endDate.difference(tournament.startDate).inDays} days',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _AboutSection(
            icon: Icons.person_outline,
            title: 'Organizer',
            rows: [
              _AboutRow(label: 'Name', value: tournament.organizerName),
              _AboutRow(label: 'Phone', value: tournament.organizerPhone),
            ],
          ),
          if (tournament.categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            _AboutSection(
              icon: Icons.category_outlined,
              title: 'Categories',
              rows: tournament.categories
                  .map((c) => _AboutRow(label: '', value: c))
                  .toList(),
            ),
          ],
          if (tournament.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.label_outline,
                          color: Color(0xFF00BCD4), size: 20),
                      SizedBox(width: 8),
                      Text('Tags',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tournament.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D0D1A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF00BCD4), width: 1),
                        ),
                        child: Text(tag,
                            style: const TextStyle(
                                color: Color(0xFF00BCD4), fontSize: 12)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const _ProFeatureSuggestions(),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_AboutRow> rows;

  const _AboutSection({
    required this.icon,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00BCD4), size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: row.label.isEmpty
                    ? Text(row.value,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13))
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 90,
                            child: Text(row.label,
                                style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 13)),
                          ),
                          Expanded(
                            child: Text(row.value,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13)),
                          ),
                        ],
                      ),
              )),
        ],
      ),
    );
  }
}

class _AboutRow {
  final String label;
  final String value;
  const _AboutRow({required this.label, required this.value});
}

class _ProFeatureSuggestions extends StatelessWidget {
  static const _features = [
    (Icons.live_tv, 'Live Scoring',
        'Ball-by-ball scoring with real-time updates for spectators and players.',
        Color(0xFFE53935)),
    (Icons.emoji_events, 'Player of the Match Awards',
        'Auto-calculate and display POTM based on performance stats each game.',
        Color(0xFFFFB300)),
    (Icons.bar_chart, 'Advanced Analytics',
        'Win probability, wagon wheel heatmaps and batting/bowling trends.',
        Color(0xFF00BCD4)),
    (Icons.share, 'Share Scorecard',
        'One-tap shareable scorecards as images for WhatsApp and Instagram.',
        Color(0xFF43A047)),
    (Icons.notifications_active, 'Match Reminders',
        'Push notifications to teams and fans before each match starts.',
        Color(0xFF8E24AA)),
    (Icons.people_alt_outlined, 'Fan Voting',
        'Let spectators vote for best player, best moment after every match.',
        Color(0xFFFF7043)),
    (Icons.monetization_on_outlined, 'Prize Pool Tracker',
        'Display prize distribution, sponsor logos and final standings.',
        Color(0xFFFFD600)),
    (Icons.camera_alt_outlined, 'Match Gallery',
        'Upload and share photos/videos from each match inside the app.',
        Color(0xFF00ACC1)),
  ];

  const _ProFeatureSuggestions();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          const Row(
            children: [
              Icon(Icons.rocket_launch_outlined,
                  color: Color(0xFF00BCD4), size: 20),
              SizedBox(width: 8),
              Text('Pro Feature Ideas',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Coming soon — features that make your tournament stand out',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 14),
          ..._features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: f.$4.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(f.$1, color: f.$4, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.$2,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(f.$3,
                              style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
  
}