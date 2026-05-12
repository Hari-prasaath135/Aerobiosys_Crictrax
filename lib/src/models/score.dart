import 'package:TURF_TOWN_/src/models/objectbox.g.dart';
import 'package:objectbox/objectbox.dart';
import 'objectbox_helper.dart';

@Entity()
class Score {
  @Id()
  int id; // Auto-incremented by ObjectBox
  
  @Unique()
  String inningsId; // Foreign key to innings (one-to-one relationship)
  
  int totalRuns;
  int wickets;
  double overs;
  double crr; // Current run rate
  
  // ADDED: Individual extras tracking
  int wides;
  int noBalls;
  int byes;
  int legByes;
  
  // ADDED: Current match state tracking
  String strikeBatsmanId; // Current striker batsman ID
  String nonStrikeBatsmanId; // Current non-striker batsman ID
  String currentBowlerId; // Current bowler ID
  int currentBall; // Total balls bowled in the innings
  
  // ADDED: Current over tracking (stored as JSON string in ObjectBox)
  String _currentOverJson;
  
  Score({
    this.id = 0,
    required this.inningsId,
    this.totalRuns = 0,
    this.wickets = 0,
    this.overs = 0.0,
    this.crr = 0.0,
    this.wides = 0,
    this.noBalls = 0,
    this.byes = 0,
    this.legByes = 0,
    this.strikeBatsmanId = '',
    this.nonStrikeBatsmanId = '',
    this.currentBowlerId = '',
    this.currentBall = 0,
    String currentOverJson = '[]',
  }) : _currentOverJson = currentOverJson;

  // Getter and setter for currentOver (List<String>)
  List<String> get currentOver {
    if (_currentOverJson.isEmpty || _currentOverJson == '[]') {
      return [];
    }
    try {
      // Simple JSON parsing for list of strings
      final trimmed = _currentOverJson.trim();
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        final content = trimmed.substring(1, trimmed.length - 1);
        if (content.isEmpty) return [];
        
        return content
            .split(',')
            .map((s) => s.trim().replaceAll('"', '').replaceAll("'", ''))
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      print('Error parsing currentOver JSON: $e');
      return [];
    }
  }
  
  set currentOver(List<String> value) {
    if (value.isEmpty) {
      _currentOverJson = '[]';
    } else {
      // Simple JSON serialization for list of strings
      final items = value.map((s) => '"$s"').join(',');
      _currentOverJson = '[$items]';
    }
  }

  // Static methods for database operations
  
  /// Create a new score for an innings
  static Score create(String inningsId) {
    final score = Score(
      inningsId: inningsId,
      currentOverJson: '[]',
    );
    ObjectBoxHelper.scoreBox.put(score);
    return score;
  }
  
  /// Get all scores
  static List<Score> getAll() {
    return ObjectBoxHelper.scoreBox.getAll();
  }
  
  /// Get score by inningsId
  static Score? getByInningsId(String inningsId) {
    final query = ObjectBoxHelper.scoreBox
        .query(Score_.inningsId.equals(inningsId))
        .build();
    final score = query.findFirst();
    query.close();
    return score;
  }
  
  /// Delete score by inningsId
  static void deleteByInningsId(String inningsId) {
    final score = getByInningsId(inningsId);
    if (score != null) {
      ObjectBoxHelper.scoreBox.remove(score.id);
    }
  }
  
  // Instance methods
  
  /// Save the current score
  void save() {
    ObjectBoxHelper.scoreBox.put(this);
  }
  
  /// Delete the current score
  void delete() {
    ObjectBoxHelper.scoreBox.remove(id);
  }
  
  /// Update score after a ball
  void updateScore({
    required int runs,
    required bool isWicket,
    required bool countBall,
    int extraRuns = 0,
  }) {
    totalRuns += runs;
    
    if (isWicket) {
      wickets++;
    }
    
    if (countBall) {
      _incrementOvers();
    }
    
    _calculateCRR();
    save();
  }
  
  /// Increment overs (adds 0.1 for each ball)
  void _incrementOvers() {
    int completedOvers = (overs * 10).round() ~/ 10;
    int balls = ((overs * 10).round() % 10);
    
    balls++;
    if (balls >= 6) {
      completedOvers++;
      balls = 0;
    }
    
    overs = completedOvers + (balls / 10.0);
  }
  
  /// Calculate current run rate
  void _calculateCRR() {
    // Convert overs to actual decimal format for calculation
    int completedOvers = overs.toInt();
    int balls = ((overs - completedOvers) * 10).round();
    double actualOvers = completedOvers + (balls / 6.0);
    
    crr = actualOvers > 0 ? (totalRuns / actualOvers) : 0.0;
  }
  
  /// ADDED: Get formatted extras display string
  String get extrasDisplay {
    final total = wides + noBalls + byes + legByes;
    if (total == 0) return '0';
    
    List<String> parts = [];
    if (wides > 0) parts.add('wd $wides');
    if (noBalls > 0) parts.add('nb $noBalls');
    if (byes > 0) parts.add('b $byes');
    if (legByes > 0) parts.add('lb $legByes');
    
    return '$total (${parts.join(', ')})';
  }
  
  /// ADDED: Get total extras
  int get totalExtras => wides + noBalls + byes + legByes;
  
  /// Reset score
  void resetScore() {
    totalRuns = 0;
    wickets = 0;
    overs = 0.0;
    crr = 0.0;
    wides = 0;
    noBalls = 0;
    byes = 0;
    legByes = 0;
    currentBall = 0;
    currentOver = [];
    strikeBatsmanId = '';
    nonStrikeBatsmanId = '';
    currentBowlerId = '';
    save();
  }
  
  @override
  String toString() {
    return 'Score(inningsId: $inningsId, runs: $totalRuns, wickets: $wickets, overs: ${overs.toStringAsFixed(1)}, crr: ${crr.toStringAsFixed(2)})';
  }
}