import 'package:TURF_TOWN_/src/models/objectbox.g.dart';
import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';
import 'objectbox_helper.dart';

enum InningsType {
  first(1),
  second(2);
  
  final int value;
  const InningsType(this.value);
  
  static InningsType fromValue(int value) {
    return InningsType.values.firstWhere((e) => e.value == value);
  }
}

@Entity()
class Innings {
  @Id()
  int id;
  
  @Unique()
  String inningsId; // Primary key (UUID)
  
  String matchId; // Foreign key to Match
  String battingTeamId; // Foreign key to Team (team batting in this innings)
  String bowlingTeamId; // Foreign key to Team (team bowling in this innings)
  
  int inningsNumber; // 1 for 1st innings, 2 for 2nd innings (stored as int for ObjectBox)
  
  /// TARGET RUNS LOGIC:
  /// - First innings: targetRuns = 0 (not applicable, team is SETTING the target)
  /// - Second innings: targetRuns = firstInningsScore + 1 (runs needed to WIN)
  /// 
  /// IMPORTANT: Never check targetRuns for first innings win condition!
  /// First innings just accumulates score. Only second innings uses targetRuns.
  int targetRuns;
  
  bool isCompleted;
  
  Innings({
    this.id = 0,
    required this.inningsId,
    required this.matchId,
    required this.battingTeamId,
    required this.bowlingTeamId,
    this.inningsNumber = 1,
    this.targetRuns = 0,
    this.isCompleted = false,
  });
  
  // Getter and setter for enum
  InningsType get inningsType => InningsType.fromValue(inningsNumber);
  set inningsType(InningsType type) => inningsNumber = type.value;
  
  static const _uuid = Uuid();
  
  /// Create first innings
  /// targetRuns is set to 0 because first innings SETS the target, doesn't chase it
  static Innings createFirstInnings({
    required String matchId,
    required String battingTeamId,
    required String bowlingTeamId,
  }) {
    final innings = Innings(
      inningsId: _uuid.v4(),
      matchId: matchId,
      battingTeamId: battingTeamId,
      bowlingTeamId: bowlingTeamId,
      inningsNumber: InningsType.first.value,
      targetRuns: 0, // Not applicable - first innings sets the target
    );
    
    ObjectBoxHelper.inningsBox.put(innings);
    return innings;
  }
  
  /// Create second innings (teams switch roles)
  /// targetRuns = firstInningsScore + 1 (runs needed to win)
  /// Example: If Team A scored 150, Team B needs 151 to win
  static Innings createSecondInnings({
    required String matchId,
    required String battingTeamId, // Was bowling in first innings
    required String bowlingTeamId, // Was batting in first innings
    required int firstInningsScore, // Total runs scored by first batting team
  }) {
    final targetRuns = firstInningsScore + 1; // Runs needed to win
    
    final innings = Innings(
      inningsId: _uuid.v4(),
      matchId: matchId,
      battingTeamId: battingTeamId,
      bowlingTeamId: bowlingTeamId,
      inningsNumber: InningsType.second.value,
      targetRuns: targetRuns, // Chasing target
    );
    
    ObjectBoxHelper.inningsBox.put(innings);
    return innings;
  }
  
  /// Get runs needed to win (only meaningful for second innings)
  /// Returns null for first innings
  int? get runsNeededToWin {
    if (isSecondInnings && targetRuns > 0) {
      return targetRuns;
    }
    return null; // First innings doesn't have a target
  }
  
  /// Check if this innings has a valid target to chase
  /// Only true for second innings with targetRuns > 0
  bool get hasValidTarget => isSecondInnings && targetRuns > 0;
  
  /// Check if the current score meets or exceeds the target
  /// Only applicable for second innings
  /// WARNING: Do NOT use this for first innings!
  bool hasMetTarget(int currentScore) {
    if (!isSecondInnings) {
      throw Exception('Cannot check target for first innings! First innings sets the target.');
    }
    return currentScore >= targetRuns;
  }
  
  void save() {
    ObjectBoxHelper.inningsBox.put(this);
  }
  
  static Innings? getByInningsId(String inningsId) {
    final query = ObjectBoxHelper.inningsBox
        .query(Innings_.inningsId.equals(inningsId))
        .build();
    final innings = query.findFirst();
    query.close();
    return innings;
  }
  
  static List<Innings> getByMatchId(String matchId) {
    final query = ObjectBoxHelper.inningsBox
        .query(Innings_.matchId.equals(matchId))
        .build();
    final innings = query.find();
    query.close();
    return innings;
  }
  
  /// Get first innings for a match
  static Innings? getFirstInnings(String matchId) {
    final query = ObjectBoxHelper.inningsBox
        .query(Innings_.matchId.equals(matchId) & 
               Innings_.inningsNumber.equals(InningsType.first.value))
        .build();
    final innings = query.findFirst();
    query.close();
    return innings;
  }
  
  /// Get second innings for a match
  static Innings? getSecondInnings(String matchId) {
    final query = ObjectBoxHelper.inningsBox
        .query(Innings_.matchId.equals(matchId) & 
               Innings_.inningsNumber.equals(InningsType.second.value))
        .build();
    final innings = query.findFirst();
    query.close();
    return innings;
  }
  
  /// Check if this is first innings
  bool get isFirstInnings => inningsNumber == InningsType.first.value;
  
  /// Check if this is second innings
  bool get isSecondInnings => inningsNumber == InningsType.second.value;
  
  void markCompleted() {
    isCompleted = true;
    save();
  }
  
  @override
  String toString() {
    return 'Innings(inningsId: $inningsId, type: ${inningsType.name}, batting: $battingTeamId, bowling: $bowlingTeamId, target: $targetRuns)';
  }
}