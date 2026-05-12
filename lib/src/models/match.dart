import 'package:TURF_TOWN_/src/models/objectbox.g.dart';
import 'package:objectbox/objectbox.dart';
import 'objectbox_helper.dart';
import 'innings.dart';
import 'score.dart';
import 'team.dart';
import 'match_history.dart';

@Entity()
class Match {
  @Id()
  int id; // Auto-incremented by ObjectBox
  
  @Unique()
  String matchId; // Primary key (m_01, m_02, etc.)
  
  String teamId1; // Foreign key to first team
  String teamId2; // Foreign key to second team
  
  String tossWonBy; // teamId of the team that won the toss
  
  int batBowlFlag; // 0 = Bat first, 1 = Bowl first (decision by toss winner)
  int noballFlag; // 0 = No-ball allowed (true), 1 = No-ball not allowed (false)
  int wideFlag; // 0 = Wide allowed (true), 1 = Wide not allowed (false)
  int overs; // Number of overs for the match
  
  // NEW: Track match start time
  @Property(type: PropertyType.date)
  DateTime? matchStartTime;
  
  Match({
    this.id = 0,
    required this.matchId,
    required this.teamId1,
    required this.teamId2,
    required this.tossWonBy,
    required this.batBowlFlag,
    required this.noballFlag,
    required this.wideFlag,
    required this.overs,
    this.matchStartTime, // NEW
  });

  // Static methods for database operations
  
  /// Creates a new match with auto-generated matchId
  static Match create({
    required String teamId1,
    required String teamId2,
    required String tossWonBy,
    required int batBowlFlag,
    required int noballFlag,
    required int wideFlag,
    required int overs,
  }) {
    // Validate team IDs
    if (teamId1.trim().isEmpty || teamId2.trim().isEmpty) {
      throw Exception('Team IDs cannot be empty');
    }
    
    if (teamId1 == teamId2) {
      throw Exception('A team cannot play against itself');
    }
    
    // Validate toss winner is one of the two teams
    if (tossWonBy != teamId1 && tossWonBy != teamId2) {
      throw Exception('Toss winner must be one of the two teams playing');
    }
    
    // Validate flags
    if (batBowlFlag != 0 && batBowlFlag != 1) {
      throw Exception('Bat/Bowl flag must be 0 (bat) or 1 (bowl)');
    }
    
    if (noballFlag != 0 && noballFlag != 1) {
      throw Exception('No-ball flag must be 0 (allowed) or 1 (not allowed)');
    }
    
    if (wideFlag != 0 && wideFlag != 1) {
      throw Exception('Wide flag must be 0 (allowed) or 1 (not allowed)');
    }
    
    // Validate overs
    if (overs <= 0) {
      throw Exception('Overs must be greater than 0');
    }
    
    // Generate next matchId
    final matchId = _generateNextMatchId();
    
    final match = Match(
      matchId: matchId,
      teamId1: teamId1.trim(),
      teamId2: teamId2.trim(),
      tossWonBy: tossWonBy.trim(),
      batBowlFlag: batBowlFlag,
      noballFlag: noballFlag,
      wideFlag: wideFlag,
      overs: overs,
      matchStartTime: DateTime.now(), // NEW: Set start time on creation
    );
    
    ObjectBoxHelper.matchBox.put(match);
    return match;
  }
  
  /// Generates the next sequential match ID (m_01, m_02, etc.)
  static String _generateNextMatchId() {
    final allMatches = ObjectBoxHelper.matchBox.getAll();
    
    if (allMatches.isEmpty) {
      return 'm_01';
    }
    
    // Extract numeric parts and find the maximum
    int maxNum = 0;
    for (final match in allMatches) {
      final numStr = match.matchId.replaceAll('m_', '');
      final num = int.tryParse(numStr) ?? 0;
      if (num > maxNum) {
        maxNum = num;
      }
    }
    
    // Increment and format with leading zeros
    final nextNum = maxNum + 1;
    return 'm_${nextNum.toString().padLeft(2, '0')}';
  }
  
  /// Get all matches
  static List<Match> getAll() {
    return ObjectBoxHelper.matchBox.getAll();
  }
  
  /// Get a specific match by matchId
  static Match? getByMatchId(String matchId) {
    final query = ObjectBoxHelper.matchBox
        .query(Match_.matchId.equals(matchId))
        .build();
    final match = query.findFirst();
    query.close();
    return match;
  }
  
