import 'package:flutter/material.dart';

class StyledInputDecoration extends InputDecoration {
  const StyledInputDecoration(String label)
      : super(
            labelText: label,
            contentPadding: const EdgeInsets.only(left: 10, right: 10));
}
