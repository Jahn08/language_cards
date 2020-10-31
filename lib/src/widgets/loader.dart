import 'package:flutter/material.dart';

class Loader extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return new Center(
            child: new CircularProgressIndicator()
        );
    }
}

class FutureLoader<TData> extends StatelessWidget {
    final Widget Function(TData data) dataWidgetBuilder;

    final Future<TData> future;

    FutureLoader(this.future, this.dataWidgetBuilder) {
        assert(future != null);
        assert(dataWidgetBuilder != null);
    }

    @override
    Widget build(BuildContext context) {
        return FutureBuilder(future: future,
            builder: (futureContext, AsyncSnapshot<TData> snapshot) {
                if (!snapshot.hasData)
                    return new Loader();

                return dataWidgetBuilder(snapshot.data);
            });
    }
}