  /// Get all matches for a specific team (as team1 or team2)
  static List<Match> getByTeamId(String teamId) {
    final query = ObjectBoxHelper.matchBox
        .query(
          Match_.teamId1.equals(teamId) | Match_.teamId2.equals(teamId)
        )
        .build();
    final matches = query.find();
    query.close();
    return matches;
  }
  
  /// Get all matches between two specific teams
  static List<Match> getByBothTeams(String teamId1, String teamId2) {
    final query = ObjectBoxHelper.matchBox
        .query(
          (Match_.teamId1.equals(teamId1) & Match_.teamId2.equals(teamId2)) |
          (Match_.teamId1.equals(teamId2) & Match_.teamId2.equals(teamId1))
        )
        .build();
    final matches = query.find();
    query.close();
    return matches;
  }
  
  /// Get all matches won by a specific team at toss
  static List<Match> getByTossWinner(String teamId) {
    final query = ObjectBoxHelper.matchBox
        .query(Match_.tossWonBy.equals(teamId))
        .build();
    final matches = query.find();
    query.close();
    return matches;
  }
  
  /// Get matches by bat/bowl decision
  static List<Match> getByBatBowlDecision(int batBowlFlag) {
    final query = ObjectBoxHelper.matchBox
        .query(Match_.batBowlFlag.equals(batBowlFlag))
        .build();
    final matches = query.find();
    query.close();
    return matches;
  }
  
  /// Delete a match by matchId
  static void deleteByMatchId(String matchId) {
    final match = getByMatchId(matchId);
    if (match != null) {
      ObjectBoxHelper.matchBox.remove(match.id);
    }
  }
  
  /// Delete all matches for a specific team
  static void deleteByTeamId(String teamId) {
    final matches = getByTeamId(teamId);
    for (final match in matches) {
      ObjectBoxHelper.matchBox.remove(match.id);
    }
  }
  
  /// Get count of total matches
  static int getTotalMatchCount() {
    return ObjectBoxHelper.matchBox.count();
  }
  
  /// Get count of matches for a specific team
  static int getTeamMatchCount(String teamId) {
    final matches = getByTeamId(teamId);
    return matches.length;
  }
  
  // Instance methods
  
  /// Save the current match
  void save() {
    ObjectBoxHelper.matchBox.put(this);
  }
  
  /// Delete the current match
  void delete() {
    ObjectBoxHelper.matchBox.remove(id);
  }
  
  /// Save completed match to history
  void saveToHistory() {
    try {
      final firstInnings = Innings.getFirstInnings(matchId);
      final secondInnings = Innings.getSecondInnings(matchId);
      
      if (firstInnings == null || secondInnings == null) {
        print('❌ Cannot save to history: Missing innings data');
        return;
      }
      
      final firstScore = Score.getByInningsId(firstInnings.inningsId);
      final secondScore = Score.getByInningsId(secondInnings.inningsId);
      
      if (firstScore == null || secondScore == null) {
        print('❌ Cannot save to history: Missing score data');
        return;
      }
      
      // Check if already saved to history
      final existingHistory = MatchHistory.getByMatchId(matchId);
      if (existingHistory != null) {
        print('⚠️ Match already saved to history');
        return;
      }
      
      // Determine winner and result message
      String result;
      if (secondScore.totalRuns >= secondInnings.targetRuns) {
        // Team batting second (TeamB) met or exceeded target
        final team = Team.getById(secondInnings.battingTeamId);
        int wicketsRemaining = 10 - secondScore.wickets;
        result = '${team?.teamName ?? "Team B"} won by $wicketsRemaining wickets';
      } else {
        // Team batting first (TeamA) won - TeamB failed to chase
        final team = Team.getById(firstInnings.battingTeamId);
        int runsDifference = secondInnings.targetRuns - secondScore.totalRuns;
        result = '${team?.teamName ?? "Team A"} won by $runsDifference runs';
      }
      
      // Create match history entry with timing
      MatchHistory.create(
        matchId: matchId,
        teamAId: teamId1,
        teamBId: teamId2,
        matchDate: DateTime.now(),
        matchType: 'CRICKET',
        team1Runs: firstScore.totalRuns,
        team1Wickets: firstScore.wickets,
        team1Overs: firstScore.overs,
        team2Runs: secondScore.totalRuns,
        team2Wickets: secondScore.wickets,
        team2Overs: secondScore.overs,
        result: result,
        isCompleted: true,
        matchStartTime: matchStartTime, // NEW: Pass match start time
        matchEndTime: DateTime.now(), // NEW: Set end time
      );
      
      print('✅ Match saved to history successfully: $result');
    } catch (e) {
      print('❌ Error saving match to history: $e');
    }
  }
  
