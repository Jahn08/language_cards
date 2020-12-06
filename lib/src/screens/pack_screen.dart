import 'package:flutter/material.dart' hide Router;
import 'package:flutter/widgets.dart' hide Router;
import '../app.dart';
import '../data/pack_storage.dart';
import '../data/word_storage.dart';
import '../models/language.dart';
import '../enum.dart';
import '../router.dart';
import '../widgets/loader.dart';
import '../widgets/bar_scaffold.dart';
import '../widgets/styled_dropdown.dart';
import '../widgets/styled_text_field.dart';

class PackScreenState extends State<PackScreen> {
    final _key = new GlobalKey<FormState>();

    String _name;

    int _cardsNumber = 0;

    String _fromLang;
    String _toLang;

    StoredPack _foundPack;
    bool _initialised = false;

    final _languages = Enum.mapStringValues(Language.values);

    BaseStorage<StoredPack> get _storage => widget._storage;

    @override
    Widget build(BuildContext context) {
        final packName = _isNew ? _name: widget.packName;
        final packNameFormatted = (packName?.isEmpty ?? true) ? '': ' "$packName"';

        return new BarScaffold(
            (_isNew ? 'Add Pack': 'Change Pack') + packNameFormatted,
            onNavGoingBack: () => widget.refreshed ? Router.goToPackList(context) : 
                Router.goBackToPackList(context),
            body: new Form(
                key: _key,
                child: _buildFutureFormLayout(widget.packId)
            )
        );
    }

    bool get _isNew => widget.packId == 0;

    Widget _buildFutureFormLayout(int packId) {
        final futurePack = _isNew || _initialised ? 
            Future.value(new StoredPack('')): _storage.find(widget.packId);
        return new FutureBuilder(
            future: futurePack,
            builder: (context, AsyncSnapshot<StoredPack> snapshot) {
                if (!snapshot.hasData)
                    return new Loader();

                final foundPack = snapshot.data;
                if (foundPack != null && foundPack.id > 0 && !_initialised) {
                    _foundPack = foundPack;
                    _initialised = true;

                    _name = foundPack.name;
                    
                    _toLang = Enum.stringifyValue(foundPack.to);
                    _fromLang = Enum.stringifyValue(foundPack.from);
                    _cardsNumber = foundPack.cardsNumber;
                }

                return _buildFormLayout();
            }
        );
    }

    Widget _buildFormLayout() {
        final children = <Widget>[
            new StyledTextField('Pack Name', 
                isRequired: true, 
                onChanged: (value, _) => setState(() => _name = value), 
                initialValue: this._name),
            new StyledDropdown(_languages.keys, 
                isRequired: true,
                label: 'Translate From',
                initialValue: this._fromLang,
                onChanged: (value) => setState(() => this._fromLang = value),
                onValidate: _validateLanguages),
            new StyledDropdown(_languages.keys, 
                isRequired: true,
                label: 'Translate To',
                initialValue: this._toLang,
                onChanged: (value) => setState(() => this._toLang = value),
                onValidate: _validateLanguages)
        ];

        if (!_isNew && _foundPack != null)
            children.add(new FlatButton.icon(
                icon: new Icon(App.cardListIcon),
                label: new Text('Show $_cardsNumber Cards'),
                onPressed: () => Router.goToCardList(context, pack: _foundPack)
            ));
        
        final isStateDirty = _isNew || (_foundPack != null && (
            _foundPack.name != _name || _foundPack.to != _languages[_toLang] ||
            _foundPack.from != _languages[_fromLang]));
        children.addAll([
            _buildSaveBtn('Save', (_) => Router.goToPackList(context), isDisabled: !isStateDirty),
            _buildSaveBtn('Save and Add Cards', 
                (savedPack) => Router.goToCardList(context, pack: savedPack), 
                isDisabled: !isStateDirty)
        ]);
        
        return new Column(children: children);
    }

    String _validateLanguages(_) => _fromLang == _toLang ? 
        'Translation languages must differ': null;

    StoredPack _buildPack() => new StoredPack(this._name, 
        id: widget.packId,
        to: _languages[_toLang],
        from: _languages[_fromLang]
    );

    RaisedButton _buildSaveBtn(String title, Function afterSaving(StoredPack pack), 
        { bool isDisabled }) => 
        new RaisedButton(
            child: new Text(title),
            onPressed: isDisabled ? null: () async {
                final state = _key.currentState;
                if (!state.validate())
                    return;

                state.save();

                afterSaving(await _storage.upsert(_buildPack()));
            }
        );
}

class PackScreen extends StatefulWidget {
    final int packId;

    final String packName;

    final bool refreshed;
    
    final BaseStorage<StoredPack> _storage;
    
    PackScreen(BaseStorage<StoredPack> storage, 
        { this.packName, this.packId = 0, this.refreshed = false }): 
        _storage = storage;

    @override
    PackScreenState createState() {
        return new PackScreenState();
    }
}
