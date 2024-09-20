import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/models/language.dart';
import 'package:language_cards/src/models/user_params.dart';
import 'package:flutter/widgets.dart';

void main() {
  const paramsJson =
      '{"interfaceLang":1,"theme":1,"studyParams":{"direction":1,"cardSide":2,"showStudyDate":false,"packOrder":2},"languagePair":{"from":0,"to":2}}';

  test('Creates user params from json', () {
    final params = UserParams(paramsJson);
    expect(params.getLocale(), const Locale('ru'));
    expect(params.theme, AppTheme.dark);

    expect(params.languagePair,
        const LanguagePair(Language.english, Language.german));

    expect(params.studyParams.cardSide, CardSide.random);
    expect(params.studyParams.direction, StudyDirection.backward);
    expect(params.studyParams.packOrder, PackOrder.byDateAsc);
    expect(params.studyParams.showStudyDate, false);
  });

  test('Creates default user params from an empty string', () => _testNullifiedJsonInput(''));

  test('Creates default user params from a null string', () => _testNullifiedJsonInput(null));

  test('Presents user params as json', () {
    final params = UserParams(paramsJson);

    params.theme = AppTheme.light;
    params.studyParams.packOrder = PackOrder.byDateDesc;
    params.studyParams.direction = StudyDirection.random;
    params.studyParams.showStudyDate = true;

    params.languagePair = const LanguagePair(Language.french, Language.spanish);

    expect(params.toJson(),
        '{"interfaceLang":1,"theme":0,"studyParams":{"direction":2,"cardSide":2,"showStudyDate":true,"packOrder":3},"languagePair":{"from":3,"to":5}}');
  });

  test('Presents default user params as json', () {
    final params = UserParams();
    expect(params.toJson(),
        '{"interfaceLang":0,"theme":0,"studyParams":{"direction":0,"cardSide":0,"showStudyDate":true,"packOrder":0},"languagePair":null}');
  });
}

void _testNullifiedJsonInput(String? nullifiedJson) {
  final params = UserParams(nullifiedJson);

  expect(params.getLocale(), const Locale('en'));
  expect(params.theme, AppTheme.light);

  expect(params.languagePair, null);

  expect(params.studyParams.cardSide, CardSide.front);
  expect(params.studyParams.direction, StudyDirection.forward);
  expect(params.studyParams.packOrder, PackOrder.byNameAsc);
  expect(params.studyParams.showStudyDate, true);
}
