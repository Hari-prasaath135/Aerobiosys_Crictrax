import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'team.dart';
import 'team_member.dart';
import 'match.dart';
import 'innings.dart';
import 'score.dart';
import 'batsman.dart';
import 'bowler.dart';
import 'match_history.dart';
import './objectbox.g.dart';

class ObjectBoxHelper {
  static Store? _store;
  static Box<Team>? _teamBox;
  static Box<TeamMember>? _teamMemberBox;
  static Box<Match>? _matchBox;
  static Box<Innings>? _inningsBox;
  static Box<Score>? _scoreBox;
  static Box<Batsman>? _batsmanBox;
  static Box<Bowler>? _bowlerBox;
  static Box<MatchHistory>? _matchHistoryBox;

  /// Check if ObjectBox is initialized
  static bool get isInitialized => _store != null;

  /// Initialize ObjectBox store and boxes
  static Future<void> init() async {
    if (_store != null) {
      print('⚠️ ObjectBox already initialized');
      return;
    }

    try {
      print('🔄 Initializing ObjectBox...');
      
      final dir = await getApplicationDocumentsDirectory();
      final storePath = p.join(dir.path, 'objectbox');
      
      print('📁 Store path: $storePath');
      
      _store = await openStore(directory: storePath);
      _teamBox = _store!.box<Team>();
      _teamMemberBox = _store!.box<TeamMember>();
      _matchBox = _store!.box<Match>();
      _inningsBox = _store!.box<Innings>();
      _scoreBox = _store!.box<Score>();
      _batsmanBox = _store!.box<Batsman>();
      _bowlerBox = _store!.box<Bowler>();
      _matchHistoryBox = _store!.box<MatchHistory>();
      
      print('✅ ObjectBox initialized successfully');
      print('📊 Database Stats:');
      print('   - Teams: ${_teamBox!.count()}');
      print('   - Team Members: ${_teamMemberBox!.count()}');
      print('   - Matches: ${_matchBox!.count()}');
      print('   - Innings: ${_inningsBox!.count()}');
      print('   - Scores: ${_scoreBox!.count()}');
      print('   - Batsmen: ${_batsmanBox!.count()}');
      print('   - Bowlers: ${_bowlerBox!.count()}');
      print('   - Match Histories: ${_matchHistoryBox!.count()}');
    } catch (e, stackTrace) {
      print('❌ Failed to initialize ObjectBox: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get Team box (throws if not initialized)
  static Box<Team> get teamBox {
    if (_teamBox == null) {
      throw Exception(
        'ObjectBox not initialized. Call ObjectBoxHelper.init() first in main.dart'
      );
    }
    return _teamBox!;
  }

  /// Get TeamMember box (throws if not initialized)
  static Box<TeamMember> get teamMemberBox {
    if (_teamMemberBox == null) {
      throw Exception(
        'ObjectBox not initialized. Call ObjectBoxHelper.init() first in main.dart'
      );
    }
    return _teamMemberBox!;
  }

  /// Get Match box (throws if not initialized)
  static Box<Match> get matchBox {
    if (_matchBox == null) {
      throw Exception(
        'ObjectBox not initialized. Call ObjectBoxHelper.init() first in main.dart'
      );
    }
    return _matchBox!;
  }

  /// Get Innings box (throws if not initialized)
  static Box<Innings> get inningsBox {
    if (_inningsBox == null) {
      throw Exception(
        'ObjectBox not initialized. Call ObjectBoxHelper.init() first in main.dart'
      );
    }
    return _inningsBox!;
  }

  /// Get Score box (throws if not initialized)
  static Box<Score> get scoreBox {
    if (_scoreBox == null) {
      throw Exception(
        'ObjectBox not initialized. Call ObjectBoxHelper.init() first in main.dart'
      );
    }
    return _scoreBox!;
  }

  /// Get Batsman box (throws if not initialized)
  static Box<Batsman> get batsmanBox {
    if (_batsmanBox == null) {
      throw Exception(
        'ObjectBox not initialized. Call ObjectBoxHelper.init() first in main.dart'
      );
    }
    return _batsmanBox!;
  }

  /// Get Bowler box (throws if not initialized)
  static Box<Bowler> get bowlerBox {
    if (_bowlerBox == null) {
      throw Exception(
        'ObjectBox not initialized. Call ObjectBoxHelper.init() first in main.dart'
      );
    }
    return _bowlerBox!;
  }

  /// Get MatchHistory box (throws if not initialized)
  static Box<MatchHistory> get matchHistoryBox {
    if (_matchHistoryBox == null) {
      throw Exception(
        'ObjectBox not initialized. Call ObjectBoxHelper.init() first in main.dart'
      );
    }
    return _matchHistoryBox!;
  }

  /// Get Store instance
  static Store get store {
    if (_store == null) {
      throw Exception(
        'ObjectBox not initialized. Call ObjectBoxHelper.init() first in main.dart'
      );
    }
    return _store!;
  }

  /// Close the ObjectBox store
  static void close() {
    if (_store != null) {
      _store!.close();
      _store = null;
      _teamBox = null;
      _teamMemberBox = null;
      _matchBox = null;
      _inningsBox = null;
      _scoreBox = null;
      _batsmanBox = null;
      _bowlerBox = null;
      print('🔒 ObjectBox store closed');
    }
  }

  /// Clear all data from database (use carefully!)
/// Clear all data from database (use carefully!)
static void clearAllData() {
  if (_teamBox != null && _teamMemberBox != null && _matchBox != null &&
      _inningsBox != null && _scoreBox != null && _batsmanBox != null &&
      _bowlerBox != null && _matchHistoryBox != null) {
    _teamBox!.removeAll();
    _teamMemberBox!.removeAll();
    _matchBox!.removeAll();
    _inningsBox!.removeAll();
    _scoreBox!.removeAll();
    _batsmanBox!.removeAll();
    _bowlerBox!.removeAll();
    _matchHistoryBox!.removeAll();
    print('🗑️ All data cleared from ObjectBox');
  }
}

  /// Get database statistics
  /// Get database statistics
static Map<String, int> getStats() {
  if (_teamBox == null || _teamMemberBox == null || _matchBox == null ||
      _inningsBox == null || _scoreBox == null || _batsmanBox == null ||
      _bowlerBox == null || _matchHistoryBox == null) {
    return {
      'teams': 0,
      'teamMembers': 0,
      'matches': 0,
      'innings': 0,
      'scores': 0,
      'batsmen': 0,
      'bowlers': 0,
      'matchHistories': 0,
    };
  }
  
  return {
    'teams': _teamBox!.count(),
    'teamMembers': _teamMemberBox!.count(),
    'matches': _matchBox!.count(),
    'innings': _inningsBox!.count(),
    'scores': _scoreBox!.count(),
    'batsmen': _batsmanBox!.count(),
    'bowlers': _bowlerBox!.count(),
    'matchHistories': _matchHistoryBox!.count(),
  };
}

  /// Print database statistics
 /// Print database statistics
static void printStats() {
  final stats = getStats();
  print('📊 Database Statistics:');
  print('   Teams: ${stats['teams']}');
  print('   Team Members: ${stats['teamMembers']}');
  print('   Matches: ${stats['matches']}');
  print('   Innings: ${stats['innings']}');
  print('   Scores: ${stats['scores']}');
  print('   Batsmen: ${stats['batsmen']}');
  print('   Bowlers: ${stats['bowlers']}');
  print('   Match Histories: ${stats['matchHistories']}');
}

  /// Verify database integrity
 /// Verify database integrity
static bool verifyIntegrity() {
  try {
    if (!isInitialized) return false;
    
    // Try basic operations
    final teamCount = _teamBox!.count();
    final memberCount = _teamMemberBox!.count();
    final matchCount = _matchBox!.count();
    final inningsCount = _inningsBox!.count();
    final scoreCount = _scoreBox!.count();
    final batsmanCount = _batsmanBox!.count();
    final bowlerCount = _bowlerBox!.count();
    final matchHistoryCount = _matchHistoryBox!.count();
    
    print('✅ Database integrity check passed');
    print('   Teams: $teamCount, Members: $memberCount, Matches: $matchCount');
    print('   Innings: $inningsCount, Scores: $scoreCount');
    print('   Batsmen: $batsmanCount, Bowlers: $bowlerCount');
    print('   Match Histories: $matchHistoryCount');
    return true;
  } catch (e) {
    print('❌ Database integrity check failed: $e');
    return false;
  }
}
/// Clear match history data
static void clearMatchHistoryData() {
  if (_matchHistoryBox != null) {
    _matchHistoryBox!.removeAll();
    print('🗑️ Match history data cleared from ObjectBox');
  }
}

  /// Clear only match data
  static void clearMatchData() {
    if (_matchBox != null) {
      _matchBox!.removeAll();
      print('🗑️ Match data cleared from ObjectBox');
    }
  }

  /// Clear only team member data
  static void clearTeamMemberData() {
    if (_teamMemberBox != null) {
      _teamMemberBox!.removeAll();
      print('🗑️ Team member data cleared from ObjectBox');
    }
  }

  /// Clear only team data
  static void clearTeamData() {
    if (_teamBox != null) {
      _teamBox!.removeAll();
      print('🗑️ Team data cleared from ObjectBox');
    }
  }

  /// Clear innings data
  static void clearInningsData() {
    if (_inningsBox != null) {
      _inningsBox!.removeAll();
      print('🗑️ Innings data cleared from ObjectBox');
    }
  }

  /// Clear score data
  static void clearScoreData() {
    if (_scoreBox != null) {
      _scoreBox!.removeAll();
      print('🗑️ Score data cleared from ObjectBox');
    }
  }

  /// Clear batsman data
  static void clearBatsmanData() {
    if (_batsmanBox != null) {
      _batsmanBox!.removeAll();
      print('🗑️ Batsman data cleared from ObjectBox');
    }
  }

  /// Clear bowler data
  static void clearBowlerData() {
    if (_bowlerBox != null) {
      _bowlerBox!.removeAll();
      print('🗑️ Bowler data cleared from ObjectBox');
    }
  }

  /// Get detailed statistics
 /// Get detailed statistics
static Map<String, dynamic> getDetailedStats() {
  if (!isInitialized) {
    return {
      'initialized': false,
      'teams': 0,
      'teamMembers': 0,
      'matches': 0,
      'innings': 0,
      'scores': 0,
      'batsmen': 0,
      'bowlers': 0,
      'matchHistories': 0,
    };
  }

  return {
    'initialized': true,
    'teams': _teamBox!.count(),
    'teamMembers': _teamMemberBox!.count(),
    'matches': _matchBox!.count(),
    'innings': _inningsBox!.count(),
    'scores': _scoreBox!.count(),
    'batsmen': _batsmanBox!.count(),
    'bowlers': _bowlerBox!.count(),
    'matchHistories': _matchHistoryBox!.count(),
    'storePath': _store!.directoryPath,
  };
}
}