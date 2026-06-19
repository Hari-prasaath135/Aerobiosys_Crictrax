import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:TURF_TOWN_/src/models/Tournament_team.dart';
import 'dart:math' as math;

bool isPowerOfTwo(int n) => n > 0 && (n & (n - 1)) == 0;

int nextPowerOfTwo(int n) {
  int p = 1;
  while (p < n) p <<= 1;
  return p;
}

String roundName(int roundIndex, int totalRounds) {
  final fromEnd = totalRounds - 1 - roundIndex;
  if (fromEnd == 0) return 'Final';
  if (fromEnd == 1) return 'Semi-Finals';
  if (fromEnd == 2) return 'Quarter-Finals';
  if (fromEnd == 3) return 'Round of 16';
  if (fromEnd == 4) return 'Round of 32';
  return 'Round ${roundIndex + 1}';
}

String _newId() =>
    FirebaseFirestore.instance.collection('_').doc().id;

// ─── Minimum teams required per format ────────────────────────────────────
int minTeamsForFormat(String formatId) {
  switch (formatId) {
    case 'single_elimination':
      return 2;
    case 'league':
    case 'ipl_full_league':
      return 3;
    case 'double_elimination':
      return 4;
    case 'fifa_world_cup':
      return 4;
    default:
      return 3;
  }
}

// ─── Single Elimination knockout bracket ──────────────────────────────────
List<Map<String, dynamic>> generateKnockoutBracket(
    List<TournamentTeam> teams) {
  final n = teams.length;
  if (n < 2) return [];

  final bracketSize = nextPowerOfTwo(n);
  final totalRounds = (math.log(bracketSize) / math.log(2)).round();

  final seeded = List<TournamentTeam?>.from(teams);
  while (seeded.length < bracketSize) {
    seeded.add(null);
  }

  final List<List<String>> roundMatchIds = [];
  int slots = bracketSize ~/ 2;
  while (slots >= 1) {
    roundMatchIds.add(List.generate(slots, (_) => _newId()));
    if (slots == 1) break;
    slots ~/= 2;
  }

  final List<Map<String, dynamic>> allMatches = [];

  final round0Count = bracketSize ~/ 2;
  for (int i = 0; i < round0Count; i++) {
    final seed1idx = i;
    final seed2idx = bracketSize - 1 - i;
    final team1 = seeded[seed1idx];
    final team2 = seeded[seed2idx];
    final matchId = roundMatchIds[0][i];
    final nextMatchIdx = i ~/ 2;
    final nextMatchId = roundMatchIds.length > 1
        ? roundMatchIds[1][nextMatchIdx]
        : null;
    final nextSlot = (i % 2 == 0) ? 1 : 2;
    final isBye = (team1 != null) != (team2 != null);
    final isEmpty = team1 == null && team2 == null;

    if (isEmpty) {
      allMatches.add({
        'matchId': matchId,
        'roundNo': 0,
        'roundName': roundName(0, roundMatchIds.length),
        'matchIndex': i,
        'teamId1': '', 'teamId2': '',
        'teamId1Name': '', 'teamId2Name': '',
        'teamId1OwnerUid': '', 'teamId2OwnerUid': '',
        'tossWonBy': '', 'batBowlFlag': 1,
        'noballFlag': 1, 'wideFlag': 1,
        'matchStartTime': null,
        'isBye': false, 'isGhost': true,
        'winnerId': '', 'winnerName': '',
        'isCompleted': false, 'status': 'ghost',
        'result': null,
        'completedAt': null,
        'nextMatchId': nextMatchId ?? '',
        'nextMatchSlot': nextSlot,
        'overs': 20, 'scheduledAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'bracketType': 'winners',
      });
      continue;
    }

    final autoWinner = isBye ? (team1 ?? team2)! : null;
    allMatches.add({
      'matchId': matchId,
      'roundNo': 0,
      'roundName': roundName(0, roundMatchIds.length),
      'matchIndex': i,
      'teamId1': team1?.teamId ?? '',
      'teamId2': team2?.teamId ?? '',
      'teamId1Name': team1?.teamName ?? '',
      'teamId2Name': team2?.teamName ?? '',
      'teamId1OwnerUid': team1?.ownerUid ?? '',
      'teamId2OwnerUid': team2?.ownerUid ?? '',
      'tossWonBy': '', 'batBowlFlag': 1,
      'noballFlag': 1, 'wideFlag': 1,
      'matchStartTime': null,
      'isBye': isBye, 'isGhost': false,
      'winnerId': isBye ? autoWinner!.teamId : '',
      'winnerName': isBye ? autoWinner!.teamName : '',
      'isCompleted': isBye,
      'status': isBye ? 'bye' : 'scheduled',
      'result': null,
      'completedAt': null,
      'nextMatchId': nextMatchId ?? '',
      'nextMatchSlot': nextSlot,
      'overs': 20, 'scheduledAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'bracketType': 'winners',
    });
  }

  for (int r = 1; r < roundMatchIds.length; r++) {
    for (int i = 0; i < roundMatchIds[r].length; i++) {
      final matchId = roundMatchIds[r][i];
      final nextMatchIdx = i ~/ 2;
      final nextMatchId = (r + 1 < roundMatchIds.length)
          ? roundMatchIds[r + 1][nextMatchIdx]
          : null;
      final nextSlot = (i % 2 == 0) ? 1 : 2;
      allMatches.add({
        'matchId': matchId,
        'roundNo': r,
        'roundName': roundName(r, roundMatchIds.length),
        'matchIndex': i,
        'teamId1': '', 'teamId2': '',
        'teamId1Name': 'TBD', 'teamId2Name': 'TBD',
        'teamId1OwnerUid': '', 'teamId2OwnerUid': '',
        'tossWonBy': '', 'batBowlFlag': 1,
        'noballFlag': 1, 'wideFlag': 1,
        'matchStartTime': null,
        'isBye': false, 'isGhost': false,
        'winnerId': '', 'winnerName': '',
        'isCompleted': false, 'status': 'pending',
        'result': null,
        'completedAt': null,
        'nextMatchId': nextMatchId ?? '',
        'nextMatchSlot': nextSlot,
        'overs': 20, 'scheduledAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'bracketType': 'winners',
      });
    }
  }

  _prefillByeWinners(allMatches);
  return allMatches;
}

