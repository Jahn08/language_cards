import 'package:flutter/material.dart';

class StyledInputDecoration extends InputDecoration {
    StyledInputDecoration(String label): 
        super(labelText: label, contentPadding: EdgeInsets.only(left: 10, right: 10));
}
