import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'file:///C:/Users/lenovo/Desktop/projects/dart/taskz/lib/services/locator.dart';
import 'package:taskz/model/task_model.dart';
import 'package:taskz/pages/add_label.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taskz/pages/home_page.dart';
import 'package:taskz/pages/upcoming_page.dart';
import 'package:taskz/pages/update_label.dart';

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
        textTheme: TextTheme(
            headline3: GoogleFonts.abrilFatface(fontSize: 48),
            bodyText1: GoogleFonts.roboto(
                fontSize: 16,
                color: Color(0xff1d3557),
                fontWeight: FontWeight.w400))),
    routes: <String, WidgetBuilder>{
      '/add_label': (context) => AddLabelPage(),
      '/update_label': (context) => UpdateLabelPage(),
      HomePage.pageRoute: (context) => HomePage(),
      UpcomingPage.pageRoute: (context) => UpcomingPage(),
    },
  );
}
