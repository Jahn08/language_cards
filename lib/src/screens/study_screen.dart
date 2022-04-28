import 'dart:math';
import 'package:flutter/material.dart' hide Router;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:language_cards/src/data/dictionary_provider.dart';
import '../dialogs/outcome_dialog.dart';
import '../router.dart';
import '../blocs/settings_bloc.dart';
import '../data/pack_storage.dart';
import '../data/word_storage.dart';
import '../dialogs/confirm_dialog.dart';
import '../models/stored_pack.dart';
import '../models/user_params.dart';
import '../models/word_study_stage.dart';
import '../utilities/speaker.dart';
import '../utilities/styler.dart';
import '../widgets/bar_scaffold.dart';
import '../widgets/cancel_button.dart';
import '../widgets/card_editor.dart';
import '../widgets/flip_card.dart';
import '../widgets/loader.dart';
import '../widgets/one_line_text.dart';
import '../widgets/tight_flexible.dart';
import '../widgets/translation_indicator.dart';

class _CardEditorDialog extends OutcomeDialog<MapEntry<StoredWord, StoredPack>> {

	final StoredWord card;
    
    final StoredPack pack;

    final DictionaryProvider provider;

    final ISpeaker defaultSpeaker;

    final WordStorage wordStorage;

    final BaseStorage<StoredPack> packStorage;

	const _CardEditorDialog({ @required this.card, @required this.pack, 
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
					new Center(child: new CancelButton(() => returnResult(context)))
				],
                title: new Text(locale.studyScreenEditingCardDialogTitle)
            )
        );
	}
}

class _StudyScreenState extends State<StudyScreen> {
    
    final _controller = new PageController();

    Future<List<StoredWord>> _futureCards;

    List<StoredWord> _cards;

    Map<int, StoredPack> _packMap;
    
	final _curCardIndexNotifier = new ValueNotifier(0);
	final _curCardUpdater = new ValueNotifier(0);

	final _studyDirectionNotifier = new ValueNotifier<StudyDirection>(null);

	final _cardSideNotifier = new ValueNotifier<CardSide>(null);

    bool _shouldReorderCards;

	Future<UserParams> _futureParams;

	AppLocalizations _locale;

    @override
    void initState() {
        super.initState();

        _shouldReorderCards = false;
        
        _packMap = <int, StoredPack>{ for (var p in widget.packs) p.id: p };
        _futureCards = widget.storage.fetchFiltered(
            parentIds: _packMap.keys.toList(), 
            studyStageIds: widget.studyStageIds);
    }

    @override
    Widget build(BuildContext context) {
		_locale = AppLocalizations.of(context);
		_futureParams ??= SettingsBlocProvider.of(context).userParams;

		return new FutureLoader<UserParams>(_futureParams, (userParams) =>
			new FutureLoader<List<StoredWord>>(_futureCards, (cards) {
				final studyParams = userParams.studyParams;
				_studyDirectionNotifier.value ??= studyParams.direction;
				_cardSideNotifier.value ??= studyParams.cardSide;

				bool shouldTakeAllCards = false;
				if (_cards == null || _cards.isEmpty) {
					_cards = cards;
					
					shouldTakeAllCards = true;
				}

				_orderCards(0, shouldTakeAllCards);
				return new BarScaffold(
					titleWidget: new ValueListenableBuilder(
						valueListenable: _curCardIndexNotifier,
						builder: (_, int curCardIndex, __) => 
							new Text(_locale.studyScreenTitle((curCardIndex + 1).toString(), 
								cards.length.toString())),
					),
					barActions: [
						new IconButton(
							icon: const Icon(Icons.edit),
							onPressed: () async {
								final curCard = _cards[_curCardIndexNotifier.value];
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

								_cards[_curCardIndexNotifier.value] = updatedCard;

								++_curCardUpdater.value;
							}
						)
					],
					body: new Column(
						children: [
							new TightFlexible(
								child: new PageView.builder(
									onPageChanged: _setIndexCard,
									controller: _controller,
									itemBuilder: _buildCard
								), 
								flex: 3
							),
							new TightFlexible(
								child: new _ButtonPanel(
									onLearningPressed: () async {
										final card = _cards[_curCardIndexNotifier.value];
										if (card.incrementProgress())
											await widget.storage.upsert([card]);

										_setNextCard();
									},
									onNextCardPressed: _setNextCard,
									addButtons: [
										new ElevatedButton(
											child: new ValueListenableBuilder(
												valueListenable: _studyDirectionNotifier,
												builder: (_, StudyDirection studyDirection, __) => 
													new _CenteredBigText(
														_locale.studyScreenSortingCardButtonLabel(
															studyDirection.present(_locale)
														)
													)
											),
											onPressed: () {
												_shouldReorderCards = true;
												_studyDirectionNotifier.value = _nextValue(
													StudyDirection.values, _studyDirectionNotifier.value);
											}
										),
										new ElevatedButton(
											child: new ValueListenableBuilder(
												valueListenable: _cardSideNotifier,
												builder: (_, CardSide cardSide, __) =>
													new _CenteredBigText(
														_locale.studyScreenCardSideButtonLabel(
															cardSide.present(_locale)
														)
													)
											),
											onPressed: () {
												_cardSideNotifier.value = _nextValue(
													CardSide.values, _cardSideNotifier.value);
											}
										)
									],
								)
							)
						]
					),
					onNavGoingBack: () => Router.goToStudyPreparation(context)
				);
			})
		);
	} 

