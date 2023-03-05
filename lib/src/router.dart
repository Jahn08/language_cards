import 'package:flutter/material.dart';
import './data/pack_storage.dart';
import './data/study_storage.dart';
import './data/word_storage.dart';

class _CardStorageRouteArgs {
final WordStorage storage;

_CardStorageRouteArgs([WordStorage storage]) : storage = storage ?? const WordStorage();
}

class _CardListRouteArgs extends _CardStorageRouteArgs {
	final StoredPack pack;

	final bool cardWasAdded;

	final bool packWasAdded;

	_CardListRouteArgs({WordStorage storage, bool cardWasAdded, bool packWasAdded, this.pack})
		: cardWasAdded = cardWasAdded ?? false,
			packWasAdded = packWasAdded ?? false,
			super(storage);
}

class CardListRoute {
	final _CardListRouteArgs params;

	CardListRoute.fromArguments(Object arguments)
		: params = arguments is _CardListRouteArgs ? arguments : new _CardListRouteArgs();
	}

	class _PackStorageRouteArgs {
	final PackStorage storage;

	const _PackStorageRouteArgs([this.storage]);
}

class _PackStorageWithCardsRouteArgs extends _PackStorageRouteArgs {
	final WordStorage cardStorage;

	const _PackStorageWithCardsRouteArgs([PackStorage storage, this.cardStorage]) : super(storage);
}

class PackListRoute {
	final _PackStorageWithCardsRouteArgs params;

	PackListRoute.fromArguments(Object arguments)
		: params = arguments is _PackStorageWithCardsRouteArgs
				? arguments
				: const _PackStorageWithCardsRouteArgs();
}

class _WordCardRouteArgs extends _CardStorageRouteArgs {
	final int wordId;

	final StoredPack pack;

	final PackStorage packStorage;

	_WordCardRouteArgs({WordStorage storage, PackStorage packStorage, this.wordId, this.pack})
		: packStorage = packStorage ?? const PackStorage(),
			super(storage);
}

class WordCardRoute {
	final _WordCardRouteArgs params;

	WordCardRoute.fromArguments(Object arguments)
		: params = arguments is _WordCardRouteArgs ? arguments : new _WordCardRouteArgs();
	}

	class _StudyStorageRouteArgs {
	final StudyStorage storage;

	const _StudyStorageRouteArgs([this.storage]);
}

class StudyPreparerRoute {
	final _StudyStorageRouteArgs params;

	StudyPreparerRoute.fromArguments(Object arguments)
		: params = arguments is _StudyStorageRouteArgs ? arguments : const _StudyStorageRouteArgs();
}

class _StudyModeRouteArgs extends _CardStorageRouteArgs {
	final List<StoredPack> packs;

	final List<int> studyStageIds;

	final BaseStorage<StoredPack> packStorage;

	_StudyModeRouteArgs(this.packs,
		{this.studyStageIds, WordStorage storage, BaseStorage<StoredPack> packStorage})
		: packStorage = packStorage ?? const PackStorage(),
			super(storage);
}

class StudyModeRoute {
	final _StudyModeRouteArgs params;

	StudyModeRoute.fromArguments(Object arguments)
		: params = arguments is _StudyModeRouteArgs ? arguments : new _StudyModeRouteArgs([]);
}

class _PackRouteArgs extends _PackStorageRouteArgs {
	final int packId;

	final bool refreshed;

	_PackRouteArgs({PackStorage storage, StoredPack pack, bool refreshed})
		: packId = pack?.id,
			refreshed = refreshed ?? false,
			super(storage);
}

class PackRoute {
	final _PackRouteArgs params;

	PackRoute.fromArguments(Object arguments)
		: params = arguments is _PackRouteArgs ? arguments : new _PackRouteArgs();
}

class PackHelpRoute {}

class CardHelpRoute {}

class StudyHelpRoute {}

class Router {
	static const String _cardRouteName = 'card';

	static const String _cardListRouteName = 'cardList';

	static const String _packRouteName = 'pack';

	static const String _packListRouteName = 'packList';

	static const String _studyPreparerRouteName = 'studyPreparer';

	static const String _studyModeRouteName = 'studyMode';

	static const String _mainMenuRouteName = 'mainMenu';

	static const String _cardHelpRouteName = 'cardHelp';

	static const String _packHelpRouteName = 'packHelp';

	static const String _studyHelpRouteName = 'studyHelp';

	static String get initialRouteName => _mainMenuRouteName;

	static void goToCard(BuildContext context, {WordStorage storage, int wordId, StoredPack pack}) {
		Navigator.pushNamed(context, _cardRouteName,
			arguments: new _WordCardRouteArgs(storage: storage, wordId: wordId, pack: pack));
	}

	static void goToCardList(BuildContext context,
		{WordStorage storage, StoredPack pack, bool cardWasAdded, bool packWasAdded}) {
		Navigator.pushNamed(context, _cardListRouteName,
			arguments: new _CardListRouteArgs(
				storage: storage, pack: pack, cardWasAdded: cardWasAdded, packWasAdded: packWasAdded));
	}

	static dynamic getRoute(RouteSettings settings) {
		switch (settings.name) {
			case _cardRouteName:
				return new WordCardRoute.fromArguments(settings.arguments);
			case _cardListRouteName:
				return new CardListRoute.fromArguments(settings.arguments);
			case _packRouteName:
				return new PackRoute.fromArguments(settings.arguments);
			case _packListRouteName:
				return new PackListRoute.fromArguments(settings.arguments);
			case _studyPreparerRouteName:
				return new StudyPreparerRoute.fromArguments(settings.arguments);
			case _studyModeRouteName:
				return new StudyModeRoute.fromArguments(settings.arguments);
			case _packHelpRouteName:
				return new PackHelpRoute();
			case _cardHelpRouteName:
				return new CardHelpRoute();
			case _studyHelpRouteName:
				return new StudyHelpRoute();
			default:
				return null;
		}
	}

	static void goHome(BuildContext context) => Navigator.pushNamed(context, initialRouteName);

	static void goToStudyPreparation(BuildContext context, [StudyStorage storage]) =>
		Navigator.pushNamed(context, _studyPreparerRouteName,
			arguments: new _StudyStorageRouteArgs(storage));

	static void goBackToStudyPreparation(BuildContext context) => _goBackUntil(context, _studyPreparerRouteName);

	static void goToStudyMode(BuildContext context,
		{@required List<StoredPack> packs, List<int> studyStageIds, WordStorage storage}) => 
		Navigator.pushNamed(context, _studyModeRouteName,
			arguments: new _StudyModeRouteArgs(packs, studyStageIds: studyStageIds, storage: storage));

	static void goToPack(BuildContext context,
		{PackStorage storage, StoredPack pack, bool refreshed}) {
		Navigator.pushNamed(context, _packRouteName,
			arguments: new _PackRouteArgs(storage: storage, pack: pack, refreshed: refreshed));
	}

	static void _goBackUntil(BuildContext context, String routeName) =>
		Navigator.popUntil(context, ModalRoute.withName(routeName));

	static void goToPackList(BuildContext context) =>
		Navigator.pushNamed(context, _packListRouteName);

	static void goBackToPackList(BuildContext context) => _goBackUntil(context, _packListRouteName);

	static void goToCardHelp(BuildContext context) =>
		Navigator.pushNamed(context, _cardHelpRouteName);

	static void goToPackHelp(BuildContext context) =>
		Navigator.pushNamed(context, _packHelpRouteName);

	static void goToStudyHelp(BuildContext context) =>
		Navigator.pushNamed(context, _studyHelpRouteName);
}
