import 'package:flutter/material.dart';
import '../widgets/settings_panel.dart';
import '../widgets/settings_opener_button.dart';
import '../blocs/settings_bloc.dart';
import '../router.dart';
import '../data/word_storage.dart';

class _MainScreenState extends State<MainScreen> {
    static const int _wordsPerPage = 30;

    bool _endOfData = false;
    bool _canFetch = false;

    int _pageIndex = 0;

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
        _storage.getWords(skipCount: _pageIndex++ * _wordsPerPage, takeCount: _wordsPerPage);

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
            floatingActionButton: _buildNewCardButton(context),
        );
    }

    Widget _buildWordList() => new Scrollbar(
        child: new ListView.builder(
            itemCount: _words.length,
            itemBuilder: (listContext, index) {
                final word = _words[index];
                return new ListTile(
                    title: _buildOneLineText(word.text),
                    trailing: _buildOneLineText(word.partOfSpeech),
                    subtitle: _buildOneLineText(word.translation)
                );
            },
            controller: _scrollController
        )
    );

    Widget _buildOneLineText(String data) => 
        new Text(data, maxLines: 1, overflow: TextOverflow.ellipsis);

    Widget _buildNewCardButton(BuildContext context) {
        final theme = Theme.of(context);
        return new FloatingActionButton(
            onPressed: () => Router.goToNewCard(context), 
            child: new Icon(Icons.add_circle), 
            mini: true,
            tooltip: 'New Card',
            backgroundColor: (theme.floatingActionButtonTheme.backgroundColor ?? 
                theme.colorScheme.secondary).withOpacity(0.3)
        );
    } 
}

class MainScreen extends StatefulWidget {
    @override
    State<StatefulWidget> createState() => new _MainScreenState();
}
