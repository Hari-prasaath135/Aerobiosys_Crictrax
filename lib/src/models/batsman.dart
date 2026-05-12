import 'package:TURF_TOWN_/src/models/objectbox.g.dart';
import 'package:objectbox/objectbox.dart';
import 'objectbox_helper.dart';

@Entity()
class Batsman {
  @Id()
  int id; // Auto-incremented by ObjectBox
  
  @Unique()
  String batId; // Unique identifier (bat_01, bat_02, etc.)
  
  String inningsId; // Foreign key to innings
  String teamId; // Foreign key to team
  String playerId; // Foreign key to player
  
  int runs;
  int ballsFaced;
  int fours;
  int sixes;
  int dotBalls;
  int extras; // ADDED: Extras scored off this batsman
  double strikeRate;
  
  bool isOut;
  String? bowlerIdWhoGotWicket;
  String? dismissalType; // ADDED: 'bowled', 'caught', 'runout', 'lbw', etc.
  String? fielderIdWhoRanOut; // ADDED: Player ID of fielder who ran out
  
  Batsman({
    this.id = 0,
    required this.batId,
    required this.inningsId,
    required this.teamId,
    required this.playerId,
    this.runs = 0,
    this.ballsFaced = 0,
    this.fours = 0,
    this.sixes = 0,
    this.dotBalls = 0,
    this.extras = 0,
    this.strikeRate = 0.0,
    this.isOut = false,
    this.bowlerIdWhoGotWicket,
    this.dismissalType,
    this.fielderIdWhoRanOut,
  });

  // Static methods for database operations
  
  /// Generate next sequential batsman ID
  static String _generateNextBatId() {
    final allBatsmen = ObjectBoxHelper.batsmanBox.getAll();
    
    if (allBatsmen.isEmpty) {
      return 'bat_01';
    }
    
    int maxNum = 0;
    for (final batsman in allBatsmen) {
      final numStr = batsman.batId.replaceAll('bat_', '');
      final num = int.tryParse(numStr) ?? 0;
      if (num > maxNum) {
        maxNum = num;
      }
    }
    
    final nextNum = maxNum + 1;
    return 'bat_${nextNum.toString().padLeft(2, '0')}';
  }
  
  /// Create a new batsman
  static Batsman create({
    required String inningsId,
    required String teamId,
    required String playerId,
  }) {
    final batsman = Batsman(
      batId: _generateNextBatId(),
      inningsId: inningsId,
      teamId: teamId,
      playerId: playerId,
    );
    
    ObjectBoxHelper.batsmanBox.put(batsman);
    return batsman;
  }
  
  /// Get all batsmen
  static List<Batsman> getAll() {
    return ObjectBoxHelper.batsmanBox.getAll();
  }
  
  /// Get batsman by batId
  static Batsman? getByBatId(String batId) {
    final query = ObjectBoxHelper.batsmanBox
        .query(Batsman_.batId.equals(batId))
        .build();
    final batsman = query.findFirst();
    query.close();
    return batsman;
  }
  
  /// Get all batsmen for an innings
  static List<Batsman> getByInningsId(String inningsId) {
    final query = ObjectBoxHelper.batsmanBox
        .query(Batsman_.inningsId.equals(inningsId))
        .build();
    final batsmen = query.find();
    query.close();
    return batsmen;
  }
  
  /// Get all batsmen for a team in an innings
  static List<Batsman> getByInningsAndTeam(String inningsId, String teamId) {
    final query = ObjectBoxHelper.batsmanBox
        .query(
          Batsman_.inningsId.equals(inningsId) & 
          Batsman_.teamId.equals(teamId)
        )
        .build();
    final batsmen = query.find();
    query.close();
    return batsmen;
  }
  
  /// Get batsman by player ID in an innings
  static Batsman? getByInningsAndPlayer(String inningsId, String playerId) {
    final query = ObjectBoxHelper.batsmanBox
        .query(
          Batsman_.inningsId.equals(inningsId) & 
          Batsman_.playerId.equals(playerId)
        )
        .build();
    final batsman = query.findFirst();
    query.close();
    return batsman;
  }
  
  /// Delete batsman by batId
  static void deleteByBatId(String batId) {
    final batsman = getByBatId(batId);
    if (batsman != null) {
      ObjectBoxHelper.batsmanBox.remove(batsman.id);
    }
  }
  
  /// Delete all batsmen for an innings
  static void deleteByInningsId(String inningsId) {
    final batsmen = getByInningsId(inningsId);
    for (final batsman in batsmen) {
      ObjectBoxHelper.batsmanBox.remove(batsman.id);
    }
  }
  
  // Instance methods
  
  /// Save the current batsman
  void save() {
    ObjectBoxHelper.batsmanBox.put(this);
  }
  
  /// Delete the current batsman
  void delete() {
    ObjectBoxHelper.batsmanBox.remove(id);
  }
  
  /// Update stats after a ball - UPDATED with extras support
  void updateStats(
    int runsScored, {
    int extrasRuns = 0,
    bool countBall = true,
  }) {
    runs += runsScored;
    
    if (countBall) {
      ballsFaced++;
      if (runsScored == 0) dotBalls++;
    }
    
    if (runsScored == 4) fours++;
    if (runsScored == 6) sixes++;
    
    strikeRate = ballsFaced > 0 ? (runs * 100.0 / ballsFaced) : 0.0;
    save();
  }
  
  /// Undo last ball
  void undoStats(int runsScored) {
    runs -= runsScored;
    if (ballsFaced > 0) ballsFaced--;
    
    if (runsScored == 0 && dotBalls > 0) dotBalls--;
    if (runsScored == 4 && fours > 0) fours--;
    if (runsScored == 6 && sixes > 0) sixes--;
    
    strikeRate = ballsFaced > 0 ? (runs * 100.0 / ballsFaced) : 0.0;
    save();
  }
  
  /// Mark batsman as out - UPDATED
  void markAsOut({
    String? bowlerIdWhoGotWicket,
    String? dismissalType,
    String? fielderIdWhoRanOut,
  }) {
    isOut = true;
    this.bowlerIdWhoGotWicket = bowlerIdWhoGotWicket;
    this.dismissalType = dismissalType;
    this.fielderIdWhoRanOut = fielderIdWhoRanOut;
    save();
  }
  
  /// Mark batsman as not out
  void markAsNotOut() {
    isOut = false;
    bowlerIdWhoGotWicket = null;
    dismissalType = null;
    fielderIdWhoRanOut = null;
    save();
  }
  
  /// Reset stats
  void resetStats() {
    runs = 0;
    ballsFaced = 0;
    fours = 0;
    sixes = 0;
    dotBalls = 0;
    extras = 0;
    strikeRate = 0.0;
    isOut = false;
    bowlerIdWhoGotWicket = null;
    dismissalType = null;
    fielderIdWhoRanOut = null;
    save();
  }
  
  @override
  String toString() {
    return 'Batsman(batId: $batId, playerId: $playerId, runs: $runs, balls: $ballsFaced, SR: ${strikeRate.toStringAsFixed(2)})';
  }
}