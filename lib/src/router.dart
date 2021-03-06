import 'package:flutter/material.dart';
import './data/base_storage.dart';
import './data/pack_storage.dart';
import './data/study_storage.dart';
import './data/word_storage.dart';

WordStorage _getCardStorageOrDefault(BaseStorage<StoredWord> storage) => 
	storage ?? new WordStorage();

PackStorage _getPackStorageOrDefault(BaseStorage<StoredPack> storage) => 
	storage ?? new PackStorage();

class _CardStorageRouteArgs {
    final BaseStorage<StoredWord> storage;

    _CardStorageRouteArgs([WordStorage storage]): 
		storage = _getCardStorageOrDefault(storage);
}

class _CardListRouteArgs extends _CardStorageRouteArgs {
    final StoredPack pack;

    final bool cardWasAdded;

    _CardListRouteArgs({ WordStorage storage, bool cardWasAdded, this.pack }):
        cardWasAdded = cardWasAdded ?? false, 
        super(storage);
}

class CardListRoute { 
    final _CardListRouteArgs params;

    CardListRoute.fromArguments(Object arguments): 
        params = arguments is _CardListRouteArgs ? arguments : new _CardListRouteArgs();
}

class _PackStorageRouteArgs {
    final BaseStorage<StoredPack> storage;

    _PackStorageRouteArgs([PackStorage storage]): 
        storage = _getPackStorageOrDefault(storage);
}

class _PackStorageWithCardsRouteArgs extends _PackStorageRouteArgs {
    final WordStorage cardStorage;

    _PackStorageWithCardsRouteArgs([PackStorage storage, WordStorage cardStorage]):
		cardStorage = _getCardStorageOrDefault(cardStorage),
		super(storage);
}

class PackListRoute { 
    final _PackStorageWithCardsRouteArgs params;

    PackListRoute.fromArguments(Object arguments): 
        params = arguments is _PackStorageWithCardsRouteArgs ? arguments : 
			new _PackStorageWithCardsRouteArgs();
}

class _WordCardRouteArgs extends _CardStorageRouteArgs {
    final int wordId;

    final StoredPack pack;

    final BaseStorage<StoredPack> packStorage;

    _WordCardRouteArgs({ BaseStorage<StoredWord> storage, 
        BaseStorage<StoredPack> packStorage, int wordId, this.pack }): 
        wordId = wordId,
        packStorage = packStorage ?? new PackStorage(),
        super(storage);
}

class WordCardRoute { 
    final _WordCardRouteArgs params;

    WordCardRoute.fromArguments(Object arguments): 
        params = arguments is _WordCardRouteArgs ? arguments : new _WordCardRouteArgs();
}

class _StudyStorageRouteArgs {
    final StudyStorage storage;

    _StudyStorageRouteArgs([StudyStorage storage]):
        storage = storage ?? new PackStorage();
}

class StudyPreparerRoute { 
    final _StudyStorageRouteArgs params;

    StudyPreparerRoute.fromArguments(Object arguments): 
        params = arguments is _StudyStorageRouteArgs ? arguments : new _StudyStorageRouteArgs();
}

class _StudyModeRouteArgs extends _CardStorageRouteArgs {
    final List<StoredPack> packs;

    final List<int> studyStageIds;

    final BaseStorage<StoredPack> packStorage;

    _StudyModeRouteArgs(this.packs, 
		{ this.studyStageIds, WordStorage storage, BaseStorage<StoredPack> packStorage }):
        packStorage = packStorage ?? new PackStorage(),
        super(storage);
}

class StudyModeRoute { 
    final _StudyModeRouteArgs params;

    StudyModeRoute.fromArguments(Object arguments): 
        params = arguments is _StudyModeRouteArgs ? arguments : new _StudyModeRouteArgs([]);
}

class _PackRouteArgs extends _PackStorageRouteArgs {
    final int packId;

    final String packName;

    final bool refreshed;

    _PackRouteArgs({ BaseStorage<StoredPack> storage, StoredPack pack, bool refreshed }): 
        packId = pack?.id,
        packName = pack?.name ?? '',
        refreshed = refreshed ?? false,
        super(storage);
}

class PackRoute { 
    final _PackRouteArgs params;

    PackRoute.fromArguments(Object arguments): 
        params = arguments is _PackStorageRouteArgs ? arguments : new _PackStorageRouteArgs();
}

class Router {
    static const String _cardRouteName = 'card';

    static const String _cardListRouteName = 'cardList';

    static const String _packRouteName = 'pack';

    static const String _packListRouteName = 'packList';

    static const String _studyPreparerRouteName = 'studyPreparer';

    static const String _studyModeRouteName = 'studyMode';

    static const String _mainMenuRouteName = 'mainMenu';

    static String get initialRouteName => _mainMenuRouteName;

    static goToCard(BuildContext context, 
        { BaseStorage<StoredWord> storage, int wordId, StoredPack pack }) {
        Navigator.pushNamed(context, _cardRouteName, 
            arguments: new _WordCardRouteArgs(storage: storage, wordId: wordId, pack: pack));
    }

    static goToCardList(BuildContext context, 
        { BaseStorage<StoredWord> storage, StoredPack pack, bool cardWasAdded }) {
        Navigator.pushNamed(context, _cardListRouteName, 
            arguments: new _CardListRouteArgs(storage: storage, pack: pack,
                cardWasAdded: cardWasAdded));
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
            default:
                return null;
        }
    }

    static goHome(BuildContext context) => Navigator.pushNamed(context, initialRouteName);

    static goToStudyPreparation(BuildContext context, [StudyStorage storage]) => 
        Navigator.pushNamed(context, _studyPreparerRouteName, 
            arguments: new _StudyStorageRouteArgs(storage));

    static goToStudyMode(BuildContext context, { @required List<StoredPack> packs,
        List<int> studyStageIds, WordStorage storage }) => 
        Navigator.pushNamed(context, _studyModeRouteName, 
            arguments: new _StudyModeRouteArgs(packs, studyStageIds: studyStageIds, storage: storage));

    static goToPack(BuildContext context, 
        { BaseStorage<StoredPack> storage, StoredPack pack, bool refreshed }) {
        Navigator.pushNamed(context, _packRouteName, 
            arguments: new _PackRouteArgs(storage: storage, pack: pack, refreshed: refreshed));
    }

    static goBackToPack(BuildContext context) => _goBackUntil(context, _packRouteName);

    static _goBackUntil(BuildContext context, String routeName) => 
        Navigator.popUntil(context, ModalRoute.withName(routeName));

    static goToPackList(BuildContext context) => Navigator.pushNamed(context, _packListRouteName);

    static goBackToPackList(BuildContext context) => _goBackUntil(context, _packListRouteName);
}
