import 'package:flutter/foundation.dart';
import 'package:taskz/locator.dart';

import '../database_provider.dart';
import 'package:taskz/database_provider.dart';
import 'data/task.dart';

class TaskModel extends ChangeNotifier {
  final DatabaseProvider dbProvider;
  final Map<int,Task> _items;


  TaskModel()
      : _items={},
        dbProvider = locator<DatabaseProvider>() { //service injection
    _initializeTasks();
  }

  List<Task> get tasks => _items.values.toList(growable: false);

  /// insert a task into database
  ///
  /// two steps are involved
  /// 1. insert task into 'Task' table
  /// 2. insert tagIDs into 'TagTask' table
  /// Both of them will be handled by [DatabaseProvider.insertTask]
  void insertTask(
      String description,
      DateTime deadline,
      List<int> labelIds,
      int parentId,) async {
    if (parentId != null && _items.containsKey(parentId)) throw Exception('parentId is undefined');

    Task task = Task(description, labelIds: labelIds, deadline: deadline,);
    var id = await dbProvider.insertTask(task, parentId);

    task.id = id;

    if (parentId == null)
      _items[id] = task;
    else
      //todo
      print('fuck');
    notifyListeners();
  }


  Future<void> _initializeTasks() async {
    final tasks = await dbProvider.todayTasks;
    tasks.forEach((task) { _items[task.id] = task; });

    notifyListeners();
  }


}