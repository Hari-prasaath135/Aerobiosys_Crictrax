// lib/src/models/player_stats_model.dart

class PlayerStats {
  // Batting
  final int totalRuns;
  final int totalInnings;
  final int notOuts;
  final int hundreds;
  final int fifties;
  final int totalBallsFaced;
  final int totalFours;
  final int totalSixes;

  // Bowling
  final int totalWickets;
  final int totalBallsBowled;
  final int totalRunsConceded;
  final int totalMaidens;

  // Fielding
  final int catches;
  final int stumpings;
  final int runOuts;

  const PlayerStats({
    this.totalRuns = 0,
    this.totalInnings = 0,
    this.notOuts = 0,
    this.hundreds = 0,
    this.fifties = 0,
    this.totalBallsFaced = 0,
    this.totalFours = 0,
    this.totalSixes = 0,
    this.totalWickets = 0,
    this.totalBallsBowled = 0,
    this.totalRunsConceded = 0,
    this.totalMaidens = 0,
    this.catches = 0,
    this.stumpings = 0,
    this.runOuts = 0,
  });

  // ── Batting computed ──────────────────────────────────────────────────────

  double get battingAverage {
    final outs = totalInnings - notOuts;
    if (outs == 0) return totalRuns.toDouble();
    return totalRuns / outs;
  }

  double get strikeRate {
    if (totalBallsFaced == 0) return 0.0;
    return (totalRuns / totalBallsFaced) * 100;
  }

  // ── Bowling computed ──────────────────────────────────────────────────────

  double get economyRate {
    if (totalBallsBowled == 0) return 0.0;
    final overs = totalBallsBowled / 6.0;
    return totalRunsConceded / overs;
  }

  double get bowlingAverage {
    if (totalWickets == 0) return 0.0;
    return totalRunsConceded / totalWickets;
  }

  double get bowlingStrikeRate {
    if (totalWickets == 0) return 0.0;
    return totalBallsBowled / totalWickets;
  }

  PlayerStats operator +(PlayerStats other) => PlayerStats(
        totalRuns: totalRuns + other.totalRuns,
        totalInnings: totalInnings + other.totalInnings,
        notOuts: notOuts + other.notOuts,
        hundreds: hundreds + other.hundreds,
        fifties: fifties + other.fifties,
        totalBallsFaced: totalBallsFaced + other.totalBallsFaced,
        totalFours: totalFours + other.totalFours,
        totalSixes: totalSixes + other.totalSixes,
        totalWickets: totalWickets + other.totalWickets,
        totalBallsBowled: totalBallsBowled + other.totalBallsBowled,
        totalRunsConceded: totalRunsConceded + other.totalRunsConceded,
        totalMaidens: totalMaidens + other.totalMaidens,
        catches: catches + other.catches,
        stumpings: stumpings + other.stumpings,
        runOuts: runOuts + other.runOuts,
      );
}