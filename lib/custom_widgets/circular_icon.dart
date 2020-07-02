import 'package:flutter/material.dart';

class CircularIcon extends StatelessWidget {
  final Icon icon;
  final double size;
  final Color backgroundColor;

  CircularIcon({@required this.icon, this.size=32, this.backgroundColor=Colors.grey});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        color: backgroundColor,
        child: SizedBox(
          width: size,
          height: size,
          child: icon,
        ),
      ),
    );
  }
}
