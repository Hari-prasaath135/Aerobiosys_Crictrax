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

/// Generates a new Firestore document ID
String _newId() =>
    FirebaseFirestore.instance.collection('_').doc().id;

/// Main knockout bracket generator.
/// Correctly handles byes: top seeds get byes, bottom seeds play first.
///
/// For 5 teams (bracketSize=8, byes=3):
///   Round 0 (Prelim): Seed4 vs Seed5  → 1 match
///   Round 1 (Semis):  Seed1 vs W(R0M0), Seed2 vs Seed3  → 2 matches
///   Round 2 (Final):  W(R1M0) vs W(R1M1)  → 1 match
///   Total: 4 matches ✅
List<Map<String, dynamic>> generateKnockoutBracket(
    List<TournamentTeam> teams) {
  final n = teams.length;
  if (n < 2) return [];

  final bracketSize = nextPowerOfTwo(n);
  final byes = bracketSize - n;
  final totalRounds = (math.log(bracketSize) / math.log(2)).round();

  // ── Step 1: Assign seeds ──────────────────────────────────────────
  // seeds[0] = top seed (Seed 1), seeds[n-1] = lowest seed
  final seeded = List<TournamentTeam?>.from(teams);
  // Pad to bracketSize with nulls (null = no team = bye slot)
  while (seeded.length < bracketSize) {
    seeded.add(null);
  }

  // ── Step 2: Build bracket slots using standard bracket ordering ───
  // Standard: Seed1 vs SeedN, Seed2 vs Seed(N-1), etc.
  // For 8-slot bracket: [1v8, 2v7, 3v6, 4v5]
  // With 5 teams: slots 6,7,8 are null
  // So matches: 1v8(null)=bye, 2v7(null)=bye, 3v6(null)=bye, 4v5=real
  // This means seeds 1,2,3 get byes and seeds 4,5 play ✅

  // ── Step 3: Pre-generate all match IDs round by round ─────────────
  // Round 0: bracketSize/2 slots (but many will be byes)
  // Round 1: bracketSize/4 slots
  // ...
  final List<List<String>> roundMatchIds = [];
  int slots = bracketSize ~/ 2;
  while (slots >= 1) {
    roundMatchIds.add(List.generate(slots, (_) => _newId()));
    if (slots == 1) break;
    slots ~/= 2;
  }

  final List<Map<String, dynamic>> allMatches = [];

  // ── Step 4: Generate Round 0 matches ─────────────────────────────
  // Pair seeds: [0 vs bracketSize-1], [1 vs bracketSize-2], ...
  final round0Count = bracketSize ~/ 2;
  for (int i = 0; i < round0Count; i++) {
    final seed1idx = i;                    // e.g. 0,1,2,3
    final seed2idx = bracketSize - 1 - i; // e.g. 7,6,5,4

    final team1 = seeded[seed1idx]; // null if no team
    final team2 = seeded[seed2idx]; // null if no team

    final matchId = roundMatchIds[0][i];
    final nextMatchIdx = i ~/ 2;
    final nextMatchId = roundMatchIds.length > 1
        ? roundMatchIds[1][nextMatchIdx]
        : null;
    final nextSlot = (i % 2 == 0) ? 1 : 2;

    // Bye: one team present, other is null
    final isBye = (team1 != null) != (team2 != null);
    // Empty: both null — skip this match entirely
    final isEmpty = team1 == null && team2 == null;

    if (isEmpty) {
      // Don't add this match — no teams involved at all
      // But we still need the ID slot for chaining, so add as ghost
      // Actually for correct chaining we still add it but mark hidden
      allMatches.add({
        'matchId': matchId,
        'roundNo': 0,
        'roundName': roundName(0, roundMatchIds.length),
        'matchIndex': i,
        'teamId1': '',
        'teamId2': '',
        'teamId1Name': '',
        'teamId2Name': '',
        'teamId1OwnerUid': '',
        'teamId2OwnerUid': '',
        'tossWonBy': '',
        'batBowlFlag': 1,
        'noballFlag': 1,
        'wideFlag': 1,
        'matchStartTime': null,
        'isBye': false,
        'isGhost': true, // hidden match, no real teams
        'winnerId': '',
        'winnerName': '',
        'isCompleted': false,
        'status': 'ghost',
        'nextMatchId': nextMatchId ?? '',
        'nextMatchSlot': nextSlot,
       'overs': null,
        'scheduledAt': null,
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
      'tossWonBy': '',
      'batBowlFlag': 1,
      'noballFlag': 1,
      'wideFlag': 1,
      'matchStartTime': null,
      'isBye': isBye,
      'isGhost': false,
      'winnerId': isBye ? autoWinner!.teamId : '',
      'winnerName': isBye ? autoWinner!.teamName : '',
      'isCompleted': isBye,
      'status': isBye ? 'bye' : 'scheduled',
      'nextMatchId': nextMatchId ?? '',
      'nextMatchSlot': nextSlot,
     'overs': null,
      'scheduledAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Step 5: Generate remaining rounds (Round 1+) ──────────────────
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
        'teamId1': '',
        'teamId2': '',
        'teamId1Name': 'TBD',
        'teamId2Name': 'TBD',
        'teamId1OwnerUid': '',
        'teamId2OwnerUid': '',
        'tossWonBy': '',
        'batBowlFlag': 1,
        'noballFlag': 1,
        'wideFlag': 1,
        'matchStartTime': null,
        'isBye': false,
        'isGhost': false,
        'winnerId': '',
        'winnerName': '',
        'isCompleted': false,
        'status': 'pending',
        'nextMatchId': nextMatchId ?? '',
        'nextMatchSlot': nextSlot,
       'overs': null,
        'scheduledAt': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ── Step 6: Pre-fill bye winners into next round slots ────────────
  // For each bye match in round 0, immediately set the winner
  // into the correct slot of the next round match
  _prefillByeWinners(allMatches);

  return allMatches;
}

/// After generating all matches, find bye matches and pre-fill
/// their winners into the next round match's teamId1/teamId2.
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

    // If BOTH slots of next match are now filled by byes, mark scheduled
    final t1 = (nextMatch['teamId1'] as String?) ?? '';
    final t2 = (nextMatch['teamId2'] as String?) ?? '';
    if (t1.isNotEmpty && t2.isNotEmpty && nextMatch['status'] == 'pending') {
      nextMatch['status'] = 'scheduled';
    }
  }
}

/// Also update the KnockoutBracketView to hide ghost matches.
/// In your KnockoutBracketView, filter out ghost matches:
///
/// final docs = snap.data?.docs ?? [];
/// // Add this filter:
/// final visibleDocs = docs.where((d) {
///   final data = d.data() as Map<String, dynamic>;
///   return (data['isGhost'] as bool?) != true
///       && (data['status'] as String?) != 'ghost';
/// }).toList();

List<List<TournamentTeam>> generateScheduleFromTeams(
    String formatId, List<TournamentTeam> teams) {
  final n = teams.length;
  if (n < 3) return [];

  switch (formatId) {
    case 'league':
    case 'ipl_full_league':
      final matches = <List<TournamentTeam>>[];
      for (int i = 0; i < n; i++) {
        for (int j = i + 1; j < n; j++) {
          matches.add([teams[i], teams[j]]);
        }
      }
      return matches;

    case 'double_elimination':
      final matches = <List<TournamentTeam>>[];
      for (int i = 0; i < n - 1; i += 2) {
        matches.add([teams[i], teams[i + 1]]);
      }
      return matches;

    case 'fifa_world_cup':
      final matches = <List<TournamentTeam>>[];
      const groupSize = 4;
      for (int g = 0; g * groupSize < n; g++) {
        final start = g * groupSize;
        final end = (start + groupSize).clamp(0, n);
        final group = teams.sublist(start, end);
        for (int i = 0; i < group.length; i++) {
          for (int j = i + 1; j < group.length; j++) {
            matches.add([group[i], group[j]]);
          }
        }
      }
      return matches;

    default:
      return [];
  }
}