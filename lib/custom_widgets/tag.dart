import 'package:flutter/material.dart';

class Tag extends StatelessWidget {
  final String desc;
  final int color;

  Tag({this.desc, this.color = 0xffbdbdbd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        color: Color(color),
        borderRadius: BorderRadius.all(Radius.circular(32)),
      ),
      child: Text('$desc',
          style: TextStyle(
              fontSize: 8, color: Colors.white, fontWeight: FontWeight.w500)),
    );
  }
}
