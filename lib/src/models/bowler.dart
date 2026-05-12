import 'package:TURF_TOWN_/src/models/objectbox.g.dart';
import 'package:objectbox/objectbox.dart';
import 'objectbox_helper.dart';

@Entity()
class Bowler {
  @Id()
  int id; // Auto-incremented by ObjectBox
  
  @Unique()
  String bowlerId; // Unique identifier (bowl_01, bowl_02, etc.)
  
  String inningsId; // Foreign key to innings
  String teamId; // Foreign key to team
  String playerId; // Foreign key to player
  
  int runsConceded;
  int wickets;
  int balls;
  int maidens; // ADDED: Maiden overs count
  int extras; // ADDED: Extras conceded by this bowler
  double overs;
  double economy;
  
  Bowler({
    this.id = 0,
    required this.bowlerId,
    required this.inningsId,
    required this.teamId,
    required this.playerId,
    this.runsConceded = 0,
    this.wickets = 0,
    this.balls = 0,
    this.maidens = 0,
    this.extras = 0,
    this.overs = 0.0,
    this.economy = 0.0,
  });

  // Static methods for database operations
  
  /// Generate next sequential bowler ID
  static String _generateNextBowlerId() {
    final allBowlers = ObjectBoxHelper.bowlerBox.getAll();
    
    if (allBowlers.isEmpty) {
      return 'bowl_01';
    }
    
    int maxNum = 0;
    for (final bowler in allBowlers) {
      final numStr = bowler.bowlerId.replaceAll('bowl_', '');
      final num = int.tryParse(numStr) ?? 0;
      if (num > maxNum) {
        maxNum = num;
      }
    }
    
    final nextNum = maxNum + 1;
    return 'bowl_${nextNum.toString().padLeft(2, '0')}';
  }
  
  /// Create a new bowler
  static Bowler create({
    required String inningsId,
    required String teamId,
    required String playerId,
  }) {
    final bowler = Bowler(
      bowlerId: _generateNextBowlerId(),
      inningsId: inningsId,
      teamId: teamId,
      playerId: playerId,
    );
    
    ObjectBoxHelper.bowlerBox.put(bowler);
    return bowler;
  }
  
  /// Get all bowlers
  static List<Bowler> getAll() {
    return ObjectBoxHelper.bowlerBox.getAll();
  }
  
  /// Get bowler by bowlerId
  static Bowler? getByBowlerId(String bowlerId) {
    final query = ObjectBoxHelper.bowlerBox
        .query(Bowler_.bowlerId.equals(bowlerId))
        .build();
    final bowler = query.findFirst();
    query.close();
    return bowler;
  }
  
  /// Get all bowlers for an innings
  static List<Bowler> getByInningsId(String inningsId) {
    final query = ObjectBoxHelper.bowlerBox
        .query(Bowler_.inningsId.equals(inningsId))
        .build();
    final bowlers = query.find();
    query.close();
    return bowlers;
  }
  
  /// Get all bowlers for a team in an innings
  static List<Bowler> getByInningsAndTeam(String inningsId, String teamId) {
    final query = ObjectBoxHelper.bowlerBox
        .query(
          Bowler_.inningsId.equals(inningsId) & 
          Bowler_.teamId.equals(teamId)
        )
        .build();
    final bowlers = query.find();
    query.close();
    return bowlers;
  }
  
  /// Get bowler by player ID in an innings
  static Bowler? getByInningsAndPlayer(String inningsId, String playerId) {
    final query = ObjectBoxHelper.bowlerBox
        .query(
          Bowler_.inningsId.equals(inningsId) & 
          Bowler_.playerId.equals(playerId)
        )
        .build();
    final bowler = query.findFirst();
    query.close();
    return bowler;
  }
  
  /// Delete bowler by bowlerId
  static void deleteByBowlerId(String bowlerId) {
    final bowler = getByBowlerId(bowlerId);
    if (bowler != null) {
      ObjectBoxHelper.bowlerBox.remove(bowler.id);
    }
  }
  
  /// Delete all bowlers for an innings
  static void deleteByInningsId(String inningsId) {
    final bowlers = getByInningsId(inningsId);
    for (final bowler in bowlers) {
      ObjectBoxHelper.bowlerBox.remove(bowler.id);
    }
  }
  
  // Instance methods
  
  /// Save the current bowler
  void save() {
    ObjectBoxHelper.bowlerBox.put(this);
  }
  
  /// Delete the current bowler
  void delete() {
    ObjectBoxHelper.bowlerBox.remove(id);
  }
  
  /// Update stats after a ball - UPDATED with extras support
  void updateStats(
    int runsScored,
    bool isWicket, {
    int extrasRuns = 0,
    bool countBall = true,
  }) {
    runsConceded += runsScored;
    if (isWicket) {
      wickets++;
    }
    
    if (countBall) {
      balls++;
      _calculateOvers();
      _calculateEconomy();
    }
    
    save();
  }
  
  /// Undo last ball
  void undoBall(int runsScored, bool wasWicket) {
    runsConceded -= runsScored;
    if (wasWicket && wickets > 0) {
      wickets--;
    }
    if (balls > 0) {
      balls--;
    }
    _calculateOvers();
    _calculateEconomy();
    save();
  }
  
  /// Calculate overs from balls
  void _calculateOvers() {
    int completedOvers = balls ~/ 6;
    int remainingBalls = balls % 6;
    overs = completedOvers + (remainingBalls / 10.0);
  }
  
  /// Calculate economy rate
  void _calculateEconomy() {
    // Convert overs back to decimal overs for economy calculation
    int completedOvers = balls ~/ 6;
    int remainingBalls = balls % 6;
    double totalOvers = completedOvers + (remainingBalls / 6.0);
    
    economy = totalOvers > 0 ? (runsConceded / totalOvers) : 0.0;
  }
  
  /// Increment maiden over count
  void incrementMaiden() {
    maidens++;
    save();
  }
  
  /// Reset stats
  void resetStats() {
    runsConceded = 0;
    wickets = 0;
    balls = 0;
    maidens = 0;
    extras = 0;
    overs = 0.0;
    economy = 0.0;
    save();
  }
  
  @override
  String toString() {
    return 'Bowler(bowlerId: $bowlerId, playerId: $playerId, wickets: $wickets, runs: $runsConceded, overs: $overs, econ: ${economy.toStringAsFixed(2)})';
  }
}