import 'dart:math';
import 'package:flutter/material.dart' hide Router;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:language_cards/src/data/dictionary_provider.dart';
import '../router.dart';
import '../blocs/settings_bloc.dart';
import '../data/pack_storage.dart';
import '../data/word_storage.dart';
import '../dialogs/cancellable_dialog.dart';
import '../dialogs/confirm_dialog.dart';
import '../models/stored_pack.dart';
import '../models/stored_word.dart';
import '../models/user_params.dart';
import '../models/word_study_stage.dart';
import '../utilities/speaker.dart';
import '../widgets/bar_scaffold.dart';
import '../widgets/card_editor.dart';
import '../widgets/flip_card.dart';
import '../widgets/loader.dart';
import '../widgets/one_line_text.dart';
import '../widgets/translation_indicator.dart';

class _CardEditorDialog extends CancellableDialog<MapEntry<StoredWord, StoredPack>> {

	final StoredWord card;
    
    final StoredPack pack;

    final DictionaryProvider provider;

    final ISpeaker defaultSpeaker;

    final BaseStorage<StoredWord> wordStorage;

    final BaseStorage<StoredPack> packStorage;

	_CardEditorDialog({ @required this.card, @required this.pack, 
		@required this.wordStorage, @required this.packStorage,
		this.provider, this.defaultSpeaker }): 
		super();

	Future<MapEntry<StoredWord, StoredPack>> show(BuildContext context) {
		final locale = AppLocalizations.of(context);
		return showDialog(
            context: context, 
            builder: (buildContext) => new SimpleDialog(
				children: [
					new CardEditor(card: card, pack: pack, 
						provider: provider, defaultSpeaker: defaultSpeaker,
						wordStorage: wordStorage, packStorage: packStorage,
						hideNonePack: true, 
						afterSave: (card, pack, _) {
							returnResult(buildContext, new MapEntry(card, pack));
						}), 
					new Center(child: buildCancelBtn(context))
				],
                title: new Text(locale.studyScreenEditingCardDialogTitle)
            )
        );
	}
}

class _StudyScreenState extends State<StudyScreen> {
    
    final PageController _controller = new PageController();

    Future<List<StoredWord>> _futureCards;

    List<StoredWord> _cards;

    Map<int, StoredPack> _packMap;
    
    int _curCardIndex;

    StudyDirection _studyDirection;

    CardSide _cardSide;

    bool _shouldReorderCards;

    bool _isStudyOver;

	Future<UserParams> _futureParams;

	Map<int, Widget> _pageCache;

    @override
    initState() {
        super.initState();
        
		_pageCache = new Map<int, Widget>();

        _shouldReorderCards = true;
        _isStudyOver = false;
        
        _curCardIndex = 0;

        _packMap = new Map<int, StoredPack>.fromIterable(widget.packs, 
            key: (p) => p.id, value: (p) => p);
        _futureCards = widget.storage.fetchFiltered(
            parentIds: _packMap.keys.toList(), 
            studyStageIds: widget.studyStageIds);
    }

    @override
    Widget build(BuildContext context) {
		if (_futureParams == null)
        	_futureParams = SettingsBlocProvider.of(context).userParams;

		return new FutureLoader<UserParams>(_futureParams, (userParams) =>
			new FutureLoader<List<StoredWord>>(_futureCards, (cards) {
				final studyParams = userParams.studyParams;
				if (_studyDirection == null)
					_studyDirection = studyParams.direction;
				if (_cardSide == null)
					_cardSide = studyParams.cardSide;

				bool shouldTakeAllCards = false;
				if (_cards == null || _cards.isEmpty) {
					_cards = cards;
					
					shouldTakeAllCards = true;
				}

				final locale = AppLocalizations.of(context);
				if (_isStudyOver) {
					_isStudyOver = false;
					WidgetsBinding.instance.addPostFrameCallback(
						(_) => new ConfirmDialog.ok(
							title: locale.studyScreenStudyEndDialogTitle,
							content: locale.studyScreenStudyEndDialogContent
						).show(context));
				
					shouldTakeAllCards = true;
					_pageCache.clear();
				}

				_orderCards(shouldTakeAllCards);

				return new BarScaffold(
					locale.studyScreenTitle((_curCardIndex + 1).toString(), 
						cards.length.toString()),
					barActions: [
						new IconButton(
							icon: new Icon(Icons.edit),
							onPressed: () async {
								final curCard = _cards[_curCardIndex];
								final updatedPackedCard = await new _CardEditorDialog(
									card: curCard,
									pack: _packMap[curCard.packId],
									provider: widget.provider,
									defaultSpeaker: widget.defaultSpeaker,
									wordStorage: widget.storage,
									packStorage: widget.packStorage
								).show(context);

								if (updatedPackedCard == null)
									return;

								final updatedCard = updatedPackedCard.key;
								if (curCard.packId != updatedCard.packId && 
									!_packMap.containsKey(updatedCard.packId))
									_packMap[updatedCard.packId] = updatedPackedCard.value;

								setState(() {
									_cards[_curCardIndex] = updatedCard;
									_removeCurrentPageFromCache();
								});
							}
						)
					],
					body: _buildLayout(locale, MediaQuery.of(context).size),
					onNavGoingBack: () => Router.goToStudyPreparation(context)
				);
			})
		);
	} 