void _prefillByeWinners(List<Map<String, dynamic>> allMatches) {
  final matchById = <String, Map<String, dynamic>>{};
  for (final m in allMatches) {
    matchById[m['matchId'] as String] = m;
  }
  for (final match in allMatches) {
    final isBye = (match['isBye'] as bool?) ?? false;
    if (!isBye) continue;
    final nextMatchId = (match['nextMatchId'] as String?) ?? '';
    final nextSlot = (match['nextMatchSlot'] as int?) ?? 1;
    final winnerId = (match['winnerId'] as String?) ?? '';
    final winnerName = (match['winnerName'] as String?) ?? '';
    if (nextMatchId.isEmpty || winnerId.isEmpty) continue;
    final nextMatch = matchById[nextMatchId];
    if (nextMatch == null) continue;
    if (nextSlot == 1) {
      nextMatch['teamId1'] = winnerId;
      nextMatch['teamId1Name'] = winnerName;
    } else {
      nextMatch['teamId2'] = winnerId;
      nextMatch['teamId2Name'] = winnerName;
    }
    final t1 = (nextMatch['teamId1'] as String?) ?? '';
    final t2 = (nextMatch['teamId2'] as String?) ?? '';
    if (t1.isNotEmpty && t2.isNotEmpty && nextMatch['status'] == 'pending') {
      nextMatch['status'] = 'scheduled';
    }
  }
}

