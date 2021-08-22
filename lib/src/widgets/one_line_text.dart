import 'package:flutter/widgets.dart';

class OneLineText extends StatelessWidget {
    
    final String content;

	final double textScaleFactor;

    const OneLineText(this.content, { this.textScaleFactor });

    @override
    Widget build(BuildContext context) => 
        new Text(content, textScaleFactor: textScaleFactor, maxLines: 1, 
			overflow: TextOverflow.ellipsis);
}
