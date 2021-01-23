import 'package:flutter/material.dart';
import '../utilities/assured_finder.dart';

class DialogTester {

	assureDialog({ bool shouldFind }) => 
		AssuredFinder.findOne(type: SimpleDialog, shouldFind: shouldFind);
}
