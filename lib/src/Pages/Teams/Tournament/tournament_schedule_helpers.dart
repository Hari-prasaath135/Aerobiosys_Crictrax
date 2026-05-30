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

List<List<int>> buildSeedPairs(int bracketSize) {
  List<int> seeds = List.generate(bracketSize, (i) => i + 1);
  List<List<int>> pairs = [];
  for (int i = 0; i < bracketSize ~/ 2; i++) {
    pairs.add([seeds[i], seeds[bracketSize - 1 - i]]);
  }
  return pairs;
}

List<Map<String, dynamic>> generateKnockoutBracket(
    List<TournamentTeam> teams) {
  final n = teams.length;
  if (n < 2) return [];

  final bracketSize = nextPowerOfTwo(n);
  final byes = bracketSize - n;
  final totalRounds = (math.log(bracketSize) / math.log(2)).round();

  final byeTeams = teams.sublist(0, byes);
  final playingTeams = teams.sublist(byes);

  final seedPairs = buildSeedPairs(bracketSize);

  final Map<int, TournamentTeam?> seedMap = {};
  for (int i = 0; i < byes; i++) {
    seedMap[i + 1] = byeTeams[i];
  }
  final playingSeeds = <int>[];
  for (int s = byes + 1; s <= bracketSize; s++) {
    playingSeeds.add(s);
  }
  for (int i = 0; i < playingTeams.length; i++) {
    seedMap[playingSeeds[i]] = playingTeams[i];
  }

  final List<List<String>> roundMatchIds = [];
  int matchesInRound = bracketSize ~/ 2;
  while (matchesInRound >= 1) {
    final ids = List.generate(matchesInRound,
        (_) => FirebaseFirestore.instance.collection('tournaments').doc().id);
    roundMatchIds.add(ids);
    if (matchesInRound == 1) break;
    matchesInRound ~/= 2;
  }

  final List<Map<String, dynamic>> allMatches = [];

  for (int i = 0; i < seedPairs.length; i++) {
    final pair = seedPairs[i];
    final seed1 = pair[0];
    final seed2 = pair[1];
    final team1 = seedMap[seed1];
    final team2 = seedMap[seed2];

    final matchId = roundMatchIds[0][i];
    final nextMatchIdx = i ~/ 2;
    final nextMatchId = roundMatchIds.length > 1
        ? roundMatchIds[1][nextMatchIdx]
        : null;

    final isBye = (team1 != null && team2 == null) ||
        (team1 == null && team2 != null);
    final autoWinner = isBye ? (team1 ?? team2) : null;

    allMatches.add({
      'matchId': matchId,
      'roundNo': 0,
      'roundName': roundName(0, roundMatchIds.length),
      'matchIndex': i,
      'teamId1': team1?.teamId ?? '',
      'teamId2': team2?.teamId ?? '',
      'teamId1Name': team1?.teamName ?? (team2 != null ? 'BYE' : ''),
      'teamId2Name': team2?.teamName ?? (team1 != null ? 'BYE' : ''),
      'teamId1OwnerUid': team1?.ownerUid ?? '',
      'teamId2OwnerUid': team2?.ownerUid ?? '',
      'tossWonBy': '',
      'batBowlFlag': 1,
      'noballFlag': 1,
      'wideFlag': 1,
      'matchStartTime': null,
      'isBye': isBye,
      'winnerId': isBye ? (autoWinner?.teamId ?? '') : '',
      'winnerName': isBye ? (autoWinner?.teamName ?? '') : '',
      'isCompleted': isBye,
      'status': isBye ? 'bye' : 'scheduled',
      'nextMatchId': nextMatchId ?? '',
      'nextMatchSlot': i % 2 == 0 ? 1 : 2,
      'seed1': seed1,
      'seed2': seed2,
      'overs': 20,
      'scheduledAt': null,
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
        'winnerId': '',
        'winnerName': '',
        'isCompleted': false,
        'status': 'pending',
        'nextMatchId': nextMatchId ?? '',
        'nextMatchSlot': i % 2 == 0 ? 1 : 2,
        'seed1': 0,
        'seed2': 0,
        'overs': 20,
        'scheduledAt': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  return allMatches;
}

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