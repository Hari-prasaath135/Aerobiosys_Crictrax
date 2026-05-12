import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const FigmaToCodeApp());

class FigmaToCodeApp extends StatelessWidget {
  const FigmaToCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A237E),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      ),
      home: const TeamPage(),
    );
  }
}

class TeamPage extends StatelessWidget {
  const TeamPage({super.key});

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

              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: h),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.all(w * 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(w),
                          SizedBox(height: h * 0.035),
                          _buildAddTeamsButton(w),
                          SizedBox(height: h * 0.035),
                          _buildTeamsSection(w),
                          SizedBox(height: h * 0.025),
                          _buildTossDetailsSection(w),
                          SizedBox(height: h * 0.025),
                          _buildOversSection(w),
                          SizedBox(height: h * 0.04),
                          _buildBottomRow(w),
                          SizedBox(height: h * 0.025),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double w) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Cricket ', style: _textStyle(w * 0.1)),
              TextSpan(text: 'Scorer', style: _textStyle(w * 0.05)),
            ],
          ),
        ),
        Row(
          children: [
            _buildSvgIcon('assets/ix_support.svg', w * 0.065),
            SizedBox(width: w * 0.025),
            Opacity(
              opacity: 0.90,
              child: _buildSvgIcon('assets/Group.svg', w * 0.065),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddTeamsButton(double w) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: w * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Add Teams', style: _textStyle(w * 0.04)),
          SizedBox(width: w * 0.025),
          _buildSvgIcon('assets/mdi_plus-circle-outline.svg', w * 0.065),
        ],
      ),
    );
  }

  Widget _buildTeamsSection(double w) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Teams', style: _textStyle(w * 0.04)),
          SizedBox(height: w * 0.04),
          _buildDropdownField('Team 1', w),
          SizedBox(height: w * 0.04),
          _buildDropdownField('Team 2', w),
        ],
      ),
    );
  }

  Widget _buildTossDetailsSection(double w) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Toss Details', style: _textStyle(w * 0.04)),
          SizedBox(height: w * 0.04),
          _buildLabeledField('Add', 'Choose team', w, hasDropdown: false),
          SizedBox(height: w * 0.04),
          _buildLabeledField('Choose to', 'Choose team', w),
        ],
      ),
    );
  }

  Widget _buildOversSection(double w) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        borderRadius: BorderRadius.circular(10),
      ),
      child: _buildLabeledField('Overs', 'Enter the overs', w, hasDropdown: false),
    );
  }

  Widget _buildBottomRow(double w) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text('Additional\nSettings', style: _textStyle(w * 0.04)),
            SizedBox(width: w * 0.025),
            _buildSvgIcon('assets/picon_on.svg', w * 0.088),
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: w * 0.03),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Start Match', style: _textStyle(w * 0.04)),
              SizedBox(width: w * 0.02),
              _buildSvgIcon('assets/mdi_cricket.svg', w * 0.062),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, double w) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.03),
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        border: Border.all(color: const Color(0xFFD1D1D1)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: _textStyle(w * 0.034, null, const Color(0xFF9E9E9E))),
          _buildSvgIcon(
            'assets/material-symbols_arrow-drop-down-circle-outline.svg',
            w * 0.062,
            colored: false,
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledField(String label, String placeholder, double w,
      {bool hasDropdown = true}) {
    return Row(
      children: [
        SizedBox(
          width: w * 0.26,
          child: Text(label, style: _textStyle(w * 0.034)),
        ),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.025),
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              border: Border.all(color: const Color(0xFFD1D1D1)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  placeholder,
                  style: _textStyle(w * 0.034, null, const Color(0xFF9E9E9E)),
                ),
                if (hasDropdown)
                  _buildSvgIcon(
                    'assets/material-symbols_arrow-drop-down-circle-outline.svg',
                    w * 0.052,
                    colored: false,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSvgIcon(String path, double size, {bool colored = true}) {
    return SvgPicture.asset(
      path,
      width: size,
      height: size,
      colorFilter: colored
          ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
          : null,
    );
  }

  TextStyle _textStyle(double size, [FontWeight? weight, Color? color]) {
    return TextStyle(
      color: color ?? Colors.white,
      fontSize: size,
      fontFamily: 'Poppins',
      fontWeight: weight ?? FontWeight.w400,
    );
  }
}