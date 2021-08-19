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

	final _nameNotifier = new ValueNotifier<String>(null); 
	final _fromLangNotifier = new ValueNotifier<String>(null); 
	final _toLangNotifier = new ValueNotifier<String>(null); 

	final _isStateDirtyNotifier = new ValueNotifier<bool>(null); 
    
    int _cardsNumber = 0;
    StoredPack _foundPack;
    bool _initialised = false;

    Map<String, Language> _languages;

    BaseStorage<StoredPack> get _storage => widget._storage;

	@override
	void dispose() {
		_fromLangNotifier.dispose();
		_toLangNotifier.dispose();
		_nameNotifier.dispose();

		_isStateDirtyNotifier.dispose();

		super.dispose();
	}

    @override
    Widget build(BuildContext context) {
		final locale = AppLocalizations.of(context);
		_languages ??= PresentableEnum.mapStringValues(Language.values, locale);
        
		final futurePack = _isNew || _initialised ? 
            Future.value(new StoredPack('')): _storage.find(widget.packId);
		return new BarScaffold(
            title: (_isNew ? locale.packScreenHeadBarAddingPackTitle:
				locale.packScreenHeadBarChangingPackTitle),
            onNavGoingBack: () => widget.refreshed ? Router.goToPackList(context) : 
                Router.goBackToPackList(context),
            body: new Form(
                key: _key,
                child: new FutureBuilder(
					future: futurePack,
					builder: (context, AsyncSnapshot<StoredPack> snapshot) {
						if (!snapshot.hasData)
							return new Loader();

						final foundPack = snapshot.data;
						if (foundPack != null && !foundPack.isNew && !_initialised) {
							_foundPack = foundPack;
							_initialised = true;

							_nameNotifier.value = foundPack.name;
							_fromLangNotifier.value = foundPack.from.present(locale);
							_toLangNotifier.value = foundPack.to.present(locale);
							
							_cardsNumber = foundPack.cardsNumber;
						}

						_setStateDirtiness();
						return new Column(children: [
							new ValueListenableBuilder(
								valueListenable: _nameNotifier, 
								builder: (_, String name, __) =>
									new StyledTextField(locale.packScreenPackNameTextFieldLabel,
										isRequired: true, 
										onChanged: (value, _) { 
											_nameNotifier.value = value;
											_setStateDirtiness();
										},
										initialValue: name)
							),
							new ValueListenableBuilder(
								valueListenable: _fromLangNotifier, 
								builder: (buildContext, String fromLang, _) =>
									new StyledDropdown(_languages.keys, 
										isRequired: true,
										label: locale.packScreenTranslationFromDropdownLabel,
										initialValue: fromLang,
										onChanged: (value) {
											_fromLangNotifier.value = value;
											_checkTranslationPossibility(buildContext, locale);

											_setStateDirtiness();
										},
										onValidate: (_) => _validateLanguages(locale))
							),
							new ValueListenableBuilder(
								valueListenable: _toLangNotifier,
								builder: (buildContext, String toLang, _) =>
									new StyledDropdown(_languages.keys, 
										isRequired: true,
										label: locale.packScreenTranslationToDropdownLabel,
										initialValue: toLang,
										onChanged: (value) {
											_toLangNotifier.value = value;
											_checkTranslationPossibility(buildContext, locale);

											_setStateDirtiness();
										},
										onValidate: (_) => _validateLanguages(locale))
							),
							if (!_isNew && _foundPack != null)
								new Container(
									alignment: Alignment.centerLeft,
									child: new TextButton.icon(
										icon: const Icon(Consts.cardListIcon),
										label: new Text(locale.packScreenShowingCardsButtonLabel(
											_cardsNumber.toString())),
										onPressed: () => Router.goToCardList(context, pack: _foundPack)
									)
								),
								new ValueListenableBuilder(
									valueListenable: _isStateDirtyNotifier,
									child: new Text(locale.constsSavingItemButtonLabel),
									builder: (_, bool isStateDirty, label) =>
										new ElevatedButton(
											child: label,
											onPressed: !isStateDirty ? null: 
												() => _onSave((_) => Router.goToPackList(context))
										)
								),
								new ValueListenableBuilder(
									valueListenable: _isStateDirtyNotifier,
									child: new Text(locale.packScreenSavingAndAddingCardsButtonLabel),
									builder: (_, bool isStateDirty, label) =>
										new ElevatedButton(
											child: label,
											onPressed: !isStateDirty ? null: 
												() => _onSave((savedPack) =>
													Router.goToCardList(context, pack: savedPack, 
														packWasAdded: _isNew))
										)
								)
						]);
					}
				)
            )
        );
    }

    bool get _isNew => widget.packId == null;

	void _setStateDirtiness() => 
		_isStateDirtyNotifier.value = _isNew || (_foundPack != null && 
			(_foundPack.name != _nameNotifier.value || 
			_foundPack.to != _languages[_toLangNotifier.value] ||
			_foundPack.from != _languages[_fromLangNotifier.value]));

    String _validateLanguages(AppLocalizations locale) => 
		_fromLangNotifier.value == _toLangNotifier.value ? 
			locale.packScreenSameTranslationDirectionsValidationError: null;

	void _checkTranslationPossibility(BuildContext buildContext, AppLocalizations locale) {
		if (_validateLanguages(locale) != null || 
			(_fromLangNotifier.value?.isEmpty ?? true) || (_toLangNotifier.value?.isEmpty ?? true))
			return;

		new WordDictionary(widget._provider, from: _languages[_fromLangNotifier.value], 
			to: _languages[_toLangNotifier.value]).isTranslationPossible().then((resp) {
				if (!resp)
					NoTranslationSnackBar.show(buildContext, locale);
			});
	}

    StoredPack _buildPack() => new StoredPack(_nameNotifier.value, 
        id: widget.packId,
        to: _languages[_toLangNotifier.value],
        from: _languages[_fromLangNotifier.value]
    );

    Future<void> _onSave(void afterSaving(StoredPack pack)) async {
		final state = _key.currentState;
		if (!state.validate())
			return;

		state.save();
		afterSaving((await _storage.upsert([_buildPack()])).first);
	}
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