// ─── DOUBLE ELIMINATION bracket generator ─────────────────────────────────
//
// Produces:
//   Winners Bracket  — standard single-elim rounds
//   Losers Bracket   — receives losers from WB each round
//   Grand Final      — WB champion vs LB champion
//
// Round numbering:
//   roundNo 0..WR-1   → Winners Bracket rounds
//   roundNo 100..     → Losers Bracket rounds  (offset 100)
//   roundNo 999       → Grand Final
//
// bracketType field: 'winners' | 'losers' | 'grand_final'
//
List<Map<String, dynamic>> generateDoubleEliminationBracket(
    List<TournamentTeam> teams) {
  final n = teams.length;
  if (n < 4) return [];

  final bracketSize = nextPowerOfTwo(n);
  final wbRounds = (math.log(bracketSize) / math.log(2)).round();

  // ── Step 1: build Winners Bracket (same as single elim) ──────────────
  final seeded = List<TournamentTeam?>.from(teams);
  while (seeded.length < bracketSize) seeded.add(null);

  // Generate IDs for all WB rounds
  final List<List<String>> wbMatchIds = [];
  int slots = bracketSize ~/ 2;
  while (slots >= 1) {
    wbMatchIds.add(List.generate(slots, (_) => _newId()));
    if (slots == 1) break;
    slots ~/= 2;
  }

  // Generate IDs for Losers Bracket
  final lbRoundCount = math.max(1, (wbRounds - 1) * 2);
  final List<List<String>> lbMatchIds = [];
  for (int r = 0; r < lbRoundCount; r++) {
    final lbSlots = (bracketSize ~/ 4) ~/ (1 << (r ~/ 2));
    final cnt = math.max(1, lbSlots);
    lbMatchIds.add(List.generate(cnt, (_) => _newId()));
  }

  // Grand Final ID
  final grandFinalId = _newId();

  final List<Map<String, dynamic>> allMatches = [];

  // ── Step 2: Winners Bracket matches ──────────────────────────────────
  for (int r = 0; r < wbMatchIds.length; r++) {
    for (int i = 0; i < wbMatchIds[r].length; i++) {
      final matchId = wbMatchIds[r][i];

      // Next WB match
      String nextWbMatchId = '';
      int nextWbSlot = 1;
      if (r + 1 < wbMatchIds.length) {
        nextWbMatchId = wbMatchIds[r + 1][i ~/ 2];
        nextWbSlot = (i % 2 == 0) ? 1 : 2;
      } else {
        // WB Final winner → Grand Final slot 1
        nextWbMatchId = grandFinalId;
        nextWbSlot = 1;
      }

      // Loser drops to LB
      final lbDropRound = r * 2;
      String loserNextMatchId = '';
      int loserNextSlot = 1;
      if (lbDropRound < lbMatchIds.length && i < lbMatchIds[lbDropRound].length) {
        loserNextMatchId = lbMatchIds[lbDropRound][i ~/ 2 < lbMatchIds[lbDropRound].length
            ? i ~/ 2
            : lbMatchIds[lbDropRound].length - 1];
        loserNextSlot = (i % 2 == 0) ? 2 : 1;
      }

      if (r == 0) {
        // Seed teams in round 0
        final seed1 = seeded[i];
        final seed2 = seeded[bracketSize - 1 - i];
        final isBye = (seed1 != null) != (seed2 != null);
        final isEmpty = seed1 == null && seed2 == null;
        final autoWinner = isBye ? (seed1 ?? seed2)! : null;

        if (isEmpty) {
          allMatches.add(_ghostMatch(matchId, r,
              'WB — ${_wbRoundLabel(r, wbRounds)}', i,
              nextWbMatchId, nextWbSlot, 'winners'));
          continue;
        }

        allMatches.add({
          'matchId': matchId,
          'roundNo': r,
          'roundName': 'WB — ${_wbRoundLabel(r, wbRounds)}',
          'matchIndex': i,
          'bracketType': 'winners',
          'teamId1': seed1?.teamId ?? '',
          'teamId2': seed2?.teamId ?? '',
          'teamId1Name': seed1?.teamName ?? '',
          'teamId2Name': seed2?.teamName ?? '',
          'teamId1OwnerUid': seed1?.ownerUid ?? '',
          'teamId2OwnerUid': seed2?.ownerUid ?? '',
          'tossWonBy': '', 'batBowlFlag': 1,
          'noballFlag': 1, 'wideFlag': 1,
          'matchStartTime': null,
          'isBye': isBye, 'isGhost': false,
          'winnerId': isBye ? autoWinner!.teamId : '',
          'winnerName': isBye ? autoWinner!.teamName : '',
          'isCompleted': isBye,
          'status': isBye ? 'bye' : 'scheduled',
          'result': null, 'completedAt': null,
          'nextMatchId': nextWbMatchId,
          'nextMatchSlot': nextWbSlot,
          'loserNextMatchId': loserNextMatchId,
          'loserNextMatchSlot': loserNextSlot,
          'overs': 20, 'scheduledAt': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        allMatches.add({
          'matchId': matchId,
          'roundNo': r,
          'roundName': 'WB — ${_wbRoundLabel(r, wbRounds)}',
          'matchIndex': i,
          'bracketType': 'winners',
          'teamId1': '', 'teamId2': '',
          'teamId1Name': 'TBD', 'teamId2Name': 'TBD',
          'teamId1OwnerUid': '', 'teamId2OwnerUid': '',
          'tossWonBy': '', 'batBowlFlag': 1,
          'noballFlag': 1, 'wideFlag': 1,
          'matchStartTime': null,
          'isBye': false, 'isGhost': false,
          'winnerId': '', 'winnerName': '',
          'isCompleted': false, 'status': 'pending',
          'result': null, 'completedAt': null,
          'nextMatchId': nextWbMatchId,
          'nextMatchSlot': nextWbSlot,
          'loserNextMatchId': loserNextMatchId,
          'loserNextMatchSlot': loserNextSlot,
          'overs': 20, 'scheduledAt': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // ── Step 3: Losers Bracket matches ───────────────────────────────────
  for (int r = 0; r < lbMatchIds.length; r++) {
    for (int i = 0; i < lbMatchIds[r].length; i++) {
      final matchId = lbMatchIds[r][i];

      String nextMatchId = '';
      int nextSlot = 1;
      if (r + 1 < lbMatchIds.length) {
        final nextIdx = i ~/ 2 < lbMatchIds[r + 1].length
            ? i ~/ 2
            : lbMatchIds[r + 1].length - 1;
        nextMatchId = lbMatchIds[r + 1][nextIdx];
        nextSlot = (i % 2 == 0) ? 1 : 2;
      } else {
        // Last LB round winner → Grand Final slot 2
        nextMatchId = grandFinalId;
        nextSlot = 2;
      }

      allMatches.add({
        'matchId': matchId,
        'roundNo': 100 + r,
        'roundName': 'LB — Round ${r + 1}',
        'matchIndex': i,
        'bracketType': 'losers',
        'teamId1': '', 'teamId2': '',
        'teamId1Name': 'TBD', 'teamId2Name': 'TBD',
        'teamId1OwnerUid': '', 'teamId2OwnerUid': '',
        'tossWonBy': '', 'batBowlFlag': 1,
        'noballFlag': 1, 'wideFlag': 1,
        'matchStartTime': null,
        'isBye': false, 'isGhost': false,
        'winnerId': '', 'winnerName': '',
        'isCompleted': false, 'status': 'pending',
        'result': null, 'completedAt': null,
        'nextMatchId': nextMatchId,
        'nextMatchSlot': nextSlot,
        'overs': 20, 'scheduledAt': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ── Step 4: Grand Final ───────────────────────────────────────────────
  allMatches.add({
    'matchId': grandFinalId,
    'roundNo': 999,
    'roundName': 'Grand Final',
    'matchIndex': 0,
    'bracketType': 'grand_final',
    'teamId1': '', 'teamId2': '',
    'teamId1Name': 'WB Champion', 'teamId2Name': 'LB Champion',
    'teamId1OwnerUid': '', 'teamId2OwnerUid': '',
    'tossWonBy': '', 'batBowlFlag': 1,
    'noballFlag': 1, 'wideFlag': 1,
    'matchStartTime': null,
    'isBye': false, 'isGhost': false,
    'winnerId': '', 'winnerName': '',
    'isCompleted': false, 'status': 'pending',
    'result': null, 'completedAt': null,
    'nextMatchId': '', 'nextMatchSlot': 0,
    'overs': 20, 'scheduledAt': null,
    'createdAt': FieldValue.serverTimestamp(),
  });

  _prefillByeWinners(allMatches);
  return allMatches;
}

Map<String, dynamic> _ghostMatch(String matchId, int roundNo,
    String rName, int matchIndex,
    String nextMatchId, int nextSlot, String bracketType) {
  return {
    'matchId': matchId,
    'roundNo': roundNo,
    'roundName': rName,
    'matchIndex': matchIndex,
    'bracketType': bracketType,
    'teamId1': '', 'teamId2': '',
    'teamId1Name': '', 'teamId2Name': '',
    'teamId1OwnerUid': '', 'teamId2OwnerUid': '',
    'tossWonBy': '', 'batBowlFlag': 1,
    'noballFlag': 1, 'wideFlag': 1,
    'matchStartTime': null,
    'isBye': false, 'isGhost': true,
    'winnerId': '', 'winnerName': '',
    'isCompleted': false, 'status': 'ghost',
    'result': null, 'completedAt': null,
    'nextMatchId': nextMatchId,
    'nextMatchSlot': nextSlot,
    'overs': 20, 'scheduledAt': null,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

String _wbRoundLabel(int r, int totalWbRounds) {
  final fromEnd = totalWbRounds - 1 - r;
  if (fromEnd == 0) return 'Final';
  if (fromEnd == 1) return 'Semi-Finals';
  if (fromEnd == 2) return 'Quarter-Finals';
  return 'Round ${r + 1}';
}

// ─── Schedule generator for league/round-robin formats ────────────────────
List<List<TournamentTeam>> generateScheduleFromTeams(
    String formatId, List<TournamentTeam> teams) {
  final n = teams.length;
  if (n < minTeamsForFormat(formatId)) return [];

  switch (formatId) {
    case 'league':
      // Single Round Robin: n(n-1)/2 matches — every pair plays once
      final matches = <List<TournamentTeam>>[];
      for (int i = 0; i < n; i++) {
        for (int j = i + 1; j < n; j++) {
          matches.add([teams[i], teams[j]]);
        }
      }
      return matches;

    case 'ipl_full_league':
      // Double Round Robin: n(n-1) matches — every pair plays home + away
      final matches = <List<TournamentTeam>>[];
      for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
          if (i != j) matches.add([teams[i], teams[j]]);
        }
      }
      return matches;

    case 'fifa_world_cup':
      // Handled separately via generateGroupStageMatches
      return [];

    case 'single_elimination':
    case 'double_elimination':
      // These use their dedicated bracket generators — not this function
      return [];

    default:
      return [];
  }
}

// ─── Group Stage match generator (FIFA World Cup) ─────────────────────────
List<Map<String, dynamic>> generateGroupStageMatches({
  required List<TournamentTeam> teams,
  required String tournamentId,
  required String createdByUid,
  int groupSize = 4,
}) {
  final n = teams.length;
  if (n < 4) return [];

  final numGroups = (n / groupSize).ceil();
  final List<Map<String, dynamic>> allMatches = [];

  for (int g = 0; g < numGroups; g++) {
    final start = g * groupSize;
    final end = (start + groupSize).clamp(0, n);
    if (end - start < 2) continue;
    final group = teams.sublist(start, end);
    final groupLabel = 'Group ${String.fromCharCode(65 + g)}';

    for (int i = 0; i < group.length; i++) {
      for (int j = i + 1; j < group.length; j++) {
        final ref = FirebaseFirestore.instance
            .collection('tournaments')
            .doc(tournamentId)
            .collection('matches')
            .doc();
        allMatches.add({
          'matchId': ref.id,
          'tournamentId': tournamentId,
          'teamId1': group[i].teamId,
          'teamId2': group[j].teamId,
          'teamId1Name': group[i].teamName,
          'teamId2Name': group[j].teamName,
          'teamId1OwnerUid': group[i].ownerUid,
          'teamId2OwnerUid': group[j].ownerUid,
          'overs': 20,
          'isCompleted': false,
          'status': 'scheduled',
          'scheduledAt': null,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': createdByUid,
          'format': 'fifa_world_cup',
          'roundNo': 0,
          'roundName': groupLabel,
          'group': groupLabel,
          'isBye': false,
          'isGhost': false,
          'bracketType': 'group',
        });
      }
    }
  }

  return allMatches;
}

// ─── Knockout phase from group standings (FIFA World Cup phase 2) ──────────
Future<List<Map<String, dynamic>>> generateKnockoutFromGroupStandings({
  required String tournamentId,
  required String createdByUid,
  int qualifiersPerGroup = 2,
}) async {
  final db = FirebaseFirestore.instance;

  final snap = await db
      .collection('tournaments')
      .doc(tournamentId)
      .collection('matches')
      .where('bracketType', isEqualTo: 'group')
      .get();

  if (snap.docs.isEmpty) return [];

  final Map<String, Map<String, Map<String, dynamic>>> groupStandings = {};

  for (final doc in snap.docs) {
    final data = doc.data();
    final group = (data['group'] as String?) ?? 'Group A';
    final isCompleted = (data['isCompleted'] as bool?) ?? false;
    if (!isCompleted) continue;

    final t1Id = (data['teamId1'] as String?) ?? '';
    final t2Id = (data['teamId2'] as String?) ?? '';
    final t1Name = (data['teamId1Name'] as String?) ?? '';
    final t2Name = (data['teamId2Name'] as String?) ?? '';
    final winnerId = (data['winnerId'] as String?) ?? '';

    groupStandings.putIfAbsent(group, () => {});

    void ensure(String id, String name) {
      groupStandings[group]!.putIfAbsent(id, () => {
        'teamName': name,
        'wins': 0,
        'losses': 0,
        'played': 0,
      });
    }

    ensure(t1Id, t1Name);
    ensure(t2Id, t2Name);

    if (winnerId.isNotEmpty) {
      final loserId = winnerId == t1Id ? t2Id : t1Id;
      groupStandings[group]![winnerId]!['wins'] =
          (groupStandings[group]![winnerId]!['wins'] as int) + 1;
      groupStandings[group]![loserId]!['losses'] =
          (groupStandings[group]![loserId]!['losses'] as int) + 1;
    }
    groupStandings[group]![t1Id]!['played'] =
        (groupStandings[group]![t1Id]!['played'] as int) + 1;
    groupStandings[group]![t2Id]!['played'] =
        (groupStandings[group]![t2Id]!['played'] as int) + 1;
  }

  final List<TournamentTeam> qualifiers = [];
  final sortedGroups = groupStandings.keys.toList()..sort();

  for (final group in sortedGroups) {
    final entries = groupStandings[group]!.entries.toList()
      ..sort((a, b) => (b.value['wins'] as int).compareTo(a.value['wins'] as int));
    final take = entries.take(qualifiersPerGroup);
    for (final e in take) {
      qualifiers.add(TournamentTeam(
        tournamentId: tournamentId,
        teamId: e.key,
        teamName: e.value['teamName'] as String,
        ownerUid: '',
        ownerName: '',
        playerCount: 0,
      ));
    }
  }

  if (qualifiers.length < 2) return [];

  final knockoutMatches = generateKnockoutBracket(qualifiers);

  for (final m in knockoutMatches) {
    m['format'] = 'fifa_world_cup';
    m['bracketType'] = 'knockout';
    m['tournamentId'] = tournamentId;
    m['createdBy'] = createdByUid;
  }

  return knockoutMatches;
}

// ─── IPL Playoff generator ─────────────────────────────────────────────────
Future<List<Map<String, dynamic>>> generateIPLPlayoffs({
  required String tournamentId,
  required String createdByUid,
}) async {
  final db = FirebaseFirestore.instance;

  final snap = await db
      .collection('tournaments')
      .doc(tournamentId)
      .collection('matches')
      .where('format', isEqualTo: 'ipl_full_league')
      .get();

  if (snap.docs.isEmpty) return [];

  final Map<String, Map<String, dynamic>> standings = {};

  for (final doc in snap.docs) {
    final data = doc.data();
    final isCompleted = (data['isCompleted'] as bool?) ?? false;
    if (!isCompleted) continue;

    final t1Id = (data['teamId1'] as String?) ?? '';
    final t2Id = (data['teamId2'] as String?) ?? '';
    final t1Name = (data['teamId1Name'] as String?) ?? '';
    final t2Name = (data['teamId2Name'] as String?) ?? '';
    final winnerId = (data['winnerId'] as String?) ?? '';

    void ensure(String id, String name) {
      standings.putIfAbsent(id, () => {
        'teamName': name,
        'wins': 0,
        'losses': 0,
        'played': 0,
        'points': 0,
      });
    }

    ensure(t1Id, t1Name);
    ensure(t2Id, t2Name);

    if (winnerId.isNotEmpty) {
      final loserId = winnerId == t1Id ? t2Id : t1Id;
      standings[winnerId]!['wins'] = (standings[winnerId]!['wins'] as int) + 1;
      standings[winnerId]!['points'] = (standings[winnerId]!['points'] as int) + 2;
      standings[loserId]!['losses'] = (standings[loserId]!['losses'] as int) + 1;
    }
    standings[t1Id]!['played'] = (standings[t1Id]!['played'] as int) + 1;
    standings[t2Id]!['played'] = (standings[t2Id]!['played'] as int) + 1;
  }

  final sorted = standings.entries.toList()
    ..sort((a, b) => (b.value['points'] as int).compareTo(a.value['points'] as int));

  if (sorted.length < 4) return [];

  final t = sorted.take(4).toList();

  TournamentTeam toTeam(MapEntry<String, Map<String, dynamic>> e) =>
      TournamentTeam(
        tournamentId: tournamentId,
        teamId: e.key,
        teamName: e.value['teamName'] as String,
        ownerUid: '', ownerName: '', playerCount: 0,
      );

  final team1 = toTeam(t[0]);
  final team2 = toTeam(t[1]);
  final team3 = toTeam(t[2]);
  final team4 = toTeam(t[3]);

  final q1Id = _newId();
  final elimId = _newId();
  final q2Id = _newId();
  final finalId = _newId();

  final now = FieldValue.serverTimestamp();

  return [
    // Qualifier 1
    {
      'matchId': q1Id,
      'tournamentId': tournamentId,
      'roundNo': 10, 'roundName': 'Qualifier 1',
      'matchIndex': 0,
      'bracketType': 'playoff',
      'teamId1': team1.teamId, 'teamId1Name': team1.teamName,
      'teamId2': team2.teamId, 'teamId2Name': team2.teamName,
      'teamId1OwnerUid': team1.ownerUid, 'teamId2OwnerUid': team2.ownerUid,
      'tossWonBy': '', 'batBowlFlag': 1, 'noballFlag': 1, 'wideFlag': 1,
      'matchStartTime': null, 'isBye': false, 'isGhost': false,
      'winnerId': '', 'winnerName': '',
      'isCompleted': false, 'status': 'scheduled',
      'result': null, 'completedAt': null,
      'nextMatchId': finalId, 'nextMatchSlot': 1,
      'loserNextMatchId': q2Id, 'loserNextMatchSlot': 1,
      'overs': 20, 'scheduledAt': null,
      'createdAt': now, 'createdBy': createdByUid,
      'format': 'ipl_full_league',
      'playoffNote': 'Winner → Final direct. Loser → Q2.',
    },
    // Eliminator
    {
      'matchId': elimId,
      'tournamentId': tournamentId,
      'roundNo': 10, 'roundName': 'Eliminator',
      'matchIndex': 1,
      'bracketType': 'playoff',
      'teamId1': team3.teamId, 'teamId1Name': team3.teamName,
      'teamId2': team4.teamId, 'teamId2Name': team4.teamName,
      'teamId1OwnerUid': team3.ownerUid, 'teamId2OwnerUid': team4.ownerUid,
      'tossWonBy': '', 'batBowlFlag': 1, 'noballFlag': 1, 'wideFlag': 1,
      'matchStartTime': null, 'isBye': false, 'isGhost': false,
      'winnerId': '', 'winnerName': '',
      'isCompleted': false, 'status': 'scheduled',
      'result': null, 'completedAt': null,
      'nextMatchId': q2Id, 'nextMatchSlot': 2,
      'loserNextMatchId': '', 'loserNextMatchSlot': 0,
      'overs': 20, 'scheduledAt': null,
      'createdAt': now, 'createdBy': createdByUid,
      'format': 'ipl_full_league',
      'playoffNote': 'Loser is eliminated.',
    },
    // Qualifier 2
    {
      'matchId': q2Id,
      'tournamentId': tournamentId,
      'roundNo': 11, 'roundName': 'Qualifier 2',
      'matchIndex': 0,
      'bracketType': 'playoff',
      'teamId1': '', 'teamId1Name': 'Loser of Q1',
      'teamId2': '', 'teamId2Name': 'Winner of Eliminator',
      'teamId1OwnerUid': '', 'teamId2OwnerUid': '',
      'tossWonBy': '', 'batBowlFlag': 1, 'noballFlag': 1, 'wideFlag': 1,
      'matchStartTime': null, 'isBye': false, 'isGhost': false,
      'winnerId': '', 'winnerName': '',
      'isCompleted': false, 'status': 'pending',
      'result': null, 'completedAt': null,
      'nextMatchId': finalId, 'nextMatchSlot': 2,
      'loserNextMatchId': '', 'loserNextMatchSlot': 0,
      'overs': 20, 'scheduledAt': null,
      'createdAt': now, 'createdBy': createdByUid,
      'format': 'ipl_full_league',
      'playoffNote': 'Winner → Final.',
    },
    // Final
    {
      'matchId': finalId,
      'tournamentId': tournamentId,
      'roundNo': 12, 'roundName': 'Final',
      'matchIndex': 0,
      'bracketType': 'playoff',
      'teamId1': '', 'teamId1Name': 'Winner of Q1',
      'teamId2': '', 'teamId2Name': 'Winner of Q2',
      'teamId1OwnerUid': '', 'teamId2OwnerUid': '',
      'tossWonBy': '', 'batBowlFlag': 1, 'noballFlag': 1, 'wideFlag': 1,
      'matchStartTime': null, 'isBye': false, 'isGhost': false,
      'winnerId': '', 'winnerName': '',
      'isCompleted': false, 'status': 'pending',
      'result': null, 'completedAt': null,
      'nextMatchId': '', 'nextMatchSlot': 0,
      'loserNextMatchId': '', 'loserNextMatchSlot': 0,
      'overs': 20, 'scheduledAt': null,
      'createdAt': now, 'createdBy': createdByUid,
      'format': 'ipl_full_league',
      'playoffNote': 'IPL Final.',
    },
  ];
}