import 'package:flutter/material.dart';

class MatchSettingsPage extends StatefulWidget {
  final bool? currentAllowNoball;
  final bool? currentAllowWide;

  const MatchSettingsPage({
    super.key,
    this.currentAllowNoball,
    this.currentAllowWide,
  });

  @override
  State<MatchSettingsPage> createState() => _MatchSettingsPageState();
}

class _MatchSettingsPageState extends State<MatchSettingsPage> {
  bool allowNoball = true;
  bool allowWide = true;

  @override
  void initState() {
    super.initState();
    allowNoball = widget.currentAllowNoball ?? true;
    allowWide = widget.currentAllowWide ?? true;
  }

  void _saveSettings() {
    Navigator.pop(context, {
      'allowNoball': allowNoball,
      'allowWide': allowWide,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF283593),
        elevation: 0,
        title: const Text(
          'Match Settings',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
          child: SingleChildScrollView(
            padding: EdgeInsets.all(w * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(w * 0.04),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2026),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF00C4FF).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.settings,
                            color: Color(0xFF00C4FF),
                            size: 24,
                          ),
                          SizedBox(width: w * 0.02),
                          const Text(
                            'Match Configuration',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: w * 0.04),
                      const Divider(color: Color(0xFF5C5C5E)),
                      SizedBox(height: w * 0.04),
                      const Text(
                        'Extra Deliveries',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: w * 0.03),
                      _buildSettingRow(
                        label: 'Allow No Ball',
                        description: 'Enable no-ball deliveries in this match',
                        value: allowNoball,
                        onChanged: (value) {
                          setState(() => allowNoball = value);
                        },
                        icon: Icons.sports_cricket,
                        w: w,
                      ),
                      SizedBox(height: w * 0.03),
                      _buildSettingRow(
                        label: 'Allow Wide',
                        description: 'Enable wide deliveries in this match',
                        value: allowWide,
                        onChanged: (value) {
                          setState(() => allowWide = value);
                        },
                        icon: Icons.straighten,
                        w: w,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: w * 0.04),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(w * 0.03),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF00C4FF),
                        size: 20,
                      ),
                      SizedBox(width: w * 0.02),
                      const Expanded(
                        child: Text(
                          'These settings will apply to the entire match',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: w * 0.06),
                Center(
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C4FF),
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.12,
                        vertical: w * 0.04,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      elevation: 5,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Save Settings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required String label,
    required String description,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
    required double w,
  }) {
    return Container(
      padding: EdgeInsets.all(w * 0.03),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value 
                  ? const Color(0xFF00C4FF).withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: value ? const Color(0xFF00C4FF) : Colors.white70,
              size: 24,
            ),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF00C4FF),
            activeTrackColor: const Color(0xFF00C4FF).withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}