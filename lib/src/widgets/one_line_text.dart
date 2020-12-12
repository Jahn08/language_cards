import 'package:flutter/widgets.dart';

class OneLineText extends StatelessWidget {
    
    final String content;

    OneLineText(this.content);

    @override
    Widget build(BuildContext context) => 
        new Text(this.content, maxLines: 1, overflow: TextOverflow.ellipsis);
}