	void _showFinishStudyDialog() {
		WidgetsBinding.instance.addPostFrameCallback(
			(_) => new ConfirmDialog.ok(
				title: _locale.studyScreenStudyEndDialogTitle,
				content: _locale.studyScreenStudyEndDialogContent
			).show(context));
	}

    void _orderCards(int newIndex, bool shouldTakeAllCards) {
        final listToOrder = shouldTakeAllCards ? 
            _cards: _cards.sublist(newIndex, _cards.length);

        if (listToOrder.length <= 1)
            return;

		final studyDirection = _studyDirectionNotifier.value;
		if (studyDirection == StudyDirection.forward) {
			listToOrder.sort((a, b) => a.packId.compareTo(b.packId));
			listToOrder.sort((a, b) => a.text.compareTo(b.text));
		}
		else if (studyDirection == StudyDirection.backward) {
			listToOrder.sort((a, b) => b.packId.compareTo(a.packId));
			listToOrder.sort((a, b) => b.text.compareTo(a.text));
		}
		else
			listToOrder.shuffle(new Random());

        if (!shouldTakeAllCards)
            _cards.replaceRange(newIndex, _cards.length, listToOrder);
    }

	Widget _buildCard(_, int index) {
		final indexCard = _getIndexCard(index);
		final isStudyOver = _isStudyOver(indexCard);
		if (_shouldReorderCards || isStudyOver) {
			_orderCards(indexCard, isStudyOver);
	        _shouldReorderCards = false;
		}

		return new ValueListenableBuilder(
			valueListenable: _curCardUpdater,
			builder: (_, __, ___) {
				final card = _cards[indexCard];
				return new Column(
					children: [
						new TightFlexible(child: _PackLabel(_packMap[card.packId])),
						new TightFlexible(
							child: new ValueListenableBuilder(
								valueListenable: _cardSideNotifier,
								builder: (_, CardSide cardSide, __) {
									final isFront = cardSide == CardSide.random ? 
										new Random().nextBool(): cardSide == CardSide.front;
				
									return new FlipCard(
										front: _CardSideFrame(card: card, isFront: isFront),
										back: _CardSideFrame(card: card, isFront: !isFront)
									);
								}
							),
							flex: 9
						)
					]
				);
			});
	}

    void _setNextCard() => _controller.nextPage(curve: Curves.linear, 
        duration: const Duration(milliseconds: 200));

    void _setIndexCard(int newIndex) {
		final indexCard = _getIndexCard(newIndex);
		if (_curCardIndexNotifier.value == indexCard)
			return;

		if (_isStudyOver(indexCard)) {
			_showFinishStudyDialog();

			if ((widget.studyStageIds ?? []).isEmpty) {
				widget.packs.forEach((p) => p.setNowAsStudyDate());
				widget.packStorage.upsert(widget.packs);
			}
		}
			
		_curCardIndexNotifier.value = indexCard;
    }

