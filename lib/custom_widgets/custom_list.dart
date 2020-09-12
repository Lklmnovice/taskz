import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:taskz/custom_widgets/custom_reorderable_listview.dart';
import 'package:taskz/custom_widgets/tile.dart';
import 'package:taskz/model/data/task.dart';
import 'package:taskz/model/task_model.dart';

import '../services/locator.dart';

class CustomList extends StatefulWidget {
  @override
  _CustomListState createState() => _CustomListState();
}

class _CustomListState extends State<CustomList> {
  List<Task> todos;
  ScrollController _controller = ScrollController();

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
                  print(todos.map((e) => e.id).toList());
                  return CustomReorderableListView(
                    scrollController: _controller,
                    children: <Widget>[
                      for (final task in todos)
                        buildTile(context, task, true)
                    ],
                    onReorder: model.updateTaskOrder,
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
      key: ValueKey(task.id),
      task: task,
      subTasks: subTasks,
      isParent: isParent,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
  }
}
