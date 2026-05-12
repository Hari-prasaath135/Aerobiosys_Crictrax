import 'package:flutter/material.dart';
import 'package:TURF_TOWN_/src/Score_widgets/buttons.dart';
import 'package:TURF_TOWN_/src/Score_widgets/score_buttons_row.dart'; // your ScoreButtonsRow widget

class ExtrasPopupDemo extends StatefulWidget {
  const ExtrasPopupDemo({super.key});

  @override
  State<ExtrasPopupDemo> createState() => _ExtrasPopupDemoState();
}

class _ExtrasPopupDemoState extends State<ExtrasPopupDemo> {
  void _showScorePopup(BuildContext context, String type) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white.withOpacity(0.95),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Enter runs for $type",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),

              // Using your existing score buttons row
              ScoreButtonsRow(
                onScoreSelected: (value) {
                  print("$type + $value runs");
                  Navigator.pop(context); // Close popup after selection
                },
              ),

              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Example UI to trigger popup
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Extras Popup Example")),
      body: Center(
        child: Wrap(
          spacing: 15,
          children: [
            ElevatedButton(
              onPressed: () => _showScorePopup(context, "Wide"),
              child: const Text("Wide"),
            ),
            ElevatedButton(
              onPressed: () => _showScorePopup(context, "No Ball"),
              child: const Text("No Ball"),
            ),
            ElevatedButton(
              onPressed: () => _showScorePopup(context, "Byes"),
              child: const Text("Byes"),
            ),
          ],
        ),
      ),
    );
  }
}
