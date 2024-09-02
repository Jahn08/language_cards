# language_cards

An Android application for learning foreign words through adding them as cards and studying them later. It features:

* 14 offline dictionaries for translating words and phrases when adding a card: 
  * English->German, English->French, English->Italian, English->Russian, English->Spanish
  * German->English, French->English, Italian->English, Spanish->English
  * Rusian->German, Russian->English, Russian->French, Russian->Italian, Russian->Spanish
* Uniting cards into categories
* Filtering cards and categories by alphabet
* Export/Import of cards in the JSON-format
* User settings: colour themes, the language of interface (English or Russian), parameters for shuffling chosen cards and their sides in the study mode, showing/hiding date of the last study for categories
* Working offline
* Pronouncing words and phrases on a card

## Installing / Getting started

The application is available for [Google Play](https://play.google.com/store/apps/details?id=language.cards.app).

## Developing

Since the project is developed with the Flutter framework its environment must be built beforehand:
* [Flutter 3.24.1](https://flutter.dev/docs/get-started/install)
* [Open JDK 22](http://jdk.java.net)
* [Android command line tools](https://developer.android.com/studio#downloads) with some packages installed by its utility *sdkmanager*:
  * platforms, system-images and build-tools - their particular versions depend on what Android OS the application is supposed to be emulated on: the target version is 35, the minimal one is 21
  * cmdline-tools
  * emulator
  * platform-tools

To create an emulator for debugging run a command: *avdmanager -s create avd -n <emulator name> -k "<system_images full pack name>" -d <device number>*.
The device number parameter is optional, to list such devices use a command: *avdmanager list*.

[Visual Studio Code](https://code.visualstudio.com/) is used as an IDE with extensions:
* [Dart](https://marketplace.visualstudio.com/items?itemName=Dart-Code.dart-code)
* [Flutter](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)

 ## Configuration
 
 The configuration file of the application is *assets/cfg/params.json*, it consists of the next parameters:
* The *contacts* section has options for setting up the respective expandable section on the panel with user preferences:
  * *facebook_user_id* is a FB user's id to render a link leading to the FB profile
  * *email* - an email for sending a report about bugs or propositions
  * *app_store_id* - for rendering a valid link to the application in Google Play.
 
 A file *assets/cfg/secret_params.json* can be created with the same structure to keep parameters locally without tracking it in GIT.
