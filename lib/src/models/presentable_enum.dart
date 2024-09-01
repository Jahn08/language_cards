import 'package:flutter_gen/gen_l10n/app_localizations.dart';

abstract class PresentableEnum {
  final int index;

  const PresentableEnum(this.index);

  String present(AppLocalizations locale);

  static Map<String, T> mapStringValues<T extends PresentableEnum>(
          Iterable<T> values, AppLocalizations locale) =>
      <String, T>{for (final v in values) v.present(locale): v};
}
