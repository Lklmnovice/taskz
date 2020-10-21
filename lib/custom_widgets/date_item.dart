import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskz/model/task_model_new.dart';

import 'custom_date_picker.dart';

class Item extends StatelessWidget {
  Item(
      {this.textColor,
      this.date,
      this.size = CALENDAR_E_HEIGHT,
      this.boxDecoration,
      this.boldText = false,
      this.onTap});

  final Color textColor;
  final DateTime date;
  final double size;
  final BoxDecoration boxDecoration;
  final boldText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String str = date?.day?.toString();
    return GestureDetector(
      onTap: onTap ?? () => Navigator.of(context).pop(date),
      child: Consumer<TaskModel>(
        builder: (context, model, child) {
          final count = model.countTasksInDate(date);
          final _widget = Positioned(
            bottom: 0,
            child: (count == 0)
                ? Container()
                : (count < 4) ? _Dot() : _Dot.double(),
          );
          return Container(
              decoration: this.boxDecoration,
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (child != null) child,
                  if (_widget != null) _widget
                ],
              ));
        },
        child: str != null
            ? Text(str,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: boldText ? FontWeight.bold : FontWeight.normal,
                    color: textColor))
            : Container(),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  _Dot.double() : isDouble = true;
  _Dot() : isDouble = false;

  final bool isDouble;
  final _size = 5.0;

  @override
  Widget build(BuildContext context) {
    return isDouble
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle),
              ),
              SizedBox(width: 2),
              Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle),
              ),
            ],
          )
        : Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle),
          );
  }
}

class WeekdaysRow extends StatelessWidget {
  WeekdaysRow({
    this.strs = const ['M', 'T', 'T', 'W', 'F', 'S', 'S'],
    this.textColor,
  }) : assert(strs.length == 7);

  final List<String> strs;
  final Color textColor;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (final s in strs)
          Container(
            width: CALENDAR_E_HEIGHT,
            height: CALENDAR_E_HEIGHT,
            alignment: Alignment.center,
            child: Text(s, style: TextStyle(fontSize: 14, color: textColor)),
          )
      ],
    );
  }
}
