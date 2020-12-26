import 'dart:math';
import 'package:flutter/material.dart' hide Router;
import 'package:language_cards/src/models/word_study_stage.dart';
import '../enum.dart';
import '../router.dart';
import '../data/word_storage.dart';
import '../dialogs/confirm_dialog.dart';
import '../models/stored_pack.dart';
import '../models/stored_word.dart';
import '../models/user_params.dart';
import '../widgets/bar_scaffold.dart';
import '../widgets/loader.dart';
import '../widgets/translation_indicator.dart';

class _StudyScreenState extends State<StudyScreen> {
    
    Future<List<StoredWord>> _futureCards;

    List<StoredWord> _cards;

    Map<int, StoredPack> _packMap;
    
    int _curCardIndex;

    StudyDirection _studyDirection;

    CardSide _cardSide;

    bool _shouldReorderCards;

    bool _shouldShowOppositeCardSide;

    bool _isStudyOver;

    bool _wasFrontCardSide;

    @override
    initState() {
        super.initState();

        _studyDirection = StudyDirection.forward;
        _cardSide = CardSide.front;
        
        _shouldReorderCards = true;
        _shouldShowOppositeCardSide = false;
        _isStudyOver = false;
        
        _curCardIndex = 0;

        _packMap = new Map<int, StoredPack>.fromIterable(widget.packs, 
            key: (p) => p.id, value: (p) => p);
        _futureCards = widget.storage.fetchFiltered(
            parentIds: _packMap.keys.toList(), 
            studyStageIds: widget.studyStageIds);
    }

    @override
    Widget build(BuildContext context) =>
        new FutureLoader<List<StoredWord>>(_futureCards, (cards) {
            if (_cards == null || _cards.isEmpty)
                _cards = cards;

            if (_isStudyOver) {
                _isStudyOver = false;
                WidgetsBinding.instance.addPostFrameCallback(
                    (_) => ConfirmDialog.buildOkDialog(
                        title: 'The Study Cicle Is Over', 
                        content: 'Well Done! You have finished the study.\n\n' + 
                            'Continue studying the same cards and you will ' +
                            'definitely hone them to perfection!'
                    ).show(context));
            }

            _orderCards();
            return new BarScaffold(
                '${_curCardIndex + 1} of ${cards.length} Cards',
                body: _buildLayout(),
                onNavGoingBack: () => Router.goToStudyPreparation(context)
            );
        });

    void _orderCards() {
        if (!_shouldReorderCards)
            return;

        _shouldReorderCards = false;
        
        final shouldTakeAllCards = _curCardIndex == 0;
        final listToOrder = shouldTakeAllCards ? 
            _cards: _cards.sublist(_curCardIndex, _cards.length);

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
                listToOrder.shuffle();
                break;
        }

        if (!shouldTakeAllCards)
            _cards.replaceRange(_curCardIndex, _cards.length, listToOrder);
    }

    Widget _buildLayout() {
        final card = _cards[_curCardIndex];

        return new Column(
            children: [
                _buildRow(child: _buildCardLayout(card), flex: 2),
                _buildRow(),
                _buildRow(child: _buildButtonPanel(card))
            ]
        );
    }

    Widget _buildRow({ Widget child, int flex }) => 
        new Flexible(
            fit: FlexFit.tight,
            flex: flex ?? 1,
            child: child ?? Container()
        );

    Widget _buildCardLayout(StoredWord card) {

        return new Column(
            children: [
                _buildRow(child: _buildPackLabel(_packMap[card.packId])),
                _buildRow(child: _buildCard(card), flex: 2)
            ]
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
        bool isFrontSide;
        if (_shouldShowOppositeCardSide) {
            _shouldShowOppositeCardSide = false;
            isFrontSide = !_wasFrontCardSide;
        }
        else
            isFrontSide = _cardSide == CardSide.random ? new Random().nextBool():
                _cardSide == CardSide.front;

        String subtext = (card.transcription ?? '').isEmpty ? '': '[${card.transcription}]\n';
        if ((card.partOfSpeech ?? '').isNotEmpty)
            subtext += '${card.partOfSpeech}';

        bool isSwipingToRight = false;
        return new GestureDetector(
            onPanUpdate: (event) {
                isSwipingToRight = event.delta.dx > 0;
            },
            onPanEnd: (event) {
                if (isSwipingToRight)
                    _setPrevCard();
                else
                    _setNextCard();
            },
            child: new Card(
                elevation: 10,
                margin: EdgeInsets.only(left: 10, right: 10),
                child: new InkWell(
                    onTap: () => setState(() {
                        _wasFrontCardSide = isFrontSide;
                        _shouldShowOppositeCardSide = true;
                    }),
                    child: new Container(
                        child: new Column(
                            children: [
                                if (isFrontSide) 
                                    _buildStudyLevelRow(card.studyProgress),
                                _buildRow(child: new Center(
                                    child: new ListTile(
                                        title: _buildCenteredBigText(isFrontSide ? 
                                            card.text: card.translation),
                                        subtitle: isFrontSide ? 
                                            new Text(subtext, textAlign: TextAlign.center): null
                                    )
                                ), flex: 2)
                            ]
                        )
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

    void _setPrevCard() => _setIndexCard(_prevIndex(_cards, _curCardIndex));

    int _prevIndex<T>(List<T> values, int curValIndex) =>
        curValIndex > 0 ? curValIndex - 1: values.length - 1;

    void _setNextCard() => 
        _setIndexCard(_nextIndex(_cards, _curCardIndex), true);

    int _nextIndex<T>(List<T> values, int curValIndex) =>
        curValIndex == -1 || curValIndex == values.length - 1 ? 
            0: curValIndex + 1;

    void _setIndexCard(int newIndex, [bool isNextIndex = false]) => 
        setState(() {
            _curCardIndex = newIndex;

            _isStudyOver = _curCardIndex == 0 && isNextIndex;
            _shouldReorderCards = _isStudyOver;
        });

    T _nextValue<T>(List<T> values, T curValue) =>
        values[_nextIndex(values, values.indexOf(curValue))];
}

class StudyScreen extends StatefulWidget {
    
    final WordStorage storage;

    final List<StoredPack> packs;

    final List<int> studyStageIds;

    StudyScreen(this.storage, { @required this.packs, this.studyStageIds });

    @override
    _StudyScreenState createState() => new _StudyScreenState();
}
