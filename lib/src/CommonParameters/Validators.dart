import 'package:flutter/material.dart';

//Phone number validator

class PhoneValidator {
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final trimmed = value.trim();

    // Must be exactly 10 digits and start with 6, 7, 8, or 9
    final regex = RegExp(r'^[6-9]\d{9}$');

    if (!regex.hasMatch(trimmed)) {
      return 'Enter Valid Phone Number';
    }

    return null; // Valid
  }
}