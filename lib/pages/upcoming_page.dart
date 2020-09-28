import 'package:flutter/material.dart';
import 'package:taskz/pages/drawer.dart';

class UpcomingPage extends StatelessWidget {
  static final String pageRoute = '/upcoming_page';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text('todo'),
      endDrawer: CustomDrawer(),
    );
  }
}
