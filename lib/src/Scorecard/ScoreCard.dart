import 'package:flutter/material.dart';
import 'package:TURF_TOWN_/src/widgets/buttons.dart';
import 'package:TURF_TOWN_/src/CommonParameters/AppBackGround1/Appbg2.dart';
import 'package:TURF_TOWN_/src/models/ScoreController.dart';
import 'package:provider/provider.dart';
import 'package:TURF_TOWN_/src/models/ScoreManager.dart';
import 'package:TURF_TOWN_/src/widgets/Circular_button.dart';

class Board extends StatelessWidget {
  final String battingTeamName;
  final String bowlingTeamName;
  final String striker;
  final String nonStriker;
  final String bowler;

  const Board({
    super.key,
    required this.battingTeamName,
    required this.bowlingTeamName,
    required this.striker,
    required this.nonStriker,
    required this.bowler,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScoreController()),
        ChangeNotifierProvider(create: (_) => ScoreManager()),
      ],
      child: BoardScreen(
        battingTeamName: battingTeamName,
        bowlingTeamName: bowlingTeamName,
        striker: striker,
        nonStriker: nonStriker,
        bowler: bowler,
      ),
    );
  }
}

class BoardScreen extends StatefulWidget {
  final String battingTeamName;
  final String bowlingTeamName;
  final String striker;
  final String nonStriker;
  final String bowler;

  const BoardScreen({
    super.key,
    required this.battingTeamName,
    required this.bowlingTeamName,
    required this.striker,
    required this.nonStriker,
    required this.bowler,
  });

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  bool _isExtrasMenuOpen = false;

  void _toggleExtrasMenu() => setState(() => _isExtrasMenuOpen = !_isExtrasMenuOpen);

  // Calculate Current Run Rate
  double _calculateCRR(int runs, double overs) {
    if (overs == 0) return 0.0;
    return runs / overs;
  }

  // Calculate Net Run Rate (simplified - requires match context)
  double _calculateNRR(int runsScored, double oversPlayed, int runsConceded, double oversBowled) {
    if (oversPlayed == 0 || oversBowled == 0) return 0.0;
    double runRate = runsScored / oversPlayed;
    double oppRunRate = runsConceded / oversBowled;
    return runRate - oppRunRate;
  }

  // Calculate Bowling Economy
  double _calculateEconomy(int runsConceded, double oversBowled) {
    if (oversBowled == 0) return 0.0;
    return runsConceded / oversBowled;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    void _showExtraRunDialog(BuildContext context, String extraType) {
      showDialog(
        context: context,
        builder: (context) {
          final scoreController = context.read<ScoreController>();
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              extraType == 'NB'
                  ? 'No Ball Scored Runs'
                  : 'Wide Ball Scored Runs',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select the runs scored by the batsman (extra + runs):',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  children: List.generate(7, (i) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(20),
                        backgroundColor: Colors.blueAccent.shade700,
                      ),
                      onPressed: () {
                        scoreController.addExtra(extraType, i);
                        Navigator.pop(context);
                      },
                      child: Text(
                        '$i',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      );
    }

    void _showNewBowlerDialog(BuildContext context, ScoreManager scoreManager) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2C2A33),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "Over Completed",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Select the next bowler to continue.",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  scoreManager.resetOver();
                  Navigator.pop(context);
                },
                child: const Text(
                  "Continue",
                  style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
    }

