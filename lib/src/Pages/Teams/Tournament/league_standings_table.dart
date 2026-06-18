import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:TURF_TOWN_/src/models/tournament_model.dart';

// ═══════════════════════════════════════════════════════════════════════════
// LEAGUE STANDINGS TABLE
// ═══════════════════════════════════════════════════════════════════════════
// Automatically generates and updates points table for league format tournaments

class _LeagueTeamStat {
  final String teamId;
  final String teamName;
  int played = 0;
  int wins = 0;
  int losses = 0;
  int ties = 0;
  int noResults = 0;
  int runsFor = 0;
  int runsAgainst = 0;
  int ballsFor = 0;
  int ballsAgainst = 0;

  _LeagueTeamStat({required this.teamId, required this.teamName});

  int get points {
    // Standard cricket scoring: Win = 2pts, Tie = 1pt, NR = 1pt, Loss = 0pts
    return (wins * 2) + (ties * 1) + (noResults * 1);
  }

  double get nrr {
    // Net Run Rate = (Runs For / Overs For) - (Runs Against / Overs Against)
    final oversFor = ballsFor / 6.0;
    final oversAgainst = ballsAgainst / 6.0;
    
    if (oversFor == 0 || oversAgainst == 0) return 0.0;
    
    final rrFor = runsFor / oversFor;
    final rrAgainst = runsAgainst / oversAgainst;
    
    return rrFor - rrAgainst;
  }
}

class LeagueStandingsTable extends StatelessWidget {
  final Tournament tournament;
  const LeagueStandingsTable({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // First, fetch all matches to get team list and results
      stream: FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tournament.tournamentId)
          .collection('matches')
          .snapshots(),
      builder: (context, matchSnap) {
        if (matchSnap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00BCD4)));
        }

        final docs = matchSnap.data?.docs ?? [];
        final Map<String, _LeagueTeamStat> stats = {};

        // Initialize team stats from all matches
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final t1Id = (data['teamId1'] as String?) ?? '';
          final t1Name = (data['teamId1Name'] as String?) ?? '';
          final t2Id = (data['teamId2'] as String?) ?? '';
          final t2Name = (data['teamId2Name'] as String?) ?? '';

          // Add teams to stats if not exists
          if (t1Id.isNotEmpty && t1Name.isNotEmpty && t1Name != 'TBD') {
            stats.putIfAbsent(
              t1Id,
              () => _LeagueTeamStat(teamId: t1Id, teamName: t1Name),
            );
          }
          if (t2Id.isNotEmpty && t2Name.isNotEmpty && t2Name != 'TBD') {
            stats.putIfAbsent(
              t2Id,
              () => _LeagueTeamStat(teamId: t2Id, teamName: t2Name),
            );
          }

          // Only process completed matches
          final isCompleted = (data['isCompleted'] as bool?) ?? false;
          if (!isCompleted) continue;

          final winnerId = (data['winnerId'] as String?) ?? '';
          final result = (data['result'] as String?) ?? ''; // win/loss/tie/nr
          
          stats[t1Id]?.played++;
          stats[t2Id]?.played++;

          // Update win/loss/tie based on result or winnerId
          if (winnerId.isNotEmpty) {
            if (winnerId == t1Id) {
              stats[t1Id]?.wins++;
              stats[t2Id]?.losses++;
            } else if (winnerId == t2Id) {
              stats[t2Id]?.wins++;
              stats[t1Id]?.losses++;
            }
          } else if (result == 'tie') {
            stats[t1Id]?.ties++;
            stats[t2Id]?.ties++;
          } else if (result == 'no_result') {
            stats[t1Id]?.noResults++;
            stats[t2Id]?.noResults++;
          }

          // Update runs and overs from cached data
          if (data.containsKey('cachedRunsFor')) {
            stats[t1Id]?.runsFor += ((data['cachedRunsFor'] as num?) ?? 0).toInt();
          }
          if (data.containsKey('cachedBallsFor')) {
            stats[t1Id]?.ballsFor += ((data['cachedBallsFor'] as num?) ?? 0).toInt();
          }
          if (data.containsKey('cachedRunsAgainst')) {
            stats[t1Id]?.runsAgainst += ((data['cachedRunsAgainst'] as num?) ?? 0).toInt();
          }
          if (data.containsKey('cachedBallsAgainst')) {
            stats[t1Id]?.ballsAgainst += ((data['cachedBallsAgainst'] as num?) ?? 0).toInt();
          }
        }

        if (stats.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.table_chart_outlined,
                    color: const Color(0xFF00BCD4).withOpacity(0.3),
                    size: 52),
                const SizedBox(height: 12),
                const Text(
                  'Points table will appear once matches are scheduled.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),
          );
        }

        // Sort by points (desc), then by NRR (desc)
        final sorted = stats.entries.toList()
          ..sort((a, b) {
            final ptsCmp = b.value.points.compareTo(a.value.points);
            if (ptsCmp != 0) return ptsCmp;
            return b.value.nrr.compareTo(a.value.nrr);
          });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text('League Standings',
                    style: TextStyle(color: Colors.white60, fontSize: 13)),
              ),
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
                    SizedBox(width: 28), // rank column
                    Expanded(
                        flex: 3,
                        child: Text('Team',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold))),
                    _TableHeaderCell('M'),
                    _TableHeaderCell('W'),
                    _TableHeaderCell('L'),
                    _TableHeaderCell('NRR'),
                    _TableHeaderCell('Pts'),
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
                                    style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 3,
                                child: Text(teamStat.teamName,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis),
                              ),
                          _TableCell(teamStat.played.toString()),
                              _TableCell(teamStat.wins.toString()),
                              _TableCell(teamStat.losses.toString()),
                              _TableCell(
                                (teamStat.nrr >= 0 ? '+' : '') +
                                    teamStat.nrr.toStringAsFixed(3),
                              ),
                          _TableCell(teamStat.points.toString(),
                                  highlight: true),                           ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                 'M = Matches  W = Wins  L = Losses  NRR = Net Run Rate  Pts = Points (Win=2, Tie/NR=1)',
                  style: TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Table Header Cell ────────────────────────────────────────────────────

class _TableHeaderCell extends StatelessWidget {
  final String text;
  const _TableHeaderCell(this.text);

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

// ─── Table Cell ────────────────────────────────────────────────────────

class _TableCell extends StatelessWidget {
  final String text;
  final bool highlight;

  const _TableCell(this.text, {this.highlight = false});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: highlight ? Colors.white : Colors.white54,
              fontSize: 12,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            )),
      );
}