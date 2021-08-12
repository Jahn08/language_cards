import 'package:flutter/material.dart';
import '../models/language.dart';
import '../utilities/styler.dart';
import '../widgets/asset_icon.dart';
import '../widgets/icon_option.dart';

class TranslationIndicator extends StatelessWidget {
        
    final Language from;

    final Language to;

    TranslationIndicator(this.from, this.to) {
        assert(this.from != null);
        assert(this.to != null);
        assert(this.from != this.to);
    }

    TranslationIndicator.empty():
        this.from = null,
        this.to = null;

    @override
    Widget build(BuildContext context) {
		final clipper = new _DiagonalClipper();
		return new Container(
			margin: new EdgeInsets.only(right: 5),
			child: new Stack(
				children: <Widget>[
					new IconOption(icon: this.from == null ? new Container(): 
						AssetIcon.getByLanguage(this.from)),
					if (this.to != null)
						new CustomPaint(
							painter: new _ClippedBorderPainter(clipper, 
								new Styler(context).dividerColor),
							child: new ClipPath(
								clipper: clipper,
								child: IconOption(icon: AssetIcon.getByLanguage(this.to))
							)
						)
				]
			)
		);
	} 
}

class _ClippedBorderPainter extends CustomPainter {

	final CustomClipper<Path> clipper;

	final Color color;

	_ClippedBorderPainter(this.clipper, this.color);

	@override
	void paint(Canvas canvas, Size size) {
		Paint paint = Paint()
			..style = PaintingStyle.stroke
			..strokeWidth = 1.5
			..color = this.color;
	
		canvas.drawPath(clipper.getClip(size), paint);
	}

	@override
	bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiagonalClipper extends CustomClipper<Path> {

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
