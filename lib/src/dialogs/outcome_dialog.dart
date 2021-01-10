import 'package:flutter/material.dart';

abstract class OutcomeDialog<TResult> {
    @protected
    void returnResult(BuildContext context, [TResult result]) => Navigator.pop(context, result);
}
