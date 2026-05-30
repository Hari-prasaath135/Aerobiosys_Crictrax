import 'dart:math' as math;
import 'package:TURF_TOWN_/src/Pages/Teams/Tournament/tournament_formats.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/Tournament/tournament_match_player_selection_page.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/Tournament/tournament_schedule_helpers.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: AnimatedBuilder(
            animation: _matchTabController,
            builder: (_, __) => Row(
              children: List.generate(_matchTabs.length, (i) {
                final selected = _matchTabController.index == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _matchTabController.animateTo(i)),
                    child: Container(
                      margin: EdgeInsets.only(right: i < 2 ? 8.0 : 0.0),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF00BCD4)
                            : const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _matchTabs[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white54,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF1A237E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(roundName,
              style: const TextStyle(
                  color: Color(0xFF00BCD4),
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
        const SizedBox(width: 8),
        Text('$matchCount match${matchCount == 1 ? '' : 'es'}',
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
        const Expanded(child: Divider(color: Colors.white12, indent: 8)),
      ],
    );
  }
}

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
          border: Border.all(
              color: const Color(0xFF00BCD4).withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events,
                color: Color(0xFF00BCD4), size: 22),
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

  if (scheduledAt != null && !_isWithinMatchWindow(scheduledAt)) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text(
          'Match can only be started 30 minutes before or within 6 hours of scheduled time.'),
      backgroundColor: Colors.orange,
    ));
    return;
  }

  final t1Id   = (data['teamId1'] as String?) ?? '';
  final t2Id   = (data['teamId2'] as String?) ?? '';
  final t1Name = (data['teamId1Name'] as String?) ?? 'Team 1';
  final t2Name = (data['teamId2Name'] as String?) ?? 'Team 2';
  final overs  = (data['overs'] as int?) ?? 20;

  if (t1Id.isEmpty || t2Id.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Both teams must be assigned before starting.'),
      backgroundColor: Colors.orange,
    ));
    return;
  }

  if (!context.mounted) return;
 Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => TournamentMatchPlayerSelectionPage(
      tournament: tournament,
      matchDocId: matchDocId,
      teamId1: t1Id,
      teamId2: t2Id,
      teamId1Name: t1Name,
      teamId2Name: t2Name,
      overs: overs,
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
                    final overs =
                        int.tryParse(oversCtrl.text.trim()) ?? 20;
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
                style:
                    const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFFFFB300).withOpacity(0.4)
              : const Color(0xFF00BCD4).withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          _teamRow(
              name: team1Name,
              isWinner: team1IsWinner,
              isPending: status == 'pending'),
          const Divider(color: Colors.white12, height: 1),
          _teamRow(
              name: team2Name,
              isWinner: team2IsWinner,
              isPending: status == 'pending'),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D1A).withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isCompleted
                          ? const Color(0xFFFFB300)
                          : status == 'pending'
                              ? Colors.white24
                              : Colors.green,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isCompleted
                        ? 'Completed'
                        : status == 'pending'
                            ? 'Waiting'
                            : 'Scheduled',
                    style: TextStyle(
                      color: isCompleted
                          ? const Color(0xFFFFB300)
                          : status == 'pending'
                              ? Colors.white38
                              : Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: isCreator && !isCompleted
                      ? () => _editMatchSchedule(context)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isCreator && !isCompleted
                            ? const Color(0xFF00BCD4).withOpacity(0.4)
                            : Colors.transparent,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('$overs ov',
                        style: TextStyle(
                          color: isCreator && !isCompleted
                              ? const Color(0xFF00BCD4)
                              : Colors.white38,
                          fontSize: 11,
                        )),
                  ),
                ),
                const Spacer(),
                if (scheduledAt != null)
                  Text(
                    '${scheduledAt.day}/${scheduledAt.month}  '
                    '${scheduledAt.hour}:${scheduledAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11),
                  )
                else
                  const Text('No date set',
                      style: TextStyle(
                          color: Colors.white24, fontSize: 10)),
            if (isCreator && !isCompleted && status != 'pending') ...[
  const SizedBox(width: 4),
  PopupMenuButton<String>(
    color: const Color(0xFF1A1A2E),
    icon: const Icon(Icons.more_vert,
        color: Colors.white54, size: 18),
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

  Widget _teamRow(
      {required String name,
      required bool isWinner,
      required bool isPending}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isWinner
                  ? const Color(0xFFFFB300).withOpacity(0.2)
                  : const Color(0xFF0D0D1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isWinner ? Icons.emoji_events : Icons.group,
              color: isWinner
                  ? const Color(0xFFFFB300)
                  : isPending
                      ? Colors.white24
                      : const Color(0xFF00BCD4),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name,
                style: TextStyle(
                  color: isPending
                      ? Colors.white38
                      : isWinner
                          ? Colors.white
                          : Colors.white70,
                  fontWeight:
                      isWinner ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                )),
          ),
          if (isWinner)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Winner',
                  style: TextStyle(
                      color: Color(0xFFFFB300),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCHEDULED MATCH LIST  (non-knockout formats)
// ═══════════════════════════════════════════════════════════════════════════

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

  if (scheduledAt != null && !_isWithinMatchWindow(scheduledAt)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Match can only be started 30 minutes before or within 6 hours of scheduled time.'),
        backgroundColor: Colors.orange,
      ));
    }
    return;
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
    builder: (_) => TournamentMatchPlayerSelectionPage(
      tournament: tournament,
      matchDocId: matchDocId,
      teamId1: t1Id,
      teamId2: t2Id,
      teamId1Name: t1Name,
      teamId2Name: t2Name,
      overs: overs,
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
            if (isCompleted || scheduledAt == null) return false;
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: AnimatedBuilder(
            animation: _lbTabController,
            builder: (_, __) => Row(
              children: List.generate(_tabs.length, (i) {
                final selected = _lbTabController.index == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _lbTabController.animateTo(i)),
                    child: Container(
                      margin: EdgeInsets.only(right: i == 0 ? 8.0 : 0.0),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF00BCD4)
                            : const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _tabs[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white54,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
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

class _BatsmenLeaderboard extends StatelessWidget {
  final Tournament tournament;
  const _BatsmenLeaderboard({required this.tournament});

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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Batting stats will appear after matches are scored.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          );
        }

        // Aggregate batsman stats from all match batting scorecards
        final Map<String, Map<String, dynamic>> playerStats = {};

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final batting =
              (data['battingScorecard'] as List<dynamic>?) ?? [];
          for (final b in batting) {
            final bMap = b as Map<String, dynamic>;
            final playerId = (bMap['playerId'] as String?) ?? '';
            final playerName = (bMap['playerName'] as String?) ?? 'Unknown';
            final runs = (bMap['runs'] as int?) ?? 0;
            final balls = (bMap['balls'] as int?) ?? 0;
            final fours = (bMap['fours'] as int?) ?? 0;
            final sixes = (bMap['sixes'] as int?) ?? 0;
            if (playerId.isEmpty) continue;

            if (!playerStats.containsKey(playerId)) {
              playerStats[playerId] = {
                'name': playerName,
                'runs': 0,
                'balls': 0,
                'fours': 0,
                'sixes': 0,
                'innings': 0,
              };
            }
            playerStats[playerId]!['runs'] =
                (playerStats[playerId]!['runs'] as int) + runs;
            playerStats[playerId]!['balls'] =
                (playerStats[playerId]!['balls'] as int) + balls;
            playerStats[playerId]!['fours'] =
                (playerStats[playerId]!['fours'] as int) + fours;
            playerStats[playerId]!['sixes'] =
                (playerStats[playerId]!['sixes'] as int) + sixes;
            playerStats[playerId]!['innings'] =
                (playerStats[playerId]!['innings'] as int) + 1;
          }
        }

        if (playerStats.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No batting data yet.',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          );
        }

        final sorted = playerStats.entries.toList()
          ..sort((a, b) =>
              (b.value['runs'] as int).compareTo(a.value['runs'] as int));

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
          children: [
            // Header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF1A237E),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10)),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 28),
                  Expanded(
                      flex: 3,
                      child: Text('Player',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold))),
                  TableHeaderCell('R'),
                  TableHeaderCell('B'),
                  TableHeaderCell('4s'),
                  TableHeaderCell('6s'),
                  TableHeaderCell('SR'),
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
                  final stat = entry.value.value;
                  final balls = stat['balls'] as int;
                  final runs = stat['runs'] as int;
                  final sr =
                      balls > 0 ? (runs / balls * 100).toStringAsFixed(1) : '—';
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
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: Text(stat['name'] as String,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            TableCell(runs.toString()),
                            TableCell(balls.toString()),
                            TableCell((stat['fours'] as int).toString()),
                            TableCell((stat['sixes'] as int).toString()),
                            TableCell(sr),
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
      },
    );
  }
}

class _BowlersLeaderboard extends StatelessWidget {
  final Tournament tournament;
  const _BowlersLeaderboard({required this.tournament});

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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Bowling stats will appear after matches are scored.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          );
        }

        final Map<String, Map<String, dynamic>> playerStats = {};

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final bowling =
              (data['bowlingScorecard'] as List<dynamic>?) ?? [];
          for (final b in bowling) {
            final bMap = b as Map<String, dynamic>;
            final playerId = (bMap['playerId'] as String?) ?? '';
            final playerName = (bMap['playerName'] as String?) ?? 'Unknown';
            final wickets = (bMap['wickets'] as int?) ?? 0;
            final runs = (bMap['runs'] as int?) ?? 0;
            final ballsBowled = (bMap['balls'] as int?) ?? 0;
            if (playerId.isEmpty) continue;

            if (!playerStats.containsKey(playerId)) {
              playerStats[playerId] = {
                'name': playerName,
                'wickets': 0,
                'runs': 0,
                'balls': 0,
              };
            }
            playerStats[playerId]!['wickets'] =
                (playerStats[playerId]!['wickets'] as int) + wickets;
            playerStats[playerId]!['runs'] =
                (playerStats[playerId]!['runs'] as int) + runs;
            playerStats[playerId]!['balls'] =
                (playerStats[playerId]!['balls'] as int) + ballsBowled;
          }
        }

        if (playerStats.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No bowling data yet.',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          );
        }

        final sorted = playerStats.entries.toList()
          ..sort((a, b) {
            final wCmp = (b.value['wickets'] as int)
                .compareTo(a.value['wickets'] as int);
            if (wCmp != 0) return wCmp;
            return (a.value['runs'] as int)
                .compareTo(b.value['runs'] as int);
          });

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF1A237E),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10)),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 28),
                  Expanded(
                      flex: 3,
                      child: Text('Player',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold))),
                  TableHeaderCell('W'),
                  TableHeaderCell('R'),
                  TableHeaderCell('Ov'),
                  TableHeaderCell('Eco'),
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
                  final stat = entry.value.value;
                  final balls = stat['balls'] as int;
                  final runs = stat['runs'] as int;
                  final completedOvers = balls ~/ 6;
                  final remBalls = balls % 6;
                  final oversStr =
                      '$completedOvers${remBalls > 0 ? '.$remBalls' : ''}';
                  final totalOvers =
                      completedOvers + (remBalls / 6.0);
                  final eco = totalOvers > 0
                      ? (runs / totalOvers).toStringAsFixed(2)
                      : '—';

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
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: Text(stat['name'] as String,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            TableCell(
                                (stat['wickets'] as int).toString()),
                            TableCell(runs.toString()),
                            TableCell(oversStr),
                            TableCell(eco),
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
      },
    );
  }
}