    void _orderCards(bool shouldTakeAllCards) {
        if (!_shouldReorderCards)
            return;

        _shouldReorderCards = false;
        
        final startIndex = _curCardIndex + 1;
        final listToOrder = shouldTakeAllCards ? 
            _cards: _cards.sublist(startIndex, _cards.length);

        if (listToOrder.length <= 1)
            return;

		if (_studyDirection == StudyDirection.forward) {
			listToOrder.sort((a, b) => a.packId.compareTo(b.packId));
			listToOrder.sort((a, b) => a.text.compareTo(b.text));
		}
		else if (_studyDirection == StudyDirection.backward) {
			listToOrder.sort((a, b) => b.packId.compareTo(a.packId));
			listToOrder.sort((a, b) => b.text.compareTo(a.text));
		}
		else
			listToOrder.shuffle(new Random());

        if (!shouldTakeAllCards)
            _cards.replaceRange(startIndex, _cards.length, listToOrder);
    }

	void _removeCurrentPageFromCache() => _pageCache.remove(_curCardIndex);

    Widget _buildLayout(AppLocalizations locale, Size screenSize) =>
		new Column(
            children: [
                _buildRow(child: _buildCardLayout(locale, screenSize), flex: 3),
                _buildRow(child: _buildButtonPanel(_cards[_curCardIndex], locale, screenSize))
            ]
        );

    Widget _buildRow({ Widget child, int flex }) => 
        new Flexible(
            fit: FlexFit.tight,
            flex: flex ?? 1,
            child: child ?? Container()
        );

    Widget _buildCardLayout(AppLocalizations locale, Size screenSize) {
        return new PageView.builder(
            controller: _controller,
            onPageChanged: (index) => _setIndexCard(_getIndexCard(index)),
            itemBuilder: (context, index) {

				if (_pageCache.containsKey(index))
					return _pageCache[index];

                final card = _cards[_getIndexCard(index)];
                return _pageCache[index] = new Column(
                    children: [
                        _buildRow(child: _buildPackLabel(_packMap[card.packId], screenSize)),
                        _buildRow(child: _buildCard(card, locale), flex: 9)
                    ]
                );
            }
        );
    }

