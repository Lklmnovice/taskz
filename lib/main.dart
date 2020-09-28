import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskz/services/locator.dart';
import 'package:taskz/model/task_model.dart';
import 'package:taskz/pages/home_page.dart';
import 'package:taskz/pages/test_page.dart';
import 'package:taskz/pages/upcoming_page.dart';

import 'model/label_model.dart';

main() {
  WidgetsFlutterBinding.ensureInitialized();
  setup();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<LabelModel>(
        create: (context) => locator<LabelModel>(),
      ),
      ChangeNotifierProvider<TaskModel>(
        create: (context) => locator<TaskModel>(),
      )
    ],
    child: _myApp(),
  ));

//  ReorderableListView
}

Widget _myApp() {
  return MaterialApp(
    title: "taskz",
    // initialRoute: TestPage.pageRoute,
    initialRoute: HomePage.pageRoute,
    theme: ThemeData(
      // Define the default brightness and colors.
      brightness: Brightness.light,
      accentColor: Colors.redAccent,
      hintColor: Colors.grey[400],
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xff1d3557),
        primaryVariant: Color(0xff457B9D),
        secondary: Color(0xffffffff),
        secondaryVariant: Color(0xffb4b4b4),
        surface: Colors.white,
        background: Colors.white,
        error: Color(0xffE63946),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xff1d3557),
        onBackground: Color(0xff1d3557),
        onError: Colors.white,
      ),

      // Define the default font family.
      fontFamily: 'roboto',

      // Define the default TextTheme. Use this to specify the default
      // text styling for headlines, titles, bodies of text, and more.
    ),
    routes: <String, WidgetBuilder>{
      HomePage.pageRoute: (context) => HomePage(),
      UpcomingPage.pageRoute: (context) => UpcomingPage(),
      TestPage.pageRoute: (context) => TestPage(),
    },
  );
}
