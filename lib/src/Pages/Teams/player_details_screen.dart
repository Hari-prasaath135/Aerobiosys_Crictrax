import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlayerDetailsScreen extends StatefulWidget {
  final String teamName;
  final int playerCount;
  final int teamNumber;
  final Function(Map<String, dynamic>)? onTeamCreated;

  const PlayerDetailsScreen({
    super.key,
    required this.teamName,
    required this.playerCount,
    this.teamNumber = 1,
    this.onTeamCreated,
  });

  @override
  State<PlayerDetailsScreen> createState() => _PlayerDetailsScreenState();
}

class _PlayerDetailsScreenState extends State<PlayerDetailsScreen> {
  late List<TextEditingController> playerControllers;

  @override
  void initState() {
    super.initState();
    playerControllers = List.generate(
      widget.playerCount,
      (index) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (var controller in playerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _createTeam() {
    // Validate all player names
    for (int i = 0; i < playerControllers.length; i++) {
      if (playerControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter name for Player ${i + 1}!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Collect player names
    List<String> playerNames = playerControllers
        .map((controller) => controller.text.trim())
        .toList();

    // Create team data map
    Map<String, dynamic> teamData = {
      'team_name': widget.teamName,
      'player_count': widget.playerCount,
      'players': playerNames,
      'team_number': widget.teamNumber,
    };

    // Call callback if provided
    if (widget.onTeamCreated != null) {
      widget.onTeamCreated!(teamData);
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Team "${widget.teamName}" created successfully!'),
        backgroundColor: const Color(0xFF00C4FF),
        duration: const Duration(seconds: 2),
      ),
    );

    // Navigate back to main screen (TeamPage)
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF283593), Color(0xFF1A237E), Color(0xFF000000)],
            stops: [0.0, 0.0, 0.2],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;

              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(w * 0.04),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            '${widget.teamName} - Players',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: w * 0.055,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                      child: Column(
                        children: [
                          Text(
                            'Enter ${widget.playerCount} Player Names',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: w * 0.04,
                            ),
                          ),
                          SizedBox(height: h * 0.02),
                          ...List.generate(
                            widget.playerCount,
                            (index) => Padding(
                              padding: EdgeInsets.only(bottom: h * 0.015),
                              child: _buildPlayerInput(index, w),
                            ),
                          ),
                          SizedBox(height: h * 0.02),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.all(w * 0.04),
                    child: ElevatedButton(
                      onPressed: _createTeam,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C4FF),
                        padding: EdgeInsets.symmetric(vertical: w * 0.04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size(double.infinity, 0),
                        elevation: 10,
                      ),
                      child: Text(
                        'Create Team',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: w * 0.045,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerInput(int index, double w) {
    return Container(
      padding: EdgeInsets.all(w * 0.035),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: w * 0.12,
            height: w * 0.12,
            decoration: BoxDecoration(
              color: const Color(0xFF00C4FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: TextField(
              controller: playerControllers[index],
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: w * 0.04,
              ),
              decoration: InputDecoration(
                hintText: 'Player ${index + 1} name',
                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFF9E9E9E),
                ),
                filled: true,
                fillColor: const Color(0xFFD9D9D9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF00C4FF), width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: w * 0.03,
                  vertical: w * 0.025,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}