	bool _isStudyOver(int newIndex) => 
		newIndex == 0 && _curCardIndexNotifier.value == _cards.length - 1;

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
	void dispose() {
		_controller?.dispose();

		_curCardIndexNotifier.dispose();
		_curCardUpdater.dispose();

		_studyDirectionNotifier.dispose();
		_cardSideNotifier.dispose();

		super.dispose();
	}
}

class _PackLabel extends StatelessWidget {

	final StoredPack pack;

	const _PackLabel(this.pack);

	@override
	Widget build(BuildContext context) {
		final screenSize = MediaQuery.of(context).size;
        return new Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
                new Container(
                    child: new TranslationIndicator(pack.from, pack.to), 
                    margin: const EdgeInsets.only(left: 10, bottom: 5)
                ),
                new Container(
					width: screenSize.width * 0.75,
                    child: new OneLineText(pack.name),
                    margin: const EdgeInsets.all(5)
                )
            ]
        );
	}
}

class _CardSideFrame extends StatelessWidget {
		
	final StoredWord card;

	final bool isFront;
	
	const _CardSideFrame({ @required this.card, @required this.isFront });
	
	@override
	Widget build(BuildContext context) {
		final locale = AppLocalizations.of(context);

		Widget subtitle;
		if (isFront) {
			String subtext = (card.transcription ?? '').isEmpty ? '': '[${card.transcription}]\n';
			if (card.partOfSpeech != null)
				subtext += card.partOfSpeech.present(locale);

			subtitle = _CenteredBigText(subtext);
		}

		const double spaceSize = 10;
		return new Card(
			elevation: 25,
			margin: const EdgeInsets.only(left: spaceSize, right: spaceSize, bottom: spaceSize),
			child: new InkWell(
				child: new Column(
					children: [
						new Row(children: [
							new Container(
								margin: const EdgeInsets.all(5),
								child: new Text(WordStudyStage.stringify(card.studyProgress, locale))
							)
						]),
						TightFlexible(
							child: new Center(
								child: new ListTile(
									title: new _CenteredBigText(isFront ? card.text: card.translation),
									subtitle: subtitle
								)
							),
							flex: 2
						)
					]
				)
			)
		);
	}
}

class _ButtonPanel extends StatelessWidget {

	final void Function() onLearningPressed;

	final void Function() onNextCardPressed;

	final List<ElevatedButton> addButtons;

	const _ButtonPanel({
		@required this.onLearningPressed, @required this.onNextCardPressed, 
		List<ElevatedButton> addButtons
	}): addButtons = addButtons ?? const <ElevatedButton>[];

	@override
	Widget build(BuildContext context) {
		final locale = AppLocalizations.of(context);
		final screenSize = MediaQuery.of(context).size;
		final buttons = [
			new ElevatedButton(
				child: new _CenteredBigText(locale.studyScreenLearningCardButtonLabel),
				onPressed: onLearningPressed
			),
			new ElevatedButton(
				child: new _CenteredBigText(locale.studyScreenNextCardButtonLabel),
				onPressed: onNextCardPressed
			), 
			...addButtons
		];
		return new OrientationBuilder(builder: (_, orientation) {
			final ratio = orientation == Orientation.landscape ? 6.25: 5.25;
			return new GridView.count(
				crossAxisCount: 2,
				crossAxisSpacing: 10,
				mainAxisSpacing: 10,
				shrinkWrap: true,
				childAspectRatio: screenSize.width / (screenSize.height / ratio),
				padding: const EdgeInsets.all(5),
				children: buttons
			);
		});
	}
}

class _CenteredBigText extends StatelessWidget {
	
	final String data;

	const _CenteredBigText(this.data);

	@override
	Widget build(BuildContext context) =>
        new Text(data, textAlign: TextAlign.center, 
			textScaleFactor: new Styler(context).isDense ? 1.2: 1.6);
}

class StudyScreen extends StatefulWidget {
    
    final WordStorage storage;

    final BaseStorage<StoredPack> packStorage;

    final List<StoredPack> packs;

    final List<int> studyStageIds;

    final DictionaryProvider provider;

    final ISpeaker defaultSpeaker;

    const StudyScreen(this.storage, { 
		@required this.packs, @required this.packStorage, @required this.provider,
		this.studyStageIds, this.defaultSpeaker 
	});

    @override
    _StudyScreenState createState() => new _StudyScreenState();
}
