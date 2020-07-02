import 'package:flutter/material.dart';
import 'package:taskz/model/data/label.dart';
import 'circular_icon.dart';



class LabelTile extends StatelessWidget {
final Label label;
final double iconSize;
final GestureTapCallback onTap;

LabelTile({this.label, this.iconSize=32, this.onTap});

@override
Widget build(BuildContext context) {
  return ListTile(
    onTap: onTap,
    leading: CircularIcon(
      icon: Icon(Icons.label, color: Color(label.colorValue),),
      size: iconSize,
    ),
    title: Text(label.description),
  );
}
}

