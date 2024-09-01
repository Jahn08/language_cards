import 'package:flutter/material.dart';
import '../models/language.dart';
import '../utilities/styler.dart';
import '../widgets/asset_icon.dart';
import '../widgets/icon_option.dart';

class TranslationIndicator extends StatelessWidget {
  final Language? from;

  final Language? to;

  const TranslationIndicator(this.from, this.to) : assert(from != to);

  const TranslationIndicator.empty()
      : from = null,
        to = null;

  @override
  Widget build(BuildContext context) {
    const clipper = _DiagonalClipper();
    return new Container(
        margin: const EdgeInsets.only(right: 5),
        child: new Stack(children: <Widget>[
          new IconOption(
              icon: from == null
                  ? const SizedBox()
                  : AssetIcon.getByLanguage(from!)),
          if (to != null)
            new CustomPaint(
                painter: new _ClippedBorderPainter(
                    clipper, new Styler(context).dividerColor),
                child: new ClipPath(
                    clipper: clipper,
                    child: IconOption(icon: AssetIcon.getByLanguage(to!))))
        ]));
  }
}

class _ClippedBorderPainter extends CustomPainter {
  final CustomClipper<Path> clipper;

  final Color color;

  const _ClippedBorderPainter(this.clipper, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color;

    canvas.drawPath(clipper.getClip(size), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiagonalClipper extends CustomClipper<Path> {
  const _DiagonalClipper();

  @override
  Path getClip(Size size) {
    final path = new Path();
    path.moveTo(size.width, size.height);

    path.lineTo(size.width, 0.0);
    path.lineTo(0, size.height * 0.9);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
