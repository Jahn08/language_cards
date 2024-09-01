import 'package:flutter/widgets.dart';

class OneLineText extends StatelessWidget {
  final String? content;

  final double? textScaleFactor;

  const OneLineText(this.content, {this.textScaleFactor});

  @override
  Widget build(BuildContext context) => new Text(content ?? '',
      textScaler: textScaleFactor == null
          ? TextScaler.noScaling
          : TextScaler.linear(textScaleFactor!),
      maxLines: 1,
      overflow: TextOverflow.ellipsis);
}
