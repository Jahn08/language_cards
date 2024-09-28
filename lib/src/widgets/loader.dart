import 'package:flutter/material.dart';

class Loader extends StatelessWidget {
  const Loader();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class FutureLoader<TData> extends StatelessWidget {
  final Widget Function(TData data) dataWidgetBuilder;

  final Future<TData> future;

  const FutureLoader(this.future, this.dataWidgetBuilder);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: future,
        builder: (futureContext, AsyncSnapshot<TData> snapshot) {
          if (snapshot.hasError)
            throw Error.throwWithStackTrace(
                snapshot.error!, snapshot.stackTrace!);
          if (!snapshot.hasData) return const Loader();

          return dataWidgetBuilder(snapshot.data as TData);
        });
  }
}
