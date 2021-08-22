import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CardNumberIndicator extends StatelessWidget {

    final int number;

    const CardNumberIndicator(this.number);

    @override
    Widget build(BuildContext context) => 
		new Text(AppLocalizations.of(context).cardNumberIndicatorContent(number?.toString()));
}
