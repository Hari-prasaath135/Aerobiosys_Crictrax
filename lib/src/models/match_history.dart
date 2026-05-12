import 'package:TURF_TOWN_/src/models/objectbox.g.dart';
import 'package:objectbox/objectbox.dart';
import 'package:flutter/foundation.dart';
import 'objectbox_helper.dart';
import 'innings.dart';

@Entity()
class MatchHistory {
  @Id()
  int id;

  @Unique()
  String matchId;

  String teamAId;
  String teamBId;

  @Property(type: PropertyType.date)
  DateTime matchDate;

  String matchType;

  int team1Runs;
  int team1Wickets;
  double team1Overs;

  int team2Runs;
  int team2Wickets;
  double team2Overs;

  String result;
  bool isCompleted;

  bool isPaused;
  bool isOnProgress; // true when app was closed/interrupted mid-match

  String? pausedState;

  @Property(type: PropertyType.date)
  DateTime? matchStartTime;

  @Property(type: PropertyType.date)
  DateTime? matchEndTime;

  MatchHistory({
    this.id = 0,
    required this.matchId,
    required this.teamAId,
    required this.teamBId,
    required this.matchDate,
    required this.matchType,
    required this.team1Runs,
    required this.team1Wickets,
    required this.team1Overs,
    required this.team2Runs,
    required this.team2Wickets,
    required this.team2Overs,
    required this.result,
    required this.isCompleted,
    this.isPaused = false,
    this.isOnProgress = false,
    this.pausedState,
    this.matchStartTime,
    this.matchEndTime,
  });

  // ── Static methods ────────────────────────────────────────────────────────

  /// Safe upsert: updates existing entry if matchId exists, creates new if not.
  /// This prevents UniqueViolationException and ensures each match has its own entry.
  static MatchHistory create({
    required String matchId,
    required String teamAId,
    required String teamBId,
    required DateTime matchDate,
    required String matchType,
    required int team1Runs,
    required int team1Wickets,
    required double team1Overs,
    required int team2Runs,
    required int team2Wickets,
    required double team2Overs,
    required String result,
    required bool isCompleted,
    bool isPaused = false,
    bool isOnProgress = false,
    String? pausedState,
    DateTime? matchStartTime,
    DateTime? matchEndTime,
  }) {
    final existing = getByMatchId(matchId);

    if (existing != null) {
      existing.teamAId = teamAId;
      existing.teamBId = teamBId;
      existing.matchDate = matchDate;
      existing.matchType = matchType;
      existing.team1Runs = team1Runs;
      existing.team1Wickets = team1Wickets;
      existing.team1Overs = team1Overs;
      existing.team2Runs = team2Runs;
      existing.team2Wickets = team2Wickets;
      existing.team2Overs = team2Overs;
      existing.result = result;
      existing.isCompleted = isCompleted;
      existing.isPaused = isPaused;
      existing.isOnProgress = isOnProgress;
      if (pausedState != null) existing.pausedState = pausedState;
      // Never overwrite matchStartTime if already set — preserve original start
      if (existing.matchStartTime == null && matchStartTime != null) {
        existing.matchStartTime = matchStartTime;
      }
      if (matchEndTime != null) existing.matchEndTime = matchEndTime;
      ObjectBoxHelper.matchHistoryBox.put(existing);
      debugPrint('✅ MatchHistory upserted (updated): matchId=$matchId');
      return existing;
    }

    final matchHistory = MatchHistory(
      matchId: matchId,
      teamAId: teamAId,
      teamBId: teamBId,
      matchDate: matchDate,
      matchType: matchType,
      team1Runs: team1Runs,
      team1Wickets: team1Wickets,
      team1Overs: team1Overs,
      team2Runs: team2Runs,
      team2Wickets: team2Wickets,
      team2Overs: team2Overs,
      result: result,
      isCompleted: isCompleted,
      isPaused: isPaused,
      isOnProgress: isOnProgress,
      pausedState: pausedState,
      matchStartTime: matchStartTime,
      matchEndTime: matchEndTime,
    );

    ObjectBoxHelper.matchHistoryBox.put(matchHistory);
    debugPrint('✅ MatchHistory created (new): matchId=$matchId');
    return matchHistory;
  }

