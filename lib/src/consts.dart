import 'package:flutter/material.dart';

class Consts {

    Consts._();

    static const IconData cardListIcon = Icons.filter_1;

    static String getSelectorLabel(bool allSelected) => 
        '${allSelected ? 'Unselect': 'Select'} All';
}
