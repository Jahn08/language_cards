import 'package:flutter/material.dart' hide Router;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:language_cards/src/data/pack_storage.dart';
import '../data/study_storage.dart';
import '../models/word_study_stage.dart';
import '../router.dart';
import '../utilities/styler.dart';
import '../widgets/bar_scaffold.dart';
import '../widgets/card_number_indicator.dart';
import '../widgets/loader.dart';
import '../widgets/one_line_text.dart';
import '../widgets/translation_indicator.dart';
import '../widgets/underlined_container.dart';

class _ListNotifier<T> extends ValueNotifier<List<T>> {
	  
	_ListNotifier(List<T> value) : super(value ?? <T>[]);

	void clear() {
		if (value == null || value.isEmpty)
			return;

		value.clear();
		notifyListeners();
	}

	@override
	set value(List<T> newValue) {
		final valueToSet = newValue ?? [];
		if ((value.length + valueToSet.length) == 0)
			return;
			
		super.value = valueToSet;
	}

	void add(T item) {
		value.add(item);
		notifyListeners();
	}
	
	void addAll(Iterable<T> items) {
		value.addAll(items);
		notifyListeners();
	}

	void remove(T item) {
		value.remove(item);
		notifyListeners();
	}
}

class _StudyPreparerScreenState extends State<StudyPreparerScreen> {

	List<StudyPack> _packs;

	bool _hasScrollNavigator = false;

	final _shouldScrollUpNotifier = new ValueNotifier(false);
	final _excludedPacksNotifier = new _ListNotifier<int>([]);

    final ScrollController _scrollController = new ScrollController();

	@override
	void dispose() {
		_scrollController.dispose();

		_shouldScrollUpNotifier.dispose();
		_excludedPacksNotifier.dispose();

		super.dispose();
	}

    @override
    Widget build(BuildContext context) {
		final locale = AppLocalizations.of(context);

        return new FutureLoader<List<StudyPack>>(
			_packs == null ? widget.storage.fetchStudyPacks(): Future.value(_packs), 
            (stPacks) {
				_initPacks(stPacks);

				final styler = new Styler(context);
				return new BarScaffold(
					title: locale.studyPreparerScreenTitle,
					barActions: <Widget>[
						new IconButton(
							onPressed: () {
								if (_excludedPacksNotifier.value.isEmpty)
									_excludedPacksNotifier.addAll(stPacks.map((p) => p.pack.id));
								else
									_excludedPacksNotifier.clear();
							},
							icon: const Icon(Icons.select_all)
						)
					],
					onNavGoingBack: () => Router.goHome(context),
					body: new Column(
						children: [
							new Flexible(child: new ValueListenableBuilder(
								valueListenable: _excludedPacksNotifier,
								builder: (_, List<int> excludedPacks, __) => 
									new _StudyLevelList(stPacks: stPacks, excludedPackIds: excludedPacks)
							), flex: 4, fit: FlexFit.tight),
							const Divider(thickness: 2, height: 0),
							new Flexible(
								child: new Scrollbar(
									child: new ListView(
										children: _packs.map((p) => new ValueListenableBuilder(
											valueListenable: _excludedPacksNotifier,
											child: new TranslationIndicator(p.pack.from, p.pack.to),
											builder: (_, List<int> excludedPacks, child) => 
												_CheckListItem(
													stPack: p,
													isChecked: !excludedPacks.contains(p.pack.id),
													onChanged: (isChecked, packId) {
														if (isChecked)
															_excludedPacksNotifier.remove(packId);
														else
															_excludedPacksNotifier.add(packId);
													}, 
													secondary: child
												)
										)).toList(),
										controller: _scrollController
									)
								), 
								flex: 5
							)
						]
					),
					floatingActionButton: _hasScrollNavigator ? new FloatingActionButton(
						onPressed: () async {
							final pos = _scrollController.position;
							await _scrollController.animateTo(
								_shouldScrollUpNotifier.value ? pos.minScrollExtent : pos.maxScrollExtent, 
								duration: const Duration(milliseconds: 500),
								curve: Curves.easeOut
							);
						},
						child: new ValueListenableBuilder(
							valueListenable: _shouldScrollUpNotifier,
							builder: (_, bool shouldScrollUp, __) => 
								shouldScrollUp ? const Icon(Icons.arrow_upward_rounded): 
									const Icon(Icons.arrow_downward_rounded)
						), 
						mini: styler.isDense,
						tooltip: locale.listScreenAddingNewItemButtonTooltip,
						backgroundColor: styler.floatingActionButtonColor
					): null
				);
			} );
    }

	void _initPacks(List<StudyPack> stPacks) {
		if (_packs != null)
			return;

		_packs = stPacks..sort((a, b) => a.pack.name.compareTo(b.pack.name));
		_hasScrollNavigator = _packs.length > 10;

		if (_hasScrollNavigator)
			_scrollController.addListener(() {
				if (_shouldScrollUpNotifier.value == 
					_scrollController.offset > (_scrollController.position.maxScrollExtent / 2))
					return;
				
				WidgetsBinding.instance.addPostFrameCallback((_) { 
					_shouldScrollUpNotifier.value = !_shouldScrollUpNotifier.value;
				});
			});
	}
}

class _CheckListItem extends StatelessWidget {
	
	final void Function(bool, int) onChanged;

	final StudyPack stPack;

	final bool isChecked;

	final Widget secondary;

	const _CheckListItem({ 
		@required this.isChecked, @required this.stPack, @required this.onChanged, @required this.secondary
	});
	
	@override
	Widget build(BuildContext context) {
		final pack = stPack.pack;
        return new UnderlinedContainer(new CheckboxListTile(
            value: isChecked,
            onChanged: (isChecked) => onChanged(isChecked, pack.id),
            secondary: secondary,
            title: new OneLineText(pack.name),
            subtitle: new CardNumberIndicator(stPack.cardsOverall)
        ));
	}
}

class _StudyLevelList extends StatelessWidget {

	final List<StudyPack> stPacks;

	final List<int> excludedPackIds;

	const _StudyLevelList({ @required this.stPacks, @required this.excludedPackIds });

	@override
	Widget build(BuildContext context) {
		final locale = AppLocalizations.of(context);

		final studyStages = <int, int>{ for (var st in WordStudyStage.values) st: 0 };
        final includedPacks = stPacks.where((p) => !excludedPackIds.contains(p.pack.id)).toList();
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

		final lvlEntries = levels.entries.toList()
			..insert(0, new MapEntry(locale.studyPreparerScreenAllCardsCategoryName, 
				levels.values.reduce((res, el) => res + el)));
        return new Scrollbar(
			isAlwaysShown: true,
			child: new ListView(
				children: lvlEntries.map((lvl) {
					final isEnabled = lvl.value > 2;
					return new ListTile(
						title: new Text(lvl.key), 
						trailing: new Text(lvl.value.toString()), 
						onTap: isEnabled ? () => Router.goToStudyMode(context, 
							packs: includedPacks.map((p) => p.pack).toList(), 
							studyStageIds: WordStudyStage.fromString(lvl.key, locale)): null,
						dense: new Styler(context).isDense,
						enabled: isEnabled,
						visualDensity: VisualDensity.adaptivePlatformDensity
					);
				}).toList()
        	)
		);
	}
}

class StudyPreparerScreen extends StatefulWidget {

    final StudyStorage storage;

    const StudyPreparerScreen([StudyStorage storage]): 
		storage = storage ?? const PackStorage();

    @override
    _StudyPreparerScreenState createState() {
        return _StudyPreparerScreenState();
    }
}