    void _showNewBatsmanDialog(BuildContext context) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('New Batsman'),
          content: const Text('Select the new batsman to come in.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
       
        centerTitle: true,
        title: const Text(
          'Cricket Scorer',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            // Add your drawer/menu logic here
          },
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Appbg2(),
          Column(
            children: [
              const SizedBox(height: 120),

              _buildInfoCard(
                size,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTeamStats(),
                    _buildScore(context),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              _buildInfoCard(size, height: 118),

              const SizedBox(height: 30),
              Consumer<ScoreManager>(
                builder: (context, manager, _) {
                  return Container(
                    width: 350,
                    height: 60,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6E6679), Color(0xFF181719)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: false,
                      child: Row(
                        children: manager.ballsInOver.map((score) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.white.withOpacity(0.9),
                                child: Text(
                                  score,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              Container(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 100.0),
                      child: GradientButton(
                        label: '4',
                        onPressed: () {
                          final scoreController = context.read<ScoreController>();
                          final scoreManager = context.read<ScoreManager>();
                          scoreController.addRuns(4);
                          scoreManager.addBallScore('4', isLegal: true);
                          if (scoreManager.legalBalls == 6) {
                            Future.delayed(const Duration(milliseconds: 200), () {
                              _showNewBowlerDialog(context, scoreManager);
                            });
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 75.0),
                      child: GradientButton(
                        label: '3',
                        onPressed: () {
                          final scoreController = context.read<ScoreController>();
                          final scoreManager = context.read<ScoreManager>();
                          scoreController.addRuns(3);
                          scoreManager.addBallScore('3', isLegal: true);
                          if (scoreManager.legalBalls == 6) {
                            Future.delayed(const Duration(milliseconds: 200), () {
                              _showNewBowlerDialog(context, scoreManager);
                            });
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 50.0),
                      child: GradientButton(
                        label: '1',
                        onPressed: () {
                          final scoreController = context.read<ScoreController>();
                          final scoreManager = context.read<ScoreManager>();
                          scoreController.addRuns(1);
                          scoreManager.addBallScore('1', isLegal: true);
                          if (scoreManager.legalBalls == 6) {
                            Future.delayed(const Duration(milliseconds: 200), () {
                              _showNewBowlerDialog(context, scoreManager);
                            });
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 25.0),
                      child: GradientButton(
                        label: '0',
                        onPressed: () {
                          final scoreController = context.read<ScoreController>();
                          final scoreManager = context.read<ScoreManager>();
                          scoreController.addRuns(0);
                          scoreManager.addBallScore('*', isLegal: true);
                          if (scoreManager.legalBalls == 6) {
                            Future.delayed(const Duration(milliseconds: 200), () {
                              _showNewBowlerDialog(context, scoreManager);
                            });
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 50.0),
                      child: GradientButton(
                        label: '2',
                        onPressed: () {
                          final scoreController = context.read<ScoreController>();
                          final scoreManager = context.read<ScoreManager>();
                          scoreController.addRuns(2);
                          scoreManager.addBallScore('2', isLegal: true);
                          if (scoreManager.legalBalls == 6) {
                            Future.delayed(const Duration(milliseconds: 200), () {
                              _showNewBowlerDialog(context, scoreManager);
                            });
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 75),
                      child: GradientButton(
                        label: '5',
                        onPressed: () {
                          final scoreController = context.read<ScoreController>();
                          final scoreManager = context.read<ScoreManager>();
                          scoreController.addRuns(5);
                          scoreManager.addBallScore('5', isLegal: true);
                          if (scoreManager.legalBalls == 6) {
                            Future.delayed(const Duration(milliseconds: 200), () {
                              _showNewBowlerDialog(context, scoreManager);
                            });
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: GradientButton(
                        label: '6',
                        onPressed: () {
                          final scoreController = context.read<ScoreController>();
                          final scoreManager = context.read<ScoreManager>();
                          scoreController.addRuns(6);
                          scoreManager.addBallScore('6', isLegal: true);
                          if (scoreManager.legalBalls == 6) {
                            Future.delayed(const Duration(milliseconds: 200), () {
                              _showNewBowlerDialog(context, scoreManager);
                            });
                          }
                        },
                      ),
                    )
                  ],
                ),
              ),

              Center(
                child: GradientCircleButton(
                  label: 'W',
                  onPressed: () {
                    final scoreController = context.read<ScoreController>();
                    final scoreManager = context.read<ScoreManager>();

                    scoreController.addWicket(isLegal: true);
                    scoreManager.addBallScore('W', isLegal: true, runs: 0);

                    _showNewBatsmanDialog(context);

                    if (scoreManager.legalBalls == 6) {
                      Future.delayed(const Duration(milliseconds: 200), () {
                        _showNewBowlerDialog(context, scoreManager);
                      });
                    }
                  },
                ),
              ),
            ],
          ),

          if (_isExtrasMenuOpen)
            GestureDetector(
              onTap: _toggleExtrasMenu,
              child: Container(color: Colors.black.withOpacity(0.6)),
            ),

          _buildAnimatedRadialButton(
            label: 'Byes',
            left: 20,
            bottom: _isExtrasMenuOpen ? 180 : 20,
            visible: _isExtrasMenuOpen,
            onPressed: () {
              print('Byes pressed!');
              _toggleExtrasMenu();
            },
          ),
          _buildAnimatedRadialButton(
            label: 'Wide',
            left: _isExtrasMenuOpen ? 90 : 20,
            bottom: _isExtrasMenuOpen ? 100 : 20,
            visible: _isExtrasMenuOpen,
            onPressed: () {
              print('Wide pressed!');
              final scoreManager = context.read<ScoreManager>();
              scoreManager.addBallScore('WD', isLegal: false);
              _showExtraRunDialog(context, 'WD');
              _toggleExtrasMenu();
              if (scoreManager.legalBalls == 6) {
                Future.delayed(const Duration(milliseconds: 200), () {
                  _showNewBowlerDialog(context, scoreManager);
                });
              }
            },
          ),
          _buildAnimatedRadialButton(
            label: 'No Ball',
            left: _isExtrasMenuOpen ? 160 : 20,
            bottom: 20,
            visible: _isExtrasMenuOpen,
            onPressed: () {
              print('No Ball pressed!');
              final scoreManager = context.read<ScoreManager>();
              scoreManager.addBallScore('NB', isLegal: false);
              _showExtraRunDialog(context, 'NB');
              _toggleExtrasMenu();
              if (scoreManager.legalBalls == 6) {
                Future.delayed(const Duration(milliseconds: 200), () {
                  _showNewBowlerDialog(context, scoreManager);
                });
              }
            },
          ),

          Positioned(
            left: 20,
            bottom: 20,
            child: FloatingActionButton(
              onPressed: _toggleExtrasMenu,
              backgroundColor: Colors.white,
              shape: const CircleBorder(),
              child: const Text(
                'Extras',
                style: TextStyle(
                  color: Color(0xFF2A313B),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              onPressed: () => print('Undo pressed!'),
              backgroundColor: Colors.white,
              shape: const CircleBorder(),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.undo, color: Color(0xFF2A313B), size: 20),
                  Text(
                    'Undo',
                    style: TextStyle(
                      color: Color(0xFF2A313B),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Size size, {Widget? child, double height = 87}) {
    return Center(
      child: Container(
        width: size.width * 0.9,
        height: height + 4,
        decoration: BoxDecoration(
          color: const Color(0xFF2A313B),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: child,
      ),
    );
  }

  Widget _buildTeamStats() {
    return Consumer2<ScoreController, ScoreManager>(
      builder: (context, scoreController, scoreManager, _) {
        final totalRuns = scoreController.runs + scoreManager.totalRuns;
        final oversPlayed = scoreController.oversAsDouble;
        
        // Calculate CRR
        final crr = _calculateCRR(totalRuns, oversPlayed);
        
        // For demo: Assuming opponent scored 150 in 20 overs
        // You'll need to track this properly in your app
        final nrr = _calculateNRR(totalRuns, oversPlayed, 150, 20.0);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                widget.battingTeamName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'CRR : ${crr.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              'NRR : ${nrr.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScore(BuildContext context) {
    final scoreController = context.watch<ScoreController>();
    final scoreManager = context.watch<ScoreManager>();

    final totalScore = scoreController.runs + scoreManager.totalRuns;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${totalScore}-${scoreController.wickets}',
          style: const TextStyle(color: Colors.white, fontSize: 22),
        ),
        const SizedBox(height: 2),
        Text(
          '(${scoreController.overs})',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAnimatedRadialButton({
    required String label,
    required double left,
    required double bottom,
    required bool visible,
    required VoidCallback onPressed,
  }) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      left: left,
      bottom: bottom,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: visible ? 1.0 : 0.0,
        child: Visibility(
          visible: visible,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}