    Widget _buildPackLabel(StoredPack pack, Size screenSize) {

        return new Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
                new Container(
                    child: new TranslationIndicator(pack.from, pack.to), 
                    margin: EdgeInsets.only(left: 10, bottom: 5)
                ),
                new Container(
					width: screenSize.width * 0.75,
                    child: new OneLineText(pack.name),
                    margin: EdgeInsets.all(5)
                )
            ]
        );
    }

    Widget _buildCard(StoredWord card, AppLocalizations locale) {
       final isFrontSide = _cardSide == CardSide.random ? new Random().nextBool():
            _cardSide == CardSide.front;

        return new FlipCard(
            front: _buildCardSide(card, locale, isFront: isFrontSide),
            back: _buildCardSide(card, locale, isFront: !isFrontSide)
        );
    }

    Widget _buildCardSide(StoredWord card, AppLocalizations locale, { bool isFront }) {
        String subtext = (card.transcription ?? '').isEmpty ? '': '[${card.transcription}]\n';
        if (card.partOfSpeech != null)
            subtext += '${card.partOfSpeech.present(locale)}';

		const double spaceSize = 10;
        return new Card(
            elevation: 25,
            margin: EdgeInsets.only(left: spaceSize, right: spaceSize, bottom: spaceSize),
            child: new InkWell(
                child: new Container(
                    child: new Column(
                        children: [
                            _buildStudyLevelRow(card.studyProgress, locale),
                            _buildRow(child: new Center(
                                child: new ListTile(
                                    title: _buildCenteredBigText(isFront ? 
                                        card.text: card.translation),
                                    subtitle: isFront ? 
                                        new Text(subtext, textAlign: TextAlign.center): null
                                )
                            ), flex: 2)
                        ]
                    )
                )
            )
        );
    }

    Widget _buildStudyLevelRow(int studyProgress, AppLocalizations locale) => 
        new Row(children: [
            new Container(
                margin: EdgeInsets.all(5),
                child: new Text(WordStudyStage.stringify(studyProgress, locale))
            )
        ]);

    Widget _buildCenteredBigText(String data) => 
        new Text(data, textAlign: TextAlign.center, textScaleFactor: 1.2);

    Widget _buildButtonPanel(StoredWord card, AppLocalizations locale, Size screenSize) {
		
		return new OrientationBuilder(builder: (_, orientation) {
			final ratio = orientation == Orientation.landscape ? 6.25: 5.25;
			return new GridView.count(
				crossAxisCount: 2,
				crossAxisSpacing: 10,
				mainAxisSpacing: 10,
				shrinkWrap: true,
				childAspectRatio: screenSize.width / (screenSize.height / ratio),
				padding: EdgeInsets.all(5),
				children: [
					new ElevatedButton(
						child: _buildCenteredBigText(locale.studyScreenLearningCardButtonLabel),
						onPressed: () async {
							if (card.incrementProgress())
								await widget.storage.upsert([card]);

							_setNextCard();
						}
					),
					new ElevatedButton(
						child: _buildCenteredBigText(locale.studyScreenNextCardButtonLabel),
						onPressed: _setNextCard
					),
					new ElevatedButton(
						child: _buildCenteredBigText(locale.studyScreenSortingCardButtonLabel(
							_studyDirection.present(locale)
						)),
						onPressed: () =>
							setState(() {
								_shouldReorderCards = true;
								_studyDirection = _nextValue(StudyDirection.values, _studyDirection);
							})
					),
					new ElevatedButton(
						child: _buildCenteredBigText(locale.studyScreenCardSideButtonLabel(
							_cardSide.present(locale)
						)),
						onPressed: () =>
							setState(() {
								_cardSide = _nextValue(CardSide.values, _cardSide);
								_removeCurrentPageFromCache();
							})
					)
				]
			);
		});
    }

    void _setNextCard() => _controller.nextPage(curve: Curves.linear, 
        duration: new Duration(milliseconds: 200));

    void _setIndexCard(int newIndex) {
        newIndex = newIndex < 0 || newIndex == _cards.length ? 0: newIndex;
        _isStudyOver = newIndex == 0 && _curCardIndex == _cards.length - 1;
		
        setState(() { 
            _curCardIndex = newIndex;
            _shouldReorderCards = !_pageCache.containsKey(newIndex);
        });
    }

    int _getIndexCard(int newIndex) {
        final cardsLength = _cards.length;
        return newIndex >= cardsLength ? newIndex % cardsLength: 
            (newIndex < 0 ? cardsLength - 1: newIndex);
    }

    T _nextValue<T>(List<T> values, T curValue) =>
        values[_nextIndex(values, values.indexOf(curValue))];

    int _nextIndex<T>(List<T> values, int curValIndex) =>
        curValIndex == -1 || curValIndex == values.length - 1 ? 
            0: curValIndex + 1;

	@override
	dispose() {
		_controller?.dispose();

		super.dispose();
	}
}

class StudyScreen extends StatefulWidget {
    
    final WordStorage storage;

    final BaseStorage<StoredPack> packStorage;

    final List<StoredPack> packs;

    final List<int> studyStageIds;

    final DictionaryProvider provider;

    final ISpeaker defaultSpeaker;

    StudyScreen(this.storage, { 
		@required this.packs, @required this.packStorage, @required this.provider,
		this.studyStageIds, this.defaultSpeaker 
	});

    @override
    _StudyScreenState createState() => new _StudyScreenState();
}
