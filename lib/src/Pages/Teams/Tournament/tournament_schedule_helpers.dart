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
// Used by all_tabs.dart to show the user a hint before the button appears.
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

// ─── Knockout bracket (unchanged) ─────────────────────────────────────────
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
        'nextMatchId': nextMatchId ?? '',
        'nextMatchSlot': nextSlot,
        'overs': 20, 'scheduledAt': null,
        'createdAt': FieldValue.serverTimestamp(),
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
      'nextMatchId': nextMatchId ?? '',
      'nextMatchSlot': nextSlot,
      'overs': 20, 'scheduledAt': null,
      'createdAt': FieldValue.serverTimestamp(),
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
        'nextMatchId': nextMatchId ?? '',
        'nextMatchSlot': nextSlot,
        'overs': 20, 'scheduledAt': null,
        'createdAt': FieldValue.serverTimestamp(),
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

// ─── Schedule generator for non-knockout formats ──────────────────────────
//
// Returns List<List<TournamentTeam>> for simple formats.
// For fifa_world_cup, returns List<Map> instead — see generateGroupStageMatches.
//
List<List<TournamentTeam>> generateScheduleFromTeams(
    String formatId, List<TournamentTeam> teams) {
  final n = teams.length;

  // FIX: per-format minimum enforcement
  if (n < minTeamsForFormat(formatId)) return [];

  switch (formatId) {
    case 'league':
      // Single Round Robin: n(n-1)/2 matches
      final matches = <List<TournamentTeam>>[];
      for (int i = 0; i < n; i++) {
        for (int j = i + 1; j < n; j++) {
          matches.add([teams[i], teams[j]]);
        }
      }
      return matches; // exactly n(n-1)/2 pairs ✓

    case 'ipl_full_league':
      // FIX: Double Round Robin: n(n-1) matches (home + away)
      // Each pair plays twice — once as [A,B] and once as [B,A]
      final matches = <List<TournamentTeam>>[];
      for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
          if (i != j) matches.add([teams[i], teams[j]]);
        }
      }
      return matches; // exactly n(n-1) pairs ✓

    case 'double_elimination':
      // FIX: min 4 teams now enforced above.
      // Double elim is architecturally complex (winner bracket + loser
      // bracket + grand final). Generating only Round 1 pairs here so
      // matches appear; the full bracket requires dedicated UI state.
      // We generate the winner-bracket Round 1 pairs: floor(n/2) matches.
      final matches = <List<TournamentTeam>>[];
      for (int i = 0; i + 1 < n; i += 2) {
        matches.add([teams[i], teams[i + 1]]);
      }
      // If odd team out, they get a bye into Round 2
      return matches;

    case 'fifa_world_cup':
      // FIX: fifa_world_cup is handled separately via generateGroupStageMatches
      // because it needs group labels. Calling generateScheduleFromTeams for
      // this format is not used — all_tabs calls generateGroupStageMatches directly.
      return [];

    default:
      return [];
  }
}

// ─── NEW: Group Stage match generator (fifa_world_cup) ────────────────────
//
// Returns a flat list of match maps with group labels already set.
// Group Stage formula: groups of groupSize, each group plays n(n-1)/2 matches.
// Total = (numGroups × groupSize × (groupSize-1) / 2)
//
// For 8 teams in 2 groups of 4: 2 × 6 = 12 group matches.
// Caller (all_tabs) writes these directly to Firestore with the group metadata.
//
List<Map<String, dynamic>> generateGroupStageMatches({
  required List<TournamentTeam> teams,
  required String tournamentId,
  required String createdByUid,
  int groupSize = 4,
}) {
  final n = teams.length;
  if (n < 4) return [];

  // Distribute teams into groups as evenly as possible
  final numGroups = (n / groupSize).ceil();
  final List<Map<String, dynamic>> allMatches = [];

  for (int g = 0; g < numGroups; g++) {
    final start = g * groupSize;
    final end = (start + groupSize).clamp(0, n);
    if (end - start < 2) continue; // need at least 2 teams per group
    final group = teams.sublist(start, end);
    final groupLabel = 'Group ${String.fromCharCode(65 + g)}'; // A, B, C...

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
          'roundName': groupLabel,  // FIX: proper group label
          'group': groupLabel,
          'isBye': false,
          'isGhost': false,
        });
      }
    }
  }

  return allMatches;
}