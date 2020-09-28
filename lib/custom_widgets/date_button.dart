import 'package:flutter/material.dart';

import 'custom_date_picker.dart';
import 'package:taskz/services/time_util.dart';

class DateButton extends StatelessWidget {
  DateButton({this.mainContext, this.setTime, this.initialDateTime});

  final BuildContext mainContext;
  final Function(DateTime dateTime) setTime;
  final DateTime initialDateTime;

  @override
  Widget build(BuildContext context) {
    return OutlineButton(
        visualDensity: VisualDensity.compact,
        shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12))),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        onPressed: () {
          showCustomDatePicker(mainContext).then((date) {
            if (date != null) setTime(date);
          });
        },
        child: Text(
          initialDateTime.getMonthStrShort(),
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.error),
        ));
  }
}
