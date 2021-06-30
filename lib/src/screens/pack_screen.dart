import 'package:flutter/material.dart' hide Router;
import 'package:flutter/widgets.dart' hide Router;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/presentable_enum.dart';
import '../consts.dart';
import '../data/dictionary_provider.dart';
import '../data/pack_storage.dart';
import '../data/word_dictionary.dart';
import '../data/word_storage.dart';
import '../models/language.dart';
import '../router.dart';
import '../widgets/loader.dart';
import '../widgets/no_translation_snack_bar.dart';
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

                return _buildFormLayout(context, locale);
            }
        );
    }

    Widget _buildFormLayout(BuildContext buildContext, AppLocalizations locale) {
        final children = <Widget>[
            new StyledTextField(locale.packScreenPackNameTextFieldLabel,
                isRequired: true, 
                onChanged: (value, _) => setState(() => _name = value), 
                initialValue: this._name),
            new StyledDropdown(_languages.keys, 
                isRequired: true,
                label: locale.packScreenTranslationFromDropdownLabel,
                initialValue: this._fromLang,
                onChanged: (value) => setState(() {
					this._fromLang = value;
					_checkTranslationPossibility(buildContext, locale);	
				}),
                onValidate: (_) => _validateLanguages(locale)),
            new StyledDropdown(_languages.keys, 
                isRequired: true,
                label: locale.packScreenTranslationToDropdownLabel,
                initialValue: this._toLang,
                onChanged: (value) => setState(() {
					this._toLang = value;
					_checkTranslationPossibility(buildContext, locale);	
				}),
                onValidate: (_) => _validateLanguages(locale))
        ];

        if (!_isNew && _foundPack != null)
            children.add(new Container(
				alignment: Alignment.centerLeft,
				child: new TextButton.icon(
					icon: new Icon(Consts.cardListIcon),
					label: new Text(locale.packScreenShowingCardsButtonLabel(
						_cardsNumber.toString())),
					onPressed: () => Router.goToCardList(context, pack: _foundPack)
				)
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

	void _checkTranslationPossibility(BuildContext buildContext, AppLocalizations locale) {
		if (_validateLanguages(locale) != null || 
			(_fromLang?.isEmpty ?? true) || (_toLang?.isEmpty ?? true))
			return;

		new WordDictionary(widget._provider, from: _languages[_fromLang], 
			to: _languages[_toLang]).isTranslationPossible().then((resp) {
				if (!resp)
					NoTranslationSnackBar.show(buildContext, locale);
			});
	}

    StoredPack _buildPack() => new StoredPack(this._name, 
        id: widget.packId,
        to: _languages[_toLang],
        from: _languages[_fromLang]
    );

    ElevatedButton _buildSaveBtn(String title, void afterSaving(StoredPack pack), 
        { bool isDisabled }) => 
        new ElevatedButton(
            child: new Text(title),
            onPressed: isDisabled ? null: () async {
                final state = _key.currentState;
                if (!state.validate())
                    return;

                state.save();

                afterSaving((await _storage.upsert([_buildPack()])).first);
            }
        );
}

class PackScreen extends StatefulWidget {
    final int packId;

    final bool refreshed;
    
    final BaseStorage<StoredPack> _storage;
    
    final DictionaryProvider _provider;

    PackScreen(BaseStorage<StoredPack> storage, DictionaryProvider provider,
        { this.packId, this.refreshed = false }): 
        _storage = storage,
		_provider = provider;

    @override
    PackScreenState createState() {
        return new PackScreenState();
    }
}
