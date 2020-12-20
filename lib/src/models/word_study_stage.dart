class WordStudyStage {
    static const int unknown = 0;

    static const int recognisedOnce = 25;
    
    static const int familiar = 50;
    
    static const int wellKnown = 75;
    
    static const int learned = 100;

    static const values = [unknown, recognisedOnce, familiar, 
        wellKnown, learned];

    static const String _familiarStageName = 'Familiar';

    static const String _wellKnownStageName = 'Well Known';
    
    static const String _learnedStageName = 'Learned';
    
    static const String _newStageName = 'New';

    static int nextStage(int stage) {
        if (stage == learned)
            return learned;

        return WordStudyStage.values.firstWhere((v) => v > stage, 
            orElse: () => learned);
    }

    static String stringify(int stage) {
        switch (stage) {
            case recognisedOnce:
            case familiar:
                return _familiarStageName;
            case wellKnown:
                return _wellKnownStageName;
            case learned:
                return _learnedStageName;
            default:
                return _newStageName;
        }
    }

    static List<int> fromString(String name) {
        switch (name) {
            case _familiarStageName:
                return [recognisedOnce, familiar];
            case _wellKnownStageName:
                return [wellKnown];
            case _learnedStageName:
                return [learned];
            case _newStageName:
                return [unknown];
            default:
                return null;
        }
    }
}
