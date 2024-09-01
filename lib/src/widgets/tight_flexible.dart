import 'package:flutter/material.dart';

class TightFlexible extends StatelessWidget {
  final int flex;

  final Widget child;

  const TightFlexible({@required this.child, this.flex});

  @override
  Widget build(BuildContext context) =>
      new Flexible(fit: FlexFit.tight, flex: flex ?? 1, child: child);
}
