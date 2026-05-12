import 'package:TURF_TOWN_/src/models/match.dart';

/// Helper class for managing match storage operations using ObjectBox
class MatchStorage {
  /// Create a new match
  static Match createMatch({
    required String teamId1,
    required String teamId2,
    required String tossWonBy,
    required bool chooseToBat, // true = bat first, false = bowl first
    required bool allowNoball, // true = allow, false = don't allow
    required bool allowWide, // true = allow, false = don't allow
    required int overs, // number of overs for the match
  }) {
    return Match.create(
      teamId1: teamId1,
      teamId2: teamId2,
      tossWonBy: tossWonBy,
      batBowlFlag: chooseToBat ? 0 : 1,
      noballFlag: allowNoball ? 0 : 1,
      wideFlag: allowWide ? 0 : 1,
      overs: overs,
    );
  }

  /// Get a specific match by matchId
  static Match? getMatch(String matchId) {
    return Match.getByMatchId(matchId);
  }

  /// Get all matches
  static List<Match> getAllMatches() {
    return Match.getAll();
  }

  /// Get all matches for a specific team
  static List<Match> getTeamMatches(String teamId) {
    return Match.getByTeamId(teamId);
  }

  /// Get all matches between two teams
  static List<Match> getMatchesBetweenTeams(String teamId1, String teamId2) {
    return Match.getByBothTeams(teamId1, teamId2);
  }

  /// Get matches where a team won the toss
  static List<Match> getTossWinMatches(String teamId) {
    return Match.getByTossWinner(teamId);
  }

  /// Get matches where teams chose to bat first
  static List<Match> getBattingFirstMatches() {
    return Match.getByBatBowlDecision(0);
  }

  /// Get matches where teams chose to bowl first
  static List<Match> getBowlingFirstMatches() {
    return Match.getByBatBowlDecision(1);
  }

  /// Delete a specific match
  static void deleteMatch(String matchId) {
    Match.deleteByMatchId(matchId);
  }

  /// Delete all matches for a specific team
  static void deleteTeamMatches(String teamId) {
    Match.deleteByTeamId(teamId);
  }

  /// Get total count of matches
  static int getTotalMatchCount() {
    return Match.getTotalMatchCount();
  }

  /// Get count of matches for a specific team
  static int getTeamMatchCount(String teamId) {
    return Match.getTeamMatchCount(teamId);
  }

  /// Update toss winner for a match
  static void updateTossWinner(String matchId, String newTossWinner) {
    final match = Match.getByMatchId(matchId);
    if (match != null) {
      match.updateTossWinner(newTossWinner);
    }
  }

  /// Update bat/bowl decision
  static void updateBatBowlDecision(String matchId, bool chooseToBat) {
    final match = Match.getByMatchId(matchId);
    if (match != null) {
      match.updateBatBowlDecision(chooseToBat ? 0 : 1);
    }
  }

  /// Update no-ball flag
  static void updateNoballFlag(String matchId, bool allowNoball) {
    final match = Match.getByMatchId(matchId);
    if (match != null) {
      match.updateNoballFlag(allowNoball ? 0 : 1);
    }
  }

  /// Update wide flag
  static void updateWideFlag(String matchId, bool allowWide) {
    final match = Match.getByMatchId(matchId);
    if (match != null) {
      match.updateWideFlag(allowWide ? 0 : 1);
    }
  }

  /// Update overs
  static void updateOvers(String matchId, int overs) {
    final match = Match.getByMatchId(matchId);
    if (match != null) {
      match.updateOvers(overs);
    }
  }

  /// Get match details as a map
  static Map<String, dynamic>? getMatchDetails(String matchId) {
    final match = Match.getByMatchId(matchId);
    if (match == null) return null;

    return {
      'matchId': match.matchId,
      'teamId1': match.teamId1,
      'teamId2': match.teamId2,
      'tossWonBy': match.tossWonBy,
      'battingTeamId': match.getBattingTeamId(),
      'bowlingTeamId': match.getBowlingTeamId(),
      'chooseToBat': match.isBattingFirst,
      'chooseToBowl': match.isBowlingFirst,
      'noballAllowed': match.isNoballAllowed,
      'wideAllowed': match.isWideAllowed,
      'overs': match.overs,
      'dbId': match.id,
    };
  }

