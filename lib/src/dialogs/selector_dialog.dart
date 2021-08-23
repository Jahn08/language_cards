import 'outcome_dialog.dart';

abstract class SelectorDialog<T> extends OutcomeDialog<T> {

	const SelectorDialog(): super();

    Future<T> show(List<T> items);
}
