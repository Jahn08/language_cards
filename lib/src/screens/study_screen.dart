import 'dart:math';
import 'package:flutter/material.dart' hide Router;
import 'package:language_cards/src/models/word_study_stage.dart';
import '../router.dart';
import '../blocs/settings_bloc.dart';
import '../data/word_storage.dart';
import '../dialogs/confirm_dialog.dart';
import '../models/stored_pack.dart';
import '../models/stored_word.dart';
import '../models/user_params.dart';
import '../utilities/enum.dart';
import '../widgets/bar_scaffold.dart';
import '../widgets/flip_card.dart';
import '../widgets/loader.dart';
import '../widgets/translation_indicator.dart';

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

    @override
    initState() {
        super.initState();
        
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

				if (_isStudyOver) {
					_isStudyOver = false;
					WidgetsBinding.instance.addPostFrameCallback(
						(_) => ConfirmDialog.buildOkDialog(
							title: 'The Study Cicle Is Over', 
							content: 'Well Done! You have finished the study.\n\n' + 
							'You can repeat the study to hone the cards to perfection'
						).show(context));
				
					shouldTakeAllCards = true;
				}

				_orderCards(shouldTakeAllCards);
				return new BarScaffold(
					'${_curCardIndex + 1} of ${cards.length} Cards',
					body: _buildLayout(),
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

        switch (_studyDirection) {
            case StudyDirection.forward:
                listToOrder.sort((a, b) => a.packId.compareTo(b.packId));
                listToOrder.sort((a, b) => a.text.compareTo(b.text));
                break;
            case StudyDirection.backward:
                listToOrder.sort((a, b) => b.packId.compareTo(a.packId));
                listToOrder.sort((a, b) => b.text.compareTo(a.text));
                break;
            default:
                listToOrder.shuffle(new Random());
                break;
        }

        if (!shouldTakeAllCards)
            _cards.replaceRange(startIndex, _cards.length, listToOrder);
    }

    Widget _buildLayout() {
        return new Column(
            children: [
                _buildRow(child: _buildCardLayout(), flex: 3),
                _buildRow(child: _buildButtonPanel(_cards[_curCardIndex]))
            ]
        );
    }

    Widget _buildRow({ Widget child, int flex }) => 
        new Flexible(
            fit: FlexFit.tight,
            flex: flex ?? 1,
            child: child ?? Container()
        );

    Widget _buildCardLayout() {
        return new PageView.builder(
            controller: _controller,
            onPageChanged: (index) => _setIndexCard(_getIndexCard(index)),
            itemBuilder: (context, index) {
                final card = _cards[_getIndexCard(index)];
                return new Column(
                    children: [
                        _buildRow(child: _buildPackLabel(_packMap[card.packId])),
                        _buildRow(child: _buildCard(card), flex: 9)
                    ]
                );
            }
        );
    }

    Widget _buildPackLabel(StoredPack pack) {

        return new Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
                new Container(
                    child: new TranslationIndicator(pack.from, pack.to), 
                    margin: EdgeInsets.only(left: 5)
                ),
                new Container(
                    child: new Text(pack.name),
                    margin: EdgeInsets.all(5)
                )
            ]
        );
    }

    Widget _buildCard(StoredWord card) {
       final isFrontSide = _cardSide == CardSide.random ? new Random().nextBool():
            _cardSide == CardSide.front;

        return new FlipCard(
            front: _buildCardSide(isFront: isFrontSide, card: card),
            back: _buildCardSide(isFront: !isFrontSide, card: card)
        );
    }

    Widget _buildCardSide({ bool isFront, StoredWord card }) {
        String subtext = (card.transcription ?? '').isEmpty ? '': '[${card.transcription}]\n';
        if ((card.partOfSpeech ?? '').isNotEmpty)
            subtext += '${card.partOfSpeech}';

        return new Card(
            elevation: 25,
            margin: EdgeInsets.only(left: 10, right: 10),
            child: new InkWell(
                child: new Container(
                    child: new Column(
                        children: [
                            _buildStudyLevelRow(card.studyProgress),
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

    Widget _buildStudyLevelRow(int studyProgress) => 
        new Row(children: [
            new Container(
                margin: EdgeInsets.all(5),
                child: new Text(WordStudyStage.stringify(studyProgress))
            )
        ]);

    Widget _buildCenteredBigText(String data) => 
        new Text(data, textAlign: TextAlign.center, textScaleFactor: 1.5);

    Widget _buildButtonPanel(StoredWord card) {

        return new GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            childAspectRatio: 2.6,
            padding: EdgeInsets.all(5),
            children: [
                new RaisedButton(
                    child: _buildCenteredBigText('Learn'),
                    onPressed: () async {
                        if (card.incrementProgress())
                            await widget.storage.update([card]);

                        _setNextCard();
                    }
                ),
                new RaisedButton(
                    child: _buildCenteredBigText('Next'),
                    onPressed: _setNextCard
                ),
                new RaisedButton(
                    child: _buildCenteredBigText('Sorting: ${Enum.stringifyValue(_studyDirection)}'),
                    onPressed: () =>
                        setState(() {
                            _shouldReorderCards = true;
                            _studyDirection = _nextValue(StudyDirection.values, _studyDirection);
                        })
                ),
                new RaisedButton(
                    child: _buildCenteredBigText('Side: ${Enum.stringifyValue(_cardSide)}'),
                    onPressed: () =>
                        setState(() {
                            _cardSide = _nextValue(CardSide.values, _cardSide);
                        })
                )
            ]
        );
    }

    void _setNextCard() => _controller.nextPage(curve: Curves.linear, 
        duration: new Duration(milliseconds: 200));

    void _setIndexCard(int newIndex) {
        newIndex = newIndex < 0 || newIndex == _cards.length ? 0: newIndex;
        _isStudyOver = newIndex == 0 && _curCardIndex == _cards.length - 1;
        
        setState(() { 
            _curCardIndex = newIndex;
            _shouldReorderCards = true; 
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

    final List<StoredPack> packs;

    final List<int> studyStageIds;

    StudyScreen(this.storage, { @required this.packs, this.studyStageIds });

    @override
    _StudyScreenState createState() => new _StudyScreenState();
}