class _BattingScorecardTable extends StatelessWidget {
  final Tournament tournament;
  const _BattingScorecardTable({required this.tournament});

  @override
  Widget build(BuildContext context) =>
      _BatsmenLeaderboard(tournament: tournament);
}

class _BowlingScorecardTable extends StatelessWidget {
  final Tournament tournament;
  const _BowlingScorecardTable({required this.tournament});

  @override
  Widget build(BuildContext context) =>
      _BowlersLeaderboard(tournament: tournament);
}

// ═══════════════════════════════════════════════════════════════════════════
// STATS TAB
// ═══════════════════════════════════════════════════════════════════════════

// REPLACE WITH:
class StatsTab extends StatefulWidget {
  final Tournament tournament;
  const StatsTab({super.key, required this.tournament});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  int _selectedFilter = 0;
  final _filters = ['Batting', 'Bowling'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF0D0D1A),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: List.generate(_filters.length, (i) {
              final selected = _selectedFilter == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedFilter = i),
                  child: Container(
                    margin: EdgeInsets.only(right: i == 0 ? 8.0 : 0.0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF00BCD4)
                          : const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _filters[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white54,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: _selectedFilter == 0
              ? _BattingScorecardTable(tournament: widget.tournament)
              : _BowlingScorecardTable(tournament: widget.tournament),
        ),
      ],
    );
  }
}

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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFF00BCD4).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.group,
                color: Color(0xFF00BCD4), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team.teamName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 3),
                Text(
                  '${team.playerCount} player${team.playerCount == 1 ? '' : 's'}  •  '
                  '${team.ownerName.isNotEmpty ? team.ownerName : 'Unknown'}',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          if (isOwner)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('You',
                  style: TextStyle(
                      color: Color(0xFF00BCD4), fontSize: 11)),
            ),
        ],
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