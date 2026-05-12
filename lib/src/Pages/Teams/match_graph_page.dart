import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:TURF_TOWN_/src/models/match.dart';
import 'package:TURF_TOWN_/src/models/innings.dart';
import 'package:TURF_TOWN_/src/models/score.dart';
import 'package:TURF_TOWN_/src/models/batsman.dart';
import 'package:TURF_TOWN_/src/models/bowler.dart';
import 'package:TURF_TOWN_/src/models/team.dart';
import 'package:TURF_TOWN_/src/models/team_member.dart';
import 'package:TURF_TOWN_/src/CommonParameters/AppBackGround1/Appbg1.dart';
import 'dart:async';

class MatchGraphPage extends StatefulWidget {
  final String matchId;
  final String inningsId;

  const MatchGraphPage({
    Key? key,
    required this.matchId,
    required this.inningsId,
  }) : super(key: key);

  @override
  State<MatchGraphPage> createState() => _MatchGraphPageState();
}

class _MatchGraphPageState extends State<MatchGraphPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _updateTimer;
  
  Match? currentMatch;
  Innings? currentInnings;
  Innings? firstInnings;
  Innings? secondInnings;
  Score? currentScore;
  Score? firstInningsScore;
  Score? secondInningsScore;
  
  List<FlSpot> teamARunsProgression = [];
  List<FlSpot> teamBRunsProgression = [];
  List<Batsman> allBatsmen = [];
  List<Bowler> allBowlers = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMatchData();
    
    // Update graph every 2 seconds
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _loadMatchData();
        });
      }
    });
  }
  
  @override
  void dispose() {
    _updateTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }
  
  void _loadMatchData() {
    currentMatch = Match.getByMatchId(widget.matchId);
    currentInnings = Innings.getByInningsId(widget.inningsId);
    currentScore = Score.getByInningsId(widget.inningsId);
    
    // Load both innings data
    firstInnings = Innings.getFirstInnings(widget.matchId);
    if (firstInnings != null) {
      firstInningsScore = Score.getByInningsId(firstInnings!.inningsId);
      _buildRunsProgression(firstInnings!, firstInningsScore, isTeamA: true);
    }
    
    secondInnings = Innings.getSecondInnings(widget.matchId);
    if (secondInnings != null) {
      secondInningsScore = Score.getByInningsId(secondInnings!.inningsId);
      _buildRunsProgression(secondInnings!, secondInningsScore, isTeamA: false);
    }
    
    // Load batsmen and bowlers for current innings
    if (currentInnings != null) {
      allBatsmen = Batsman.getByInningsAndTeam(
        currentInnings!.inningsId,
        currentInnings!.battingTeamId,
      );
      allBowlers = Bowler.getByInningsAndTeam(
        currentInnings!.inningsId,
        currentInnings!.bowlingTeamId,
      );
    }
  }
  
  void _buildRunsProgression(Innings innings, Score? score, {required bool isTeamA}) {
    if (score == null) return;
    
    List<FlSpot> progression = [];
    
    // Start at 0
    progression.add(const FlSpot(0, 0));
    
    // Add current score point
    progression.add(FlSpot(score.overs, score.totalRuns.toDouble()));
    
    if (isTeamA) {
      teamARunsProgression = progression;
    } else {
      teamBRunsProgression = progression;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: Appbg1.mainGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRunsComparisonTab(),
                    _buildBatsmenStatsTab(),
                    _buildBowlersStatsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Match Statistics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 40), // For symmetry
        ],
      ),
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F24),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: Appbg1.mainGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF9AA0A6),
        tabs: const [
          Tab(text: 'Runs'),
          Tab(text: 'Batsmen'),
          Tab(text: 'Bowlers'),
        ],
      ),
    );
  }
  
  Widget _buildRunsComparisonTab() {
    if (currentMatch == null || currentInnings == null || currentScore == null) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    
    String teamAName = 'Team A';
    String teamBName = 'Team B';
    
    if (firstInnings != null) {
      final teamA = Team.getById(firstInnings!.battingTeamId);
      teamAName = teamA?.teamName ?? 'Team A';
    }
    
    if (secondInnings != null) {
      final teamB = Team.getById(secondInnings!.battingTeamId);
      teamBName = teamB?.teamName ?? 'Team B';
    } else if (firstInnings != null) {
      final teamB = Team.getById(firstInnings!.bowlingTeamId);
      teamBName = teamB?.teamName ?? 'Team B';
    }
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Title
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1F24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'SCORING COMPARISON',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(teamAName, const Color(0xFF42A5F5)),
                const SizedBox(width: 30),
                _buildLegendItem(teamBName, const Color(0xFFFF5252)),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Graph
            Container(
              height: 350,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1F24),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: _buildLineChart(),
            ),
            
            const SizedBox(height: 30),
            
            // Required runs info (if second innings)
            if (currentInnings!.isSecondInnings && currentInnings!.hasValidTarget)
              _buildRequiredRunsInfo(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 80,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              label.length > 6 ? label.substring(0, 6) : label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLineChart() {
  double maxOvers = currentMatch?.overs.toDouble() ?? 20.0;
  double maxRuns = 265; // Default max, will adjust based on data
  
  if (firstInningsScore != null && firstInningsScore!.totalRuns > maxRuns) {
    maxRuns = (firstInningsScore!.totalRuns + 50).toDouble();
  }
  if (secondInningsScore != null && secondInningsScore!.totalRuns > maxRuns) {
    maxRuns = (secondInningsScore!.totalRuns + 50).toDouble();
  }
  
  return LineChart(
    LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 55,
        verticalInterval: 2,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.white.withOpacity(0.15),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.white.withOpacity(0.15),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          axisNameWidget: const Text(
            'OVERS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          axisNameSize: 28, // Space for axis label
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30, // Space for axis values
            interval: 2,
            getTitlesWidget: (value, meta) {
              if (value % 2 != 0) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          axisNameWidget: const Text(
            'RUNS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          axisNameSize: 28, // Space for axis label
          sideTitles: SideTitles(
            showTitles: true,
            interval: 55,
            reservedSize: 45, // Space for axis values
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      minX: 0,
      maxX: maxOvers,
      minY: 0,
      maxY: maxRuns,
      lineBarsData: [
        // Team A line
        if (teamARunsProgression.isNotEmpty)
          LineChartBarData(
            spots: teamARunsProgression,
            isCurved: true,
            
            color: const Color(0xFF42A5F5),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 6,
                  color: const Color(0xFF42A5F5),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: false,
            ),
          ),
        // Team B line
        if (teamBRunsProgression.isNotEmpty)
          LineChartBarData(
            spots: teamBRunsProgression,
            isCurved: true,
            color: const Color(0xFFFF5252),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 6,
                  color: const Color(0xFFFF5252),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: false,
            ),
          ),
      ],
    ),
  );
}
  
  Widget _buildRequiredRunsInfo() {
    if (currentScore == null || currentInnings == null) return const SizedBox();
    
    int requiredRuns = currentInnings!.targetRuns - currentScore!.totalRuns;
    int remainingBalls = (currentMatch!.overs * 6) - currentScore!.currentBall;
    double requiredRPO = remainingBalls > 0 ? (requiredRuns / (remainingBalls / 6.0)) : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF9800),
          width: 2,
        ),
      ),
      child: Text(
        '(B) TEAM NEED $requiredRuns MORE TO WIN FROM ${(remainingBalls / 6.0).toStringAsFixed(1)} OVERS AT ${requiredRPO.toStringAsFixed(2)} RPO',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildBatsmenStatsTab() {
    if (allBatsmen.isEmpty) {
      return const Center(
        child: Text(
          'No batsmen data available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    
    // Sort by runs
    allBatsmen.sort((a, b) => b.runs.compareTo(a.runs));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            'BATSMEN PERFORMANCE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          
          // Batsmen list
          ...allBatsmen.map((batsman) {
            final player = TeamMember.getByPlayerId(batsman.playerId);
            return _buildBatsmanCard(batsman, player);
          }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildBatsmanCard(Batsman batsman, TeamMember? player) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: Appbg1.mainGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  player?.teamName ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (batsman.isOut)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5252),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'OUT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Runs', batsman.runs.toString(), const Color(0xFF42A5F5)),
              _buildStatItem('Balls', batsman.ballsFaced.toString(), const Color(0xFF66BB6A)),
              _buildStatItem('4s', batsman.fours.toString(), const Color(0xFFFFCA28)),
              _buildStatItem('6s', batsman.sixes.toString(), const Color(0xFFFF7043)),
              _buildStatItem('SR', batsman.strikeRate.toStringAsFixed(1), const Color(0xFFAB47BC)),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Runs bar
          _buildRunsBar(batsman.runs, allBatsmen.first.runs),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildRunsBar(int runs, int maxRuns) {
    double percentage = maxRuns > 0 ? (runs / maxRuns) : 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contribution',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildBowlersStatsTab() {
    if (allBowlers.isEmpty) {
      return const Center(
        child: Text(
          'No bowlers data available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    
    // Sort by wickets
    allBowlers.sort((a, b) => b.wickets.compareTo(a.wickets));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            'BOWLERS PERFORMANCE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          
          // Bowlers list
          ...allBowlers.map((bowler) {
            final player = TeamMember.getByPlayerId(bowler.playerId);
            return _buildBowlerCard(bowler, player);
          }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildBowlerCard(Bowler bowler, TeamMember? player) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: Appbg1.mainGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  player?.teamName ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (bowler.maidens > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'M: ${bowler.maidens}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Overs', bowler.overs.toStringAsFixed(1), const Color(0xFF42A5F5)),
              _buildStatItem('Runs', bowler.runsConceded.toString(), const Color(0xFFFF7043)),
              _buildStatItem('Wickets', bowler.wickets.toString(), const Color(0xFF66BB6A)),
              _buildStatItem('Economy', bowler.economy.toStringAsFixed(2), const Color(0xFFFFCA28)),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Economy rate bar
          _buildEconomyBar(bowler.economy),
        ],
      ),
    );
  }
  
  Widget _buildEconomyBar(double economy) {
    double percentage = economy / 15.0; // Max economy assumed as 15
    if (percentage > 1.0) percentage = 1.0;
    
    Color barColor;
    if (economy < 6.0) {
      barColor = const Color(0xFF66BB6A); // Green - excellent
    } else if (economy < 9.0) {
      barColor = const Color(0xFFFFCA28); // Yellow - good
    } else {
      barColor = const Color(0xFFFF5252); // Red - expensive
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Economy Rate',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}