  /// Clean up ghost entries that are neither paused nor completed nor on-progress.
  /// - Entries with no innings data are deleted entirely.
  /// - Entries with valid innings data but wrong flags are corrected to isOnProgress=true.
  static void cleanupStaleEntries() {
    final all = ObjectBoxHelper.matchHistoryBox.getAll();
    for (final entry in all) {
      if (!entry.isCompleted && !entry.isPaused && !entry.isOnProgress) {
        final innings = Innings.getFirstInnings(entry.matchId);
        if (innings == null) {
          // Completely orphaned entry — no innings data — delete it
          ObjectBoxHelper.matchHistoryBox.remove(entry.id);
          debugPrint(
            '🗑️ Deleted orphaned ghost entry: matchId=${entry.matchId}',
          );
        } else {
          // Has innings data but wrong flags — correct to on-progress
          entry.isOnProgress = true;
          entry.isPaused = false;
          entry.result = 'Match Interrupted';
          ObjectBoxHelper.matchHistoryBox.put(entry);
          debugPrint('🧹 Fixed stale entry to isOnProgress: matchId=${entry.matchId}');
        }
      }
    }
  }

  /// Get all match histories
  static List<MatchHistory> getAll() {
    return ObjectBoxHelper.matchHistoryBox.getAll();
  }

  /// Get match history by matchId
  static MatchHistory? getByMatchId(String matchId) {
    final query = ObjectBoxHelper.matchHistoryBox
        .query(MatchHistory_.matchId.equals(matchId))
        .build();
    final matchHistory = query.findFirst();
    query.close();
    return matchHistory;
  }

  /// Get on-progress matches (app was closed/interrupted mid-match)
  static List<MatchHistory> getOnProgressMatches() {
    final query = ObjectBoxHelper.matchHistoryBox
        .query(
          MatchHistory_.isOnProgress.equals(true) &
              MatchHistory_.isCompleted.equals(false),
        )
        .order(MatchHistory_.matchDate, flags: Order.descending)
        .build();
    final matches = query.find();
    query.close();
    return matches;
  }

  /// Get paused matches only (user explicitly saved and exited)
  static List<MatchHistory> getPausedMatches() {
    final query = ObjectBoxHelper.matchHistoryBox
        .query(
          MatchHistory_.isPaused.equals(true) &
              MatchHistory_.isOnProgress.equals(false) &
              MatchHistory_.isCompleted.equals(false),
        )
        .order(MatchHistory_.matchDate, flags: Order.descending)
        .build();
    final matches = query.find();
    query.close();
    return matches;
  }

  /// Get completed matches only (excludes paused and on-progress matches)
  static List<MatchHistory> getAllCompleted() {
    final query = ObjectBoxHelper.matchHistoryBox
        .query(
          MatchHistory_.isCompleted.equals(true) &
              MatchHistory_.isPaused.equals(false),
        )
        .order(MatchHistory_.matchDate, flags: Order.descending)
        .build();
    final matches = query.find();
    query.close();
    return matches;
  }

  /// Get completed matches (alias for backward compatibility)
  static List<MatchHistory> getCompletedMatches() {
    return getAllCompleted();
  }

  /// Get matches by team
  static List<MatchHistory> getMatchesByTeam(String teamId) {
    final query = ObjectBoxHelper.matchHistoryBox
        .query(
          MatchHistory_.teamAId
              .equals(teamId)
              .or(MatchHistory_.teamBId.equals(teamId)),
        )
        .build();
    final matches = query.find();
    query.close();
    return matches;
  }

  // ── Instance methods ──────────────────────────────────────────────────────

  /// Save the current match history
  void save() {
    ObjectBoxHelper.matchHistoryBox.put(this);
  }

  /// Delete the current match history
  void delete() {
    ObjectBoxHelper.matchHistoryBox.remove(id);
  }

  /// Mark match as completed and remove paused/on-progress state
  void markAsCompleted(String finalResult) {
    isCompleted = true;
    isPaused = false;
    isOnProgress = false;
    pausedState = null;
    result = finalResult;
    matchEndTime = DateTime.now();
    save();
  }

  /// Mark match as paused with state (user explicitly saved and exited)
  void markAsPaused(String stateJson) {
    isPaused = true;
    isOnProgress = false; // explicit save is NOT on-progress
    isCompleted = false;
    pausedState = stateJson;
    result = 'Match Paused';
    save();
  }

  /// Mark match as on-progress (app was interrupted/closed mid-match)
  void markAsOnProgress(String stateJson) {
    isOnProgress = true;
    isPaused = false;
    isCompleted = false;
    pausedState = stateJson;
    result = 'Match Interrupted';
    save();
  }
}