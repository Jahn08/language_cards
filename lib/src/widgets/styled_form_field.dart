import 'package:flutter/material.dart';

abstract class StyledFormField extends StatelessWidget {
    @protected
    final InputDecoration decoration;

    StyledFormField(String hintText, {Key key}):
        decoration = new InputDecoration(
            hintText: hintText,
            contentPadding: EdgeInsets.only(left: 10, right: 10)
        ),
        super(key: key);
}
