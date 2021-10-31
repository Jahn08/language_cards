# language_cards

An Android application for learning foreign words through adding them as cards and studying them later. It features:

* Working offline
* 14 offline dictionaries for translating words and phrases when adding a card: 
  * English->German, English->French, English->Italian, English->Russian, English->Spanish
  * German->English, French->English, Italian->English, Spanish->English
  * Rusian->German, Russian->English, Russian->French, Russian->Italian, Russian->Spanish
* Uniting cards into categories
* Filtering cards and categories by alphabet
* Export/Import of cards in the JSON-format
* User settings: colour themes, parameters for shuffling chosen cards and their sides in the study mode, showing/hiding date of the last study for categories
* Pronouncing words and phrases on a card

## Installing / Getting started

The application is available for [Google Play](https://play.google.com/store/apps/details?id=language.cards.app).

## Developing

Since the project is developed with the Flutter framework its environment should be built before developing:
* [Flutter 2.2.2](https://flutter.dev/docs/get-started/install)
* [Open JDK 15](http://jdk.java.net/java-se-ri/15)
* [Android command line tools](https://developer.android.com/studio#downloads) with some packages installed by its utility *sdkmanger*:
  * platforms, system-images and build-tools - their particular versions depend on what Android OS the application is supposed to be emulated on: the target version is 30, the minimal one is 21
  * emulator
  * platform-tools

[Visual Studio Code](https://code.visualstudio.com/updates/v1_59) is used as an IDE with extensions:
* [Dart 3.27.2](https://marketplace.visualstudio.com/items?itemName=Dart-Code.dart-code)
* [Flutter 3.27.0](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)