  /// Update toss winner
  void updateTossWinner(String newTossWinner) {
    if (newTossWinner != teamId1 && newTossWinner != teamId2) {
      throw Exception('Toss winner must be one of the two teams playing');
    }
    tossWonBy = newTossWinner;
    save();
  }
  
  /// Update bat/bowl decision
  void updateBatBowlDecision(int newBatBowlFlag) {
    if (newBatBowlFlag != 0 && newBatBowlFlag != 1) {
      throw Exception('Bat/Bowl flag must be 0 (bat) or 1 (bowl)');
    }
    batBowlFlag = newBatBowlFlag;
    save();
  }
  
  /// Update no-ball flag
  void updateNoballFlag(int newNoballFlag) {
    if (newNoballFlag != 0 && newNoballFlag != 1) {
      throw Exception('No-ball flag must be 0 (allowed) or 1 (not allowed)');
    }
    noballFlag = newNoballFlag;
    save();
  }
  
  /// Update wide flag
  void updateWideFlag(int newWideFlag) {
    if (newWideFlag != 0 && newWideFlag != 1) {
      throw Exception('Wide flag must be 0 (allowed) or 1 (not allowed)');
    }
    wideFlag = newWideFlag;
    save();
  }
  
  /// Update overs
  void updateOvers(int newOvers) {
    if (newOvers <= 0) {
      throw Exception('Overs must be greater than 0');
    }
    overs = newOvers;
    save();
  }
  
  // Getter methods for better readability
  
  /// Returns true if toss winner chose to bat first
  bool get isBattingFirst => batBowlFlag == 0;
  
  /// Returns true if toss winner chose to bowl first
  bool get isBowlingFirst => batBowlFlag == 1;
  
  /// Returns true if no-balls are allowed in this match
  bool get isNoballAllowed => noballFlag == 0;
  
  /// Returns true if wides are allowed in this match
  bool get isWideAllowed => wideFlag == 0;
  
  /// Get the opponent team ID
  String getOpponentTeamId(String teamId) {
    if (teamId == teamId1) return teamId2;
    if (teamId == teamId2) return teamId1;
    throw Exception('Team ID not found in this match');
  }
  
  /// Check if a specific team won the toss
  bool didTeamWinToss(String teamId) {
    return tossWonBy == teamId;
  }
  
  /// Get batting team ID (based on toss decision)
  String getBattingTeamId() {
    if (batBowlFlag == 0) {
      return tossWonBy; // Toss winner chose to bat
    } else {
      return getOpponentTeamId(tossWonBy); // Opponent bats
    }
  }
  
  /// Get bowling team ID (based on toss decision)
  String getBowlingTeamId() {
    if (batBowlFlag == 1) {
      return tossWonBy; // Toss winner chose to bowl
    } else {
      return getOpponentTeamId(tossWonBy); // Opponent bowls
    }
  }
  
  @override
  String toString() {
    return 'Match(id: $id, matchId: $matchId, team1: $teamId1, team2: $teamId2, '
           'tossWon: $tossWonBy, batBowl: ${isBattingFirst ? "Bat" : "Bowl"}, '
           'overs: $overs, '
           'noball: ${isNoballAllowed ? "Allowed" : "Not Allowed"}, '
           'wide: ${isWideAllowed ? "Allowed" : "Not Allowed"})';
  }
  
  /// Convert to map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matchId': matchId,
      'teamId1': teamId1,
      'teamId2': teamId2,
      'tossWonBy': tossWonBy,
      'batBowlFlag': batBowlFlag,
      'noballFlag': noballFlag,
      'wideFlag': wideFlag,
      'overs': overs,
      'matchStartTime': matchStartTime?.toIso8601String(), // NEW
    };
  }
}