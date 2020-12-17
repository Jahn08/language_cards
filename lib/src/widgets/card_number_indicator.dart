import 'package:flutter/widgets.dart';

class CardNumberIndicator extends StatelessWidget {

    final String data;

    CardNumberIndicator(int number):
        data = 'Cards: $number';

    @override
    Widget build(BuildContext context) => new Text(data);
}
