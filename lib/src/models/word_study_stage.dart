class WordStudyStage {
    static const int unknown = 0;

    static const int recognisedOnce = 25;
    
    static const int familiar = 50;
    
    static const int wellKnown = 75;
    
    static const int learned = 100;
    
    static const values = [unknown, recognisedOnce, familiar, 
        wellKnown, learned];

    static List<int> getValuesLowerOrEqual(int stage) {
        if (stage == unknown)
            return [unknown];
        else if (stage == learned)
            return WordStudyStage.values;

        return WordStudyStage.values.where((v) => v <= stage).toList();
    }

    static String stringify(int stage) {
        switch (stage) {
            case recognisedOnce:
                return 'Barely Known';
            case familiar:
                return 'Familiar';
            case wellKnown:
                return 'Well Known';
            case learned:
                return 'Learned';
            default:
                return 'New';
        }
    }
}
