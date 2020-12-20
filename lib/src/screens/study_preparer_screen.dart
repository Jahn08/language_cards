import 'package:flutter/material.dart' hide Router;
import 'package:language_cards/src/models/word_study_stage.dart';
import '../consts.dart';
import '../router.dart';
import '../data/study_storage.dart';
import '../widgets/bar_scaffold.dart';
import '../widgets/card_number_indicator.dart';
import '../widgets/loader.dart';
import '../widgets/one_line_text.dart';
import '../widgets/translation_indicator.dart';

class _StudyPreparerScreenState extends State<StudyPreparerScreen> {

    Future<List<StudyPack>> _futurePacks;

    final List<int> _excludedPacks = [];

    final ScrollController _scrollController = new ScrollController();

    @override
    void initState() {
        super.initState();

        _futurePacks = widget.storage.fetchStudyPacks();
    }

    @override
    Widget build(BuildContext context) {
        return new FutureLoader<List<StudyPack>>(_futurePacks, 
            (stPacks) => new BarScaffold('Choose What to Study',
                barActions: <Widget>[_buildSelectorButton(stPacks)],
                onNavGoingBack: () => Router.goHome(context),
                body: _buildLayout(stPacks)
            ));
    }

    Widget _buildSelectorButton(List<StudyPack> stPacks) {
        final allSelected = _excludedPacks.isEmpty;
        return new FlatButton(
            onPressed: () {
                setState(() { 
                    _excludedPacks.clear();

                    if (allSelected)
                        _excludedPacks.addAll(stPacks.map((p) => p.pack.id));
                });
            },
            child: new Text(Consts.getSelectorLabel(allSelected))
        );
    }

    Widget _buildLayout(List<StudyPack> stPacks) => 
        new Column(
            children: [
                new Flexible(child: _buildStudyLevelList(stPacks), fit: FlexFit.tight),
                new Divider(thickness: 2),
                new Flexible(child: _buildList(stPacks), flex: 2)
            ]
        );

    Widget _buildStudyLevelList(List<StudyPack> stPacks) {
        final levels = new Map<String, int>.fromIterable(WordStudyStage.values,
            key: (k) => WordStudyStage.stringify(k), value: (_) => 0);
        final includedPacks = stPacks.where((p) => !_excludedPacks.contains(p.pack.id)).toList();
        includedPacks.expand((e) => e.cardsByStage.entries)
            .forEach((en) => levels[en.key] += en.value);
        levels[StudyPreparerScreen.allWordsCategoryName] = 
            levels.values.reduce((res, el) => res + el);

        final includedPackIds = includedPacks.map((p) => p.pack.id).toList();
        return new ListView(
            children: levels.entries.map((lvl) => 
                new ListTile(
                    title: new Text(lvl.key), 
                    trailing: new Text(lvl.value.toString()), 
                    onTap: lvl.value < 2 ? null: () => Router.goToStudyMode(context, 
                        packIds: includedPackIds, 
                        studyStageIds: WordStudyStage.fromString(lvl.key)),
                    dense: true, 
                    visualDensity: VisualDensity.comfortable
                )).toList()
        );
    }

    Widget _buildList(List<StudyPack> packs) => 
        new Scrollbar(
            child: new ListView(
                children: packs.map((p) =>_buildCheckListItem(p)).toList(),
                controller: _scrollController
            )
        );

    Widget _buildCheckListItem(StudyPack stPack) {
        final pack = stPack.pack;
        return new CheckboxListTile(
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
        );
    }
}

class StudyPreparerScreen extends StatefulWidget {

    static const String allWordsCategoryName = 'All';

    final StudyStorage storage;

    StudyPreparerScreen(this.storage);

    @override
    _StudyPreparerScreenState createState() {
        return _StudyPreparerScreenState();
    }
}
