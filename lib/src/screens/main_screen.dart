import 'package:flutter/material.dart';
import '../widgets/settings_panel.dart';
import '../widgets/settings_opener_button.dart';
import '../blocs/settings_bloc.dart';
import '../router.dart';
import '../data/word_storage.dart';

class _CachedWord {
    final StoredWord word;

    final int index;

    _CachedWord(this.word, this.index);
}

class _MainScreenState extends State<MainScreen> {
    static const int _wordsPerPage = 30;

    bool _endOfData = false;
    bool _canFetch = false;

    int _pageIndex = 0;

    final Map<int, _CachedWord> _wordsMarkedForRemoval = {};

    final List<StoredWord> _words = [];
    final ScrollController _scrollController = new ScrollController();

    final _storage = WordStorage.instance;
    
    @override
    initState() {
        super.initState();
        
        _scrollController.addListener(_expandWordListOnScroll);

        _fetchWords();
    }

    _fetchWords() async {
        _canFetch = false;
        final nextWords = await _fetchNextWords();

        _canFetch = true;

        if (nextWords.length == 0)
            _endOfData = true;
        else
            setState(() { _words.addAll(nextWords); });
    }

    _expandWordListOnScroll() {
        if (_scrollController.position.extentAfter < 500 && !_endOfData && _canFetch)
            _fetchWords();
    }

    Future<List<StoredWord>> _fetchNextWords() => 
        _storage.fetch(skipCount: _pageIndex++ * _wordsPerPage, takeCount: _wordsPerPage);

    @override
    dispose() {
        _scrollController.removeListener(_expandWordListOnScroll);

        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return new Scaffold(
            appBar: new AppBar(
                title: new Text('Language Cards'),
                actions: <Widget>[new SettingsOpenerButton()]
            ),
            endDrawer: new SettingsBlocProvider(child: new SettingsPanel()),
            body: _buildWordList(),
            floatingActionButton: _buildNewCardButton(context)
        );
    }

    Widget _buildWordList() => new Scrollbar(
        child: new ListView.builder(
            itemCount: _words.length,
            itemBuilder: (listContext, index) => _buildListItem(listContext, index),
            controller: _scrollController
        )
    );

    Widget _buildListItem(BuildContext context, int wordIndex) {
        final word = _words[wordIndex];

        bool shouldRemove = false;
        return new Dismissible(
            confirmDismiss: (direction) => Future.delayed(new Duration(milliseconds: 2000), 
                () => shouldRemove),
            background: new Container(
                color: Colors.deepOrange[300], 
                child: new FlatButton.icon(
                    label: new Text('Remove'),
                    icon: new Icon(Icons.delete), 
                    onPressed: () => shouldRemove = true
                )
            ),
            key: new Key(word.id.toString()),
            onDismissed: (direction) {
                final wordToRemove = _words[wordIndex];
                _wordsMarkedForRemoval[wordToRemove.id] = 
                    new _CachedWord(wordToRemove, wordIndex);

                final snackBar = Scaffold.of(context).showSnackBar(new SnackBar(
                    content: new Text('The word ${wordToRemove.text} has been removed'),
                    action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () => _recoverMarkedForRemoval([wordToRemove.id])
                    )
                ));

                snackBar.closed.then((value) {
                    if (value == SnackBarClosedReason.timeout)
                        _deleteMarkedForRemoval([wordToRemove.id]);
                });

                setState(() => _words.remove(wordToRemove));
            },
            child: new ListTile(
                title: _buildOneLineText(word.text),
                trailing: _buildOneLineText(word.partOfSpeech),
                subtitle: _buildOneLineText(word.translation),
                onTap: () => _goToCard(context, word.id)
            )
        );
    }

    _recoverMarkedForRemoval(List<int> ids) {
        final entries = _getEntriesMarkedForRemoval(ids).toList();
        if (entries.isEmpty)
            return;

        setState(() {
            entries.forEach((entry) => _words.insert(entry.value.index, entry.value.word));
            _deleteFromMarkedForRemoval(ids);
        });
    }

    Iterable<MapEntry<int, _CachedWord>> _getEntriesMarkedForRemoval(List<int> ids) =>
        _wordsMarkedForRemoval.entries.where((entry) => ids.contains(entry.key));

    _deleteFromMarkedForRemoval(List<int> ids) => 
        _wordsMarkedForRemoval.removeWhere((id, _) => ids.contains(id));

    _deleteMarkedForRemoval(List<int> ids) {
        if (_wordsMarkedForRemoval.isEmpty)
            return;

        _storage.remove(_getEntriesMarkedForRemoval(ids).map((entry) => entry.key).toList());
        _deleteFromMarkedForRemoval(ids);
    }

    Widget _buildOneLineText(String data) => 
        new Text(data, maxLines: 1, overflow: TextOverflow.ellipsis);

    Widget _buildNewCardButton(BuildContext context) {
        final theme = Theme.of(context);
        return new FloatingActionButton(
            onPressed: () => _goToCard(context),
            child: new Icon(Icons.add_circle), 
            mini: true,
            tooltip: 'New Card',
            backgroundColor: (theme.floatingActionButtonTheme.backgroundColor ?? 
                theme.colorScheme.secondary).withOpacity(0.3)
        );
    }

    _goToCard(BuildContext context, [int wordId]) {
        _deleteAllMarkedForRemoval();
        Router.goToCard(context, wordId: wordId);
    }
    
    _deleteAllMarkedForRemoval() {
        if (_wordsMarkedForRemoval.isEmpty)
            return;

        _storage.remove(_wordsMarkedForRemoval.keys);
        _wordsMarkedForRemoval.clear();
    }
}

class MainScreen extends StatefulWidget {
    @override
    State<StatefulWidget> createState() => new _MainScreenState();
}
