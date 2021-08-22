import './cancellable_dialog.dart';

abstract class SelectorDialog<T> extends CancellableDialog<T> {

	const SelectorDialog(): super();

    Future<T> show(List<T> items);
}
