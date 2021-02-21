import 'package:flutter/material.dart' hide Router;
import 'package:flutter/widgets.dart' hide Router;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/presentable_enum.dart';
import '../consts.dart';
import '../data/pack_storage.dart';
import '../data/word_storage.dart';
import '../models/language.dart';
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

    Map<String, PresentableEnum> _languages;

    BaseStorage<StoredPack> get _storage => widget._storage;

    @override
    Widget build(BuildContext context) {
		final locale = AppLocalizations.of(context);
    	
		if (_languages == null)
			_languages = PresentableEnum.mapStringValues(Language.values, locale);
        
		return new BarScaffold(
            (_isNew ? locale.packScreenHeadBarAddingPackTitle:
				locale.packScreenHeadBarChangingPackTitle),
            onNavGoingBack: () => widget.refreshed ? Router.goToPackList(context) : 
                Router.goBackToPackList(context),
            body: new Form(
                key: _key,
                child: _buildFutureFormLayout(widget.packId, locale)
            )
        );
    }

    bool get _isNew => widget.packId == null;

    Widget _buildFutureFormLayout(int packId, AppLocalizations locale) {
        final futurePack = _isNew || _initialised ? 
            Future.value(new StoredPack('')): _storage.find(widget.packId);
        return new FutureBuilder(
            future: futurePack,
            builder: (context, AsyncSnapshot<StoredPack> snapshot) {
                if (!snapshot.hasData)
                    return new Loader();

                final foundPack = snapshot.data;
                if (foundPack != null && !foundPack.isNew && !_initialised) {
                    _foundPack = foundPack;
                    _initialised = true;

                    _name = foundPack.name;
                    
                    _toLang = foundPack.to.present(locale);
                    _fromLang = foundPack.from.present(locale);
                    _cardsNumber = foundPack.cardsNumber;
                }

                return _buildFormLayout(locale);
            }
        );
    }

    Widget _buildFormLayout(AppLocalizations locale) {
        final children = <Widget>[
            new StyledTextField(locale.packScreenPackNameTextFieldLabel,
                isRequired: true, 
                onChanged: (value, _) => setState(() => _name = value), 
                initialValue: this._name),
            new StyledDropdown(_languages.keys, 
                isRequired: true,
                label: locale.packScreenTranslationFromDropdownLabel,
                initialValue: this._fromLang,
                onChanged: (value) => setState(() => this._fromLang = value),
                onValidate: (_) => _validateLanguages(locale)),
            new StyledDropdown(_languages.keys, 
                isRequired: true,
                label: locale.packScreenTranslationToDropdownLabel,
                initialValue: this._toLang,
                onChanged: (value) => setState(() => this._toLang = value),
                onValidate: (_) => _validateLanguages(locale))
        ];

        if (!_isNew && _foundPack != null)
            children.add(new FlatButton.icon(
                icon: new Icon(Consts.cardListIcon),
                label: new Text(locale.packScreenShowingCardsButtonLabel(_cardsNumber)),
                onPressed: () => Router.goToCardList(context, pack: _foundPack)
            ));
        
        final isStateDirty = _isNew || (_foundPack != null && (
            _foundPack.name != _name || _foundPack.to != _languages[_toLang] ||
            _foundPack.from != _languages[_fromLang]));
        children.addAll([
            _buildSaveBtn(locale.constsSavingItemButtonLabel, 
				(_) => Router.goToPackList(context), isDisabled: !isStateDirty),
            _buildSaveBtn(locale.packScreenSavingAndAddingCardsButtonLabel, 
                (savedPack) => Router.goToCardList(context, pack: savedPack), 
                isDisabled: !isStateDirty)
        ]);
        
        return new Column(children: children);
    }

    String _validateLanguages(AppLocalizations locale) => _fromLang == _toLang ? 
        locale.packScreenSameTranslationDirectionsValidationError: null;

    StoredPack _buildPack() => new StoredPack(this._name, 
        id: widget.packId,
        to: _languages[_toLang],
        from: _languages[_fromLang]
    );

    RaisedButton _buildSaveBtn(String title, void afterSaving(StoredPack pack), 
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
        { this.packName, this.packId, this.refreshed = false }): 
        _storage = storage;

    @override
    PackScreenState createState() {
        return new PackScreenState();
    }
}