  /// Get match summary
  static String getMatchSummary(String matchId) {
    final match = Match.getByMatchId(matchId);
    if (match == null) return 'Match not found';

    final tossDecision = match.isBattingFirst
        ? 'chose to bat'
        : 'chose to bowl';
    final battingTeam = match.getBattingTeamId();
    final bowlingTeam = match.getBowlingTeamId();

    return '${match.matchId}: ${match.teamId1} vs ${match.teamId2}\n'
        'Overs: ${match.overs}\n'
        'Toss: ${match.tossWonBy} won and $tossDecision\n'
        'Batting: $battingTeam | Bowling: $bowlingTeam\n'
        'No-ball: ${match.isNoballAllowed ? "Allowed" : "Not Allowed"} | '
        'Wide: ${match.isWideAllowed ? "Allowed" : "Not Allowed"}';
  }

  /// Check if a match exists
  static bool matchExists(String matchId) {
    return Match.getByMatchId(matchId) != null;
  }

  static Match? getByMatchId(String matchId) {
    return Match.getByMatchId(matchId);
  }

  /// Get head-to-head statistics between two teams
  static Map<String, dynamic> getHeadToHeadStats(
    String teamId1,
    String teamId2,
  ) {
    final matches = Match.getByBothTeams(teamId1, teamId2);

    int team1TossWins = 0;
    int team2TossWins = 0;
    int team1BattedFirst = 0;
    int team2BattedFirst = 0;

    for (final match in matches) {
      if (match.tossWonBy == teamId1) {
        team1TossWins++;
      } else {
        team2TossWins++;
      }

      final battingTeam = match.getBattingTeamId();
      if (battingTeam == teamId1) {
        team1BattedFirst++;
      } else {
        team2BattedFirst++;
      }
    }

    return {
      'totalMatches': matches.length,
      'team1': teamId1,
      'team2': teamId2,
      'team1TossWins': team1TossWins,
      'team2TossWins': team2TossWins,
      'team1BattedFirst': team1BattedFirst,
      'team2BattedFirst': team2BattedFirst,
    };
  }

  /// Get team statistics
  static Map<String, dynamic> getTeamStats(String teamId) {
    final matches = Match.getByTeamId(teamId);

    int tossesWon = 0;
    int choseToBat = 0;
    int choseToBowl = 0;
    int battedFirst = 0;
    int bowledFirst = 0;

    for (final match in matches) {
      if (match.tossWonBy == teamId) {
        tossesWon++;
        if (match.isBattingFirst) {
          choseToBat++;
        } else {
          choseToBowl++;
        }
      }

      if (match.getBattingTeamId() == teamId) {
        battedFirst++;
      } else {
        bowledFirst++;
      }
    }

    return {
      'teamId': teamId,
      'totalMatches': matches.length,
      'tossesWon': tossesWon,
      'tossesLost': matches.length - tossesWon,
      'choseToBat': choseToBat,
      'choseToBowl': choseToBowl,
      'battedFirst': battedFirst,
      'bowledFirst': bowledFirst,
    };
  }

  /// Get recent matches (sorted by matchId descending)
  static List<Match> getRecentMatches({int limit = 10}) {
    final allMatches = Match.getAll();
    allMatches.sort((a, b) => b.matchId.compareTo(a.matchId));
    return allMatches.take(limit).toList();
  }

  /// Get matches by overs
  static List<Match> getMatchesByOvers(int overs) {
    final allMatches = Match.getAll();
    return allMatches.where((match) => match.overs == overs).toList();
  }

  /// Batch create matches
  static List<Match> batchCreateMatches(
    List<Map<String, dynamic>> matchDataList,
  ) {
    List<Match> createdMatches = [];

    for (var matchData in matchDataList) {
      try {
        final match = createMatch(
          teamId1: matchData['teamId1'],
          teamId2: matchData['teamId2'],
          tossWonBy: matchData['tossWonBy'],
          chooseToBat: matchData['chooseToBat'] ?? true,
          allowNoball: matchData['allowNoball'] ?? true,
          allowWide: matchData['allowWide'] ?? true,
          overs: matchData['overs'] ?? 20,
        );
        createdMatches.add(match);
      } catch (e) {
        print('Error creating match: $e');
      }
    }

    return createdMatches;
  }
}
