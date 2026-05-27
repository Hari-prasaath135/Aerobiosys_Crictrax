// lib/src/services/player_stats_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:TURF_TOWN_/src/models/player_stats_model.dart';

class PlayerStatsService {
  PlayerStatsService._();
  static final instance = PlayerStatsService._();

  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── Entry point ────────────────────────────────────────────────────────────

  Future<PlayerStats> fetchStatsForPlayer(String playerId) async {
    if (_uid.isEmpty || playerId.isEmpty) return const PlayerStats();

    // Collect stats from all standalone matches
    final standaloneStats = await _fetchFromStandaloneMatches(playerId);

    // Collect stats from all tournaments
    final tournamentStats = await _fetchFromTournaments(playerId);

    return standaloneStats + tournamentStats;
  }

  // ── Standalone matches ─────────────────────────────────────────────────────

  Future<PlayerStats> _fetchFromStandaloneMatches(String playerId) async {
    PlayerStats result = const PlayerStats();
    try {
      final matchesSnap = await _db
          .collection('users')
          .doc(_uid)
          .collection('matches')
          .get();

      for (final matchDoc in matchesSnap.docs) {
        final matchId = matchDoc.id;
        final matchStats = await _fetchFromMatch(
          matchId: matchId,
          tournamentId: 'standalone',
          createdBy: _uid,
          playerId: playerId,
        );
        result = result + matchStats;
      }
    } catch (_) {}
    return result;
  }

  // ── Tournament matches ─────────────────────────────────────────────────────

  Future<PlayerStats> _fetchFromTournaments(String playerId) async {
    PlayerStats result = const PlayerStats();
    try {
      // Fetch all tournaments where this user is the creator
      final tournamentsSnap = await _db
          .collection('tournaments')
          .where('createdBy', isEqualTo: _uid)
          .get();

      for (final tDoc in tournamentsSnap.docs) {
        final tournamentId = tDoc.id;
        final matchesSnap = await _db
            .collection('tournaments')
            .doc(tournamentId)
            .collection('matches')
            .get();

        for (final matchDoc in matchesSnap.docs) {
          final matchStats = await _fetchFromMatch(
            matchId: matchDoc.id,
            tournamentId: tournamentId,
            createdBy: _uid,
            playerId: playerId,
          );
          result = result + matchStats;
        }
      }
    } catch (_) {}
    return result;
  }

  // ── Per-match aggregation ──────────────────────────────────────────────────

  Future<PlayerStats> _fetchFromMatch({
    required String matchId,
    required String tournamentId,
    required String createdBy,
    required String playerId,
  }) async {
    PlayerStats result = const PlayerStats();
    try {
      final base = tournamentId == 'standalone'
          ? _db.collection('users').doc(createdBy).collection('matches').doc(matchId)
          : _db.collection('tournaments').doc(tournamentId).collection('matches').doc(matchId);

      final inningsSnap = await base.collection('innings').get();

      for (final inningsDoc in inningsSnap.docs) {
        final inningsId = inningsDoc.id;

        // ── Batting stats ──
        final batSnap = await base
            .collection('innings')
            .doc(inningsId)
            .collection('batsmen')
            .where('playerId', isEqualTo: playerId)
            .get();

        for (final batDoc in batSnap.docs) {
          final data = batDoc.data();
          final runs = (data['runs'] as num?)?.toInt() ?? 0;
          final balls = (data['ballsFaced'] as num?)?.toInt() ?? 0;
          final isOut = data['isOut'] as bool? ?? false;
          final fours = (data['fours'] as num?)?.toInt() ?? 0;
          final sixes = (data['sixes'] as num?)?.toInt() ?? 0;
          final dismissalType = data['dismissalType'] as String?;

          // Fielding from dismissal
          // For stumpings: dismissalType == 'stumped' and fielderIdWhoRanOut == playerId
          // For run outs: dismissalType == 'run_out' and fielderIdWhoRanOut == playerId
          // These are counted when OTHER batsmen are dismissed — handled below

          result = result + PlayerStats(
            totalRuns: runs,
            totalInnings: 1,
            notOuts: isOut ? 0 : 1,
            hundreds: runs >= 100 ? 1 : 0,
            fifties: (runs >= 50 && runs < 100) ? 1 : 0,
            totalBallsFaced: balls,
            totalFours: fours,
            totalSixes: sixes,
          );
        }

        // ── Bowling stats ──
        final bowlSnap = await base
            .collection('innings')
            .doc(inningsId)
            .collection('bowlers')
            .where('playerId', isEqualTo: playerId)
            .get();

        for (final bowlDoc in bowlSnap.docs) {
          final data = bowlDoc.data();
          final wickets = (data['wickets'] as num?)?.toInt() ?? 0;
          final balls = (data['balls'] as num?)?.toInt() ?? 0;
          final runs = (data['runsConceded'] as num?)?.toInt() ?? 0;
          final maidens = (data['maidens'] as num?)?.toInt() ?? 0;

          result = result + PlayerStats(
            totalWickets: wickets,
            totalBallsBowled: balls,
            totalRunsConceded: runs,
            totalMaidens: maidens,
          );
        }

        // ── Fielding stats: scan ALL batsmen dismissals in this innings ──
        // A player gets fielding credit when they appear as fielderIdWhoRanOut
        // in ANOTHER player's batsman doc, or as bowlerIdWhoGotWicket for
        // caught-behind / caught types.
        final allBatSnap = await base
            .collection('innings')
            .doc(inningsId)
            .collection('batsmen')
            .get();

        int catches = 0;
        int stumpings = 0;
        int runOuts = 0;

        for (final doc in allBatSnap.docs) {
          final data = doc.data();
          final isOut = data['isOut'] as bool? ?? false;
          if (!isOut) continue;

          final dismissalType = (data['dismissalType'] as String? ?? '').toLowerCase();
          final fielder = data['fielderIdWhoRanOut'] as String?;
          final bowlerWhoGotWicket = data['bowlerIdWhoGotWicket'] as String?;

          if (dismissalType == 'caught' && bowlerWhoGotWicket == playerId) {
            // Bowler is credited — fielding catch goes to fielder if different
            // If no separate fielder field, credit as catch to the bowler
            catches++;
          }
          if (dismissalType == 'caught' && fielder == playerId && bowlerWhoGotWicket != playerId) {
            catches++;
          }
          if (dismissalType == 'stumped' && fielder == playerId) {
            stumpings++;
          }
          if (dismissalType == 'run_out' && fielder == playerId) {
            runOuts++;
          }
        }

        result = result + PlayerStats(
          catches: catches,
          stumpings: stumpings,
          runOuts: runOuts,
        );
      }
    } catch (_) {}
    return result;
  }
}