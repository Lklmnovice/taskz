import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskz/locator.dart';
import 'package:taskz/model/task_model.dart';
import 'package:taskz/pages/add_label.dart';
import 'package:taskz/pages/add_task.dart';
import 'package:taskz/pages/home.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taskz/pages/update_label.dart';

import 'model/label_model.dart';

main() {
  setup();
  runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LabelModel>(
            create: (context) => locator<LabelModel>(),
          ),
          ChangeNotifierProvider<TaskModel>(
            create: (context) => locator<TaskModel>(),
          )
        ],
        child: _myApp(),
      )
  );

  ReorderableListView
}

Widget _myApp() {
  return MaterialApp(
    title: "taskz",
    initialRoute: '/',
    theme: ThemeData(
      // Define the default brightness and colors.
        brightness: Brightness.light,
        accentColor: Colors.redAccent,
        hintColor: Colors.grey[400],

        colorScheme: ColorScheme(
          brightness: Brightness.light,

          primary: Color(0xff1d3557),
          primaryVariant: Color(0xff457B9D),
          secondary: Color(0xffE63946),
          secondaryVariant: Color(0xffa8dadc),

//            Color(0xF1FAEE),
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
            bodyText1: GoogleFonts.roboto(fontSize: 16, color: Color(0xff1d3557), fontWeight: FontWeight.w400))


    ),
    routes: <String, WidgetBuilder>{
      '/': (context) => Home(),
      '/add_label': (context) => AddLabelPage(),
      '/update_label': (context) => UpdateLabelPage(),
    },

    onGenerateRoute: (settings) {
      if (settings.name == '/add_task')
        return PageRouteBuilder(
          settings: settings,
          opaque: false,
          barrierColor: Colors.grey.withOpacity(0.1),
          barrierDismissible: true,
          pageBuilder: (_, __, ___) => AddTaskPage(),
        );

      return MaterialPageRoute(builder: (context) => Home());
    },
  );
}