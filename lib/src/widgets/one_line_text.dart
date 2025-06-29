import 'package:flutter/widgets.dart';

class OneLineText extends StatelessWidget {
  final String? content;

  final double? textScaleFactor;

  final TextStyle? style;

  const OneLineText(this.content, {this.textScaleFactor, this.style});

  @override
  Widget build(BuildContext context) => new Text(content ?? '',
      textScaler:
          textScaleFactor == null ? null : TextScaler.linear(textScaleFactor!),
      maxLines: 1,
      style: style,
      overflow: TextOverflow.ellipsis);
}
