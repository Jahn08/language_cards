import './cancellable_dialog.dart';

abstract class SelectorDialog<T> extends CancellableDialog<T> {
    Future<T> show(List<T> items);
}
