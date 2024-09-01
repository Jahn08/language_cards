import 'package:flutter/material.dart';

abstract class OutcomeDialog<TResult> {
  const OutcomeDialog();

  @protected
  void returnResult(BuildContext context, [TResult result]) =>
      Navigator.pop(context, result);
}
