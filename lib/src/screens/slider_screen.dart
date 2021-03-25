import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../dialogs/confirm_dialog.dart';
import '../utilities/local_asset_image.dart';
import '../utilities/string_ext.dart';
import '../utilities/styler.dart';
import '../widgets/bar_scaffold.dart';

class _SliderScreenState extends State<_SliderScreen> {
	
	int _curPageIndex = 0;

	List<Image> _slides;

	PageController _ctrl;

	@override
	initState() {
		super.initState();

		_slides = widget.slideNames.map((n) => new Image(image: new LocalAssetImage(n))).toList();
		_ctrl = new PageController();
	}

	@override
	dispose() {
		_ctrl?.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final locale = AppLocalizations.of(context);

		final scaffold = new BarScaffold(
			'${widget.title}\nPage ${_curPageIndex + 1} of ${_slides.length}', 
			body: new Container(
				child: new PageView(
					controller: _ctrl,
					allowImplicitScrolling: true,
					children: _slides.map((s) => _buildSlide(s)).toList(),
					onPageChanged: (pageIndex) {
						setState(() => _curPageIndex = pageIndex);
					}
				),
				margin: new EdgeInsets.all(5.0),
				decoration: new BoxDecoration(
					border: new Border.all(color: new Styler(context).primaryColor)
				)
			),
			barActions: [
				new IconButton(
					onPressed: () => _showInfoDialog(context, locale),
					icon: new Icon(Icons.info)
				)
			],
		);

		WidgetsBinding.instance.addPostFrameCallback((_) => _showInfoDialog(context, locale));
		
		return scaffold;
	}
		
	Widget _buildSlide(Image image) {
		const double iconSize = 30;
		return new Stack(
			fit: StackFit.expand,
			children: [
				new Container(
					child: image,
					alignment: Alignment.center
				),
				new Container(
					alignment: Alignment.centerRight,
					child: new IconButton(
						icon: new Icon(Icons.chevron_right_outlined), 
						onPressed: _curPageIndex == _slides.length - 1 ? null: 
							() => _ctrl.nextPage(
								duration: new Duration(milliseconds: 200), 
								curve: Curves.easeInOut
							),
						iconSize: iconSize
					)
				),
				new Container(
					alignment: Alignment.centerLeft,
					child: new IconButton(
						icon: new Icon(Icons.chevron_left_outlined), 
						onPressed: _curPageIndex == 0 ? null: () => _ctrl.previousPage(
							duration: new Duration(milliseconds: 200), 
							curve: Curves.easeInOut
						),
						iconSize: iconSize
					)
				)
			],
		);
	}

	Future<void> _showInfoDialog(BuildContext context, AppLocalizations locale) async {
		final description = widget.descriptor(_curPageIndex, locale);

		final parts = splitLocalizedText(description);
		new ConfirmDialog.ok(title: parts.last, content: parts.first).show(context);
	}
}

class _SliderScreen extends StatefulWidget {

	final List<String> slideNames;

	final String title;

	final String Function(int slideIndex, AppLocalizations locale) descriptor;

	_SliderScreen(this.title, this.slideNames, this.descriptor);

	@override
	State<StatefulWidget> createState() => new _SliderScreenState();
}

class HelpCardScreen extends _SliderScreen {

	HelpCardScreen(): super('About Word Cards', [
		'help_card_screen', 'help_card_editor_mode_btn', 'help_card_editor_mode_exit_btn'
	], _descriptor);

	static String _descriptor(int slideIndex, AppLocalizations locale) {
		switch (slideIndex) {
			case 0:
				return locale.helpCardScreenOverviewSlideDescription;
			case 1:
				return locale.helpCardScreenEditorModeBtnSlideDescription;
			case 2:
				return locale.helpCardScreenEditorModeExitBtnSlideDescription;
			default:
				return '';
		}
	}
}
