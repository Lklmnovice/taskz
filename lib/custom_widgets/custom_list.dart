import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:taskz/custom_widgets/tile.dart';
import 'package:taskz/model/data/task.dart';
import 'package:taskz/model/task_model.dart';

import '../locator.dart';

class CustomList extends StatefulWidget {
  @override
  _CustomListState createState() => _CustomListState();
}

class _CustomListState extends State<CustomList> {
  List<Task> todos;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
        future: locator.allReady(),
        builder: (context, snapshot) {
          if (snapshot.hasData)
            return MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: Consumer<TaskModel>(
                builder: (context, model, child) {
                  final todos = model.tasks;
                  return ListView.separated(
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      return buildTile(context, todos[index], true);
                    },
                    separatorBuilder: (context, index) => SizedBox(
                      height: 16,
                    ),
                  );
                },
              ),
            );
          else
            return Center(
                child: SpinKitCubeGrid(size: 50, color: Colors.lightBlue));
        });
  }

  CustomTile buildTile(BuildContext context, Task task, bool isParent) {
    List<CustomTile> subTasks = [
      for (var t in task.subTask) buildTile(context, t, false)
    ];

    return CustomTile(
      task: task,
      subTasks: subTasks,
      isParent: isParent,
    );
  }
}
