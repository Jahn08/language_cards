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
    
    bool _editorMode;

    int _pageIndex = 0;

    BuildContext _scaffoldContext;

    final Map<int, _CachedWord> _wordsMarkedForRemoval = {};
    final Map<int, _CachedWord> _wordsMarkedForRemovalInEditor = {};

    final List<StoredWord> _words = [];
    final ScrollController _scrollController = new ScrollController();

    final _storage = WordStorage.instance;
    
    @override
    initState() {
        super.initState();
        
        _editorMode = false;

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
    Widget build(BuildContext buildContext) {
        return new Scaffold(
            appBar: new AppBar(
                leading: new SettingsOpenerButton(),
                title: new Text('Language Cards'),
                actions: <Widget>[_editorMode ? _buildEditorDoneButton(): 
                    _buildEditorButton()]
            ),
            bottomNavigationBar: _editorMode ? _buildBottomBar(): null,
            drawer: new SettingsBlocProvider(child: new SettingsPanel()),
            body: _buildWordList(),
            floatingActionButton: _buildNewCardButton(buildContext)
        );
    }

    Widget _buildEditorButton() => new FlatButton(
        onPressed: () {
            setState(() => _editorMode = true);
        }, 
        child: new Text('Edit')
    );

    Widget _buildEditorDoneButton() => new FlatButton(
        onPressed: () {
            setState(() { 
                _wordsMarkedForRemovalInEditor.clear();
                _editorMode = false;
            });
        },
        child: new Text('Done')
    );

    Widget _buildBottomBar() {
        bool allSelected = _wordsMarkedForRemovalInEditor.length == _words.length;

        const int removalItemIndex = 0;
        final options = new List<BottomNavigationBarItem>.generate(2, (index) {
            if (index == removalItemIndex)
                return new BottomNavigationBarItem(
                    icon: new Icon(Icons.delete),
                    title: new Text('Remove')
                );
            else
                return new BottomNavigationBarItem(
                    icon: new Icon(Icons.select_all),
                    title: new Text('${allSelected ? 'Unselect': 'Select'} All')
                );
        });
        
        return new BottomNavigationBar(
            items: options,
            onTap: (tappedIndex) {
                if (tappedIndex == removalItemIndex) {
                    if (_wordsMarkedForRemovalInEditor.length == 0)
                        return;

                    _wordsMarkedForRemoval.addAll(_wordsMarkedForRemovalInEditor);

                    setState(() {
                        final idsMarkedForRemoval = _wordsMarkedForRemovalInEditor.keys;
                        _words.removeWhere((w) => idsMarkedForRemoval.contains(w.id));

                        _showWordRemovalInfoSnackBar(_scaffoldContext,
                            '${_wordsMarkedForRemovalInEditor.length} words have been removed',
                            _wordsMarkedForRemovalInEditor.keys.toList());

                        _wordsMarkedForRemovalInEditor.clear();
                    });
                }
                else {
                    if (allSelected)
                        setState(() => _wordsMarkedForRemovalInEditor.clear());
                    else {
                        setState(() {
                            int index = 0;
                            _words.forEach((w) =>
                                _wordsMarkedForRemovalInEditor[w.id] = new _CachedWord(w, index++));
                        });
                    }
                }
            }
        );
    }

    void _showWordRemovalInfoSnackBar(BuildContext scaffoldContext, String message, 
        List<int> wordIdsToRemove) {
        final snackBar = Scaffold.of(scaffoldContext ?? context).showSnackBar(new SnackBar(
            content: new Text(message),
            action: SnackBarAction(
                label: 'Undo',
                onPressed: () => _recoverMarkedForRemoval(wordIdsToRemove)
            )
        ));

        snackBar.closed.then((value) {
            if (value == SnackBarClosedReason.timeout)
                _deleteMarkedForRemoval(wordIdsToRemove);
        });
    }

    Widget _buildWordList() => new Scrollbar(
        child: new ListView.builder(
            itemCount: _words.length,
            itemBuilder: (listContext, index) => _editorMode ?
                _buildCheckListItem(listContext, index):
                _buildDismissibleListItem(listContext, index),
            controller: _scrollController
        )
    );

    Widget _buildCheckListItem(BuildContext buildContext, int wordIndex) {
        _scaffoldContext = buildContext;
        final word = _words[wordIndex];
        
        return new CheckboxListTile(
            value: _wordsMarkedForRemovalInEditor.containsKey(word.id),
            onChanged: (isChecked) {
                setState(() {
                    if (isChecked)
                        _wordsMarkedForRemovalInEditor[word.id] = new _CachedWord(word, wordIndex);
                    else
                        _wordsMarkedForRemovalInEditor.remove(word.id);
                });
            },
            title: _buildOneLineText(word.text),
            subtitle: _buildOneLineText(word.translation),
        );
    }

    Widget _buildOneLineText(String data) => 
        new Text(data, maxLines: 1, overflow: TextOverflow.ellipsis);

    Widget _buildDismissibleListItem(BuildContext buildContext, int wordIndex) {
        final word = _words[wordIndex];

        bool shouldRemove = false;
        return new Dismissible(
            direction: DismissDirection.endToStart,
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

                _showWordRemovalInfoSnackBar(buildContext, 
                    'The word ${wordToRemove.text} has been removed',
                    [wordToRemove.id]);

                setState(() => _words.remove(wordToRemove));
            },
            child: new ListTile(
                title: _buildOneLineText(word.text),
                trailing: _buildOneLineText(word.partOfSpeech),
                subtitle: _buildOneLineText(word.translation),
                onTap: () => _goToCard(buildContext, word.id)
            )
        );
    }

    _recoverMarkedForRemoval(List<int> ids) {
        final entries = _getEntriesMarkedForRemoval(ids).toList();
        if (entries.isEmpty)
            return;

        setState(() {
            entries.sort((a, b) => a.value.index.compareTo(b.value.index));
            entries.forEach((entry) => _words.insert(entry.value.index, entry.value.word));
            _deleteFromMarkedForRemoval(ids);
        });
    }

    List<MapEntry<int, _CachedWord>> _getEntriesMarkedForRemoval(List<int> ids) =>
        _wordsMarkedForRemoval.entries.where((entry) => ids.contains(entry.key)).toList();

    _deleteFromMarkedForRemoval(List<int> ids) => 
        _wordsMarkedForRemoval.removeWhere((id, _) => ids.contains(id));

    _deleteMarkedForRemoval(List<int> ids) {
        if (_wordsMarkedForRemoval.isEmpty)
            return;

        _storage.remove(_getEntriesMarkedForRemoval(ids).map((entry) => entry.key).toList());
        _deleteFromMarkedForRemoval(ids);
    }

    Widget _buildNewCardButton(BuildContext buildContext) {
        final theme = Theme.of(buildContext);
        return new FloatingActionButton(
            onPressed: () => _goToCard(buildContext),
            child: new Icon(Icons.add_circle), 
            mini: true,
            tooltip: 'New Card',
            backgroundColor: (theme.floatingActionButtonTheme.backgroundColor ?? 
                theme.colorScheme.secondary).withOpacity(0.3)
        );
    }

    _goToCard(BuildContext buildContext, [int wordId]) {
        _deleteAllMarkedForRemoval();
        Router.goToCard(buildContext, wordId: wordId);
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
