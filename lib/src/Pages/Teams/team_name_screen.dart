import 'package:flutter/material.dart';

class TeamNameScreen extends StatefulWidget {
  final int teamNumber;
  final Function(Map<String, dynamic>) onTeamCreated;

  const TeamNameScreen({
    super.key,
    required this.teamNumber,
    required this.onTeamCreated,
  });

  @override
  State<TeamNameScreen> createState() => _TeamNameScreenState();
}

class _TeamNameScreenState extends State<TeamNameScreen> {
  final TextEditingController teamNameController = TextEditingController();
  final TextEditingController teamMembersController = TextEditingController();

  @override
  void dispose() {
    teamNameController.dispose();
    teamMembersController.dispose();
    super.dispose();
  }

  void _createTeam() {
    final teamName = teamNameController.text.trim();
    final teamMembers = teamMembersController.text.trim();

    if (teamName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter team name!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (teamMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter team members!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create team data
    final teamData = {
      'team_name': teamName,
      'team_members': teamMembers,
      'created_at': DateTime.now().toIso8601String(),
    };

    // Call the callback
    widget.onTeamCreated(teamData);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Team "$teamName" created successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate back
    Navigator.pop(context);
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
                  // Header
                  Padding(
                    padding: EdgeInsets.all(w * 0.04),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        SizedBox(width: w * 0.02),
                        Text(
                          'Create Team ${widget.teamNumber}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w * 0.055,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(w * 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: h * 0.02),

                          // Team Name
                          Text(
                            'Team Name',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: w * 0.045,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: h * 0.015),
                          TextField(
                            controller: teamNameController,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: w * 0.04,
                              fontFamily: 'Poppins',
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter team name',
                              hintStyle: TextStyle(
                                color: const Color(0xFF9E9E9E),
                                fontSize: w * 0.04,
                                fontFamily: 'Poppins',
                              ),
                              filled: true,
                              fillColor: const Color(0xFFD9D9D9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFF00C4FF), width: 2),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: w * 0.04,
                                vertical: w * 0.035,
                              ),
                            ),
                          ),

                          SizedBox(height: h * 0.03),

                          // Team Members
                          Text(
                            'Team Members',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: w * 0.045,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: h * 0.015),
                          TextField(
                            controller: teamMembersController,
                            maxLines: 5,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: w * 0.04,
                              fontFamily: 'Poppins',
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter team members (comma separated)',
                              hintStyle: TextStyle(
                                color: const Color(0xFF9E9E9E),
                                fontSize: w * 0.04,
                                fontFamily: 'Poppins',
                              ),
                              filled: true,
                              fillColor: const Color(0xFFD9D9D9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFF00C4FF), width: 2),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: w * 0.04,
                                vertical: w * 0.035,
                              ),
                            ),
                          ),

                          SizedBox(height: h * 0.02),

                          // Helper text
                          Text(
                            'Tip: Enter player names separated by commas',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: w * 0.032,
                              fontFamily: 'Poppins',
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Create Team Button
                  Padding(
                    padding: EdgeInsets.all(w * 0.04),
                    child: InkWell(
                      onTap: _createTeam,
                      borderRadius: BorderRadius.circular(22),
                      splashColor: Colors.white.withOpacity(0.3),
                      highlightColor: Colors.white.withOpacity(0.1),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C4FF),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: w * 0.04),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Create Team',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: w * 0.045,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: w * 0.02),
                              Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                                size: w * 0.06,
                              ),
                            ],
                          ),
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
}