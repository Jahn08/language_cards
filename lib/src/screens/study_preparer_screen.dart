import 'package:flutter/material.dart' hide Router;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../data/study_storage.dart';
import '../models/word_study_stage.dart';
import '../router.dart';
import '../widgets/bar_scaffold.dart';
import '../widgets/card_number_indicator.dart';
import '../widgets/loader.dart';
import '../widgets/one_line_text.dart';
import '../widgets/translation_indicator.dart';
import '../widgets/underlined_container.dart';

class _StudyPreparerScreenState extends State<StudyPreparerScreen> {

    Future<List<StudyPack>> _futurePacks;

    final List<int> _excludedPacks = [];

    final ScrollController _scrollController = new ScrollController();

    @override
    void initState() {
        super.initState();
    }

    @override
    Widget build(BuildContext context) {
		final locale = AppLocalizations.of(context);
		if (_futurePacks == null)
        	_futurePacks = widget.storage.fetchStudyPacks();

        return new FutureLoader<List<StudyPack>>(_futurePacks, 
            (stPacks) => new BarScaffold(locale.studyPreparerScreenTitle,
					barActions: <Widget>[_buildSelectorButton(stPacks, locale)],
					onNavGoingBack: () => Router.goHome(context),
					body: _buildLayout(stPacks, locale)
            	));
    }

    Widget _buildSelectorButton(List<StudyPack> stPacks, AppLocalizations locale) {
        final allSelected = _excludedPacks.isEmpty;
        return new IconButton(
            onPressed: () {
                setState(() { 
                    _excludedPacks.clear();

                    if (allSelected)
                        _excludedPacks.addAll(stPacks.map((p) => p.pack.id));
                });
            },
            icon: new Icon(Icons.select_all)
        );
    }

    Widget _buildLayout(List<StudyPack> stPacks, AppLocalizations locale) => 
        new Column(
            children: [
                new Flexible(child: _buildStudyLevelList(stPacks, locale), 
					flex: 2, fit: FlexFit.tight),
                new Divider(thickness: 2),
                new Flexible(child: _buildList(stPacks), flex: 3)
            ]
        );

    Widget _buildStudyLevelList(List<StudyPack> stPacks, AppLocalizations locale) {
        final studyStages = new Map<int, int>.fromIterable(WordStudyStage.values,
            key: (st) => st, value: (_) => 0);
        final includedPacks = stPacks.where((p) => !_excludedPacks.contains(p.pack.id)).toList();
        includedPacks.expand((e) => e.cardsByStage.entries)
            .forEach((en) => studyStages[en.key] += en.value);

		final levels = <String, int>{};
		studyStages.entries.forEach((en) {
			final key = WordStudyStage.stringify(en.key, locale);
			if (levels.containsKey(key))
				levels[key] += en.value;
			else
				levels[key] = en.value;
		});
        levels[locale.studyPreparerScreenAllCardsCategoryName] = 
            levels.values.reduce((res, el) => res + el);

        return new Scrollbar(
			isAlwaysShown: true,
			child: new ListView(
				children: levels.entries.map((lvl) {
					final isEnabled = lvl.value > 2;
					return new ListTile(
						title: new Text(lvl.key), 
						trailing: new Text(lvl.value.toString()), 
						onTap: isEnabled ? () => Router.goToStudyMode(context, 
							packs: includedPacks.map((p) => p.pack).toList(), 
							studyStageIds: WordStudyStage.fromString(lvl.key, locale)): null,
						dense: true,
						enabled: isEnabled,
						visualDensity: VisualDensity.comfortable
					);
				}).toList()
        	)
		);
    }

    Widget _buildList(List<StudyPack> packs) => 
        new Scrollbar(
            child: new ListView(
                children: packs.map((p) => _buildCheckListItem(p)).toList(),
                controller: _scrollController
            )
        );

    Widget _buildCheckListItem(StudyPack stPack) {
        final pack = stPack.pack;
        return new UnderlinedContainer(new CheckboxListTile(
            value: !_excludedPacks.contains(pack.id),
            onChanged: (isChecked) {
                setState(() {
                    if (isChecked)
                        _excludedPacks.remove(pack.id);
                    else
                        _excludedPacks.add(pack.id);
                });
            },
            secondary: new TranslationIndicator(pack.from, pack.to),
            title: new OneLineText(pack.name),
            subtitle: new CardNumberIndicator(stPack.cardsOverall)
        ));
    }
}

class StudyPreparerScreen extends StatefulWidget {

    final StudyStorage storage;

    StudyPreparerScreen(this.storage);

    @override
    _StudyPreparerScreenState createState() {
        return _StudyPreparerScreenState();
    }
}
