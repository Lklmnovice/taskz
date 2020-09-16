import 'package:flutter/material.dart';
import 'package:taskz/model/data/label.dart';
import 'package:taskz/extended_string.dart';

class LabelTile extends StatelessWidget {
  LabelTile(
      {this.label,
      this.iconSize = 32,
      this.onTap,
      this.backgroundColor = Colors.transparent,
      this.textColor = Colors.black,
      this.padding = const EdgeInsets.symmetric(horizontal: 4)});

  final double iconSize;
  final GestureTapCallback onTap;
  final Color backgroundColor, textColor;
  final Label label;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      // color: Colors.transparent,
      color: backgroundColor,
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          Icons.label,
          color: Color(label.colorValue),
        ),
        title: Text(
          label.description.capitalize(),
          style: TextStyle(color: textColor, fontSize: 16),
        ),
      ),
    );
  }
}
