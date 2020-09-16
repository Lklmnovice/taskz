import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskz/services/database_provider.dart';
import 'package:taskz/services/locator.dart';

import 'data/task.dart';

class TaskModel extends ChangeNotifier {
  TaskModel()
      : _items = {},
        dbProvider = locator<DatabaseProvider>();

  final DatabaseProvider dbProvider;
  final Map<int, Task> _items; //contains every single item
  List<int> _topItemsOrder; //only top-level items
  int nTodayTask;

  final String _todayStr = 'DATE';
  final String _tasksOrderStr = 'TASKS_ORDER';
  final String _nTodayTaskStr = 'TASKS_NUM';

  /// Gets a list of top-level tasks
  List<Task> get tasks {
    return List.generate(_topItemsOrder.length, (index) {
      return _items[_topItemsOrder[index]];
    });
  }

  /// Insert a task into database
  ///
  /// 1. insert task into 'Task' table
  /// 2. insert tagIDs into 'TagTask' table
  /// Both of them will be handled by [DatabaseProvider.insertTask]
  /// [posBefore] defines the position where the task will be inserted
  void insertTask(
      String description, DateTime deadline, List<int> labelIds, int parentId,
      [int posBefore = -1]) async {
    Task task = Task(
      description,
      labelIds: labelIds,
      deadline: deadline,
    );
    var id = await dbProvider.insertTask(task, parentId);
    task.id = id;
    _items[id] = task;

    if (parentId == null) {
      if (posBefore != -1)
        _topItemsOrder.insert(posBefore + 1, id);
      else
        _topItemsOrder.add(id);
      _saveTasksOrder();
    } else {
      _items[parentId].subTask.add(task);
    }
    notifyListeners();
  }

  void updateTask() {}

  /// Completes a task
  ///
  /// It will display a [SnackBar] that allows user to revoke a completion.
  /// Otherwise after the timeout, the completion will be definitive.
  /// There must be a scaffold in the given [context]
  Future<void> completeTask(BuildContext context, int id) async {
    //complete the task and its subtasks
    var parentTaskId = _items[id].parentId;
    var tempSubTasks = parentTaskId != null
            ? List<Task>.from(_items[parentTaskId]?.subTask ?? [])
            : [],
        tempTopItemsOrder = List<int>.from(_topItemsOrder);
    var isAmongTopItems = false;
    if (_topItemsOrder.contains(id)) {
      _topItemsOrder.remove(id);
      _saveTasksOrder();
      isAmongTopItems = true;
    } else
      _items[parentTaskId].subTask.removeWhere((s) => s.id == id);
    notifyListeners();

    final sfld = Scaffold.of(context);
    sfld
        .showSnackBar(SnackBar(
          content: Text('A task has been deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              sfld.hideCurrentSnackBar();
              print('todo pressed');
            },
          ),
        ))
        .closed
        .then((SnackBarClosedReason reason) async {
      if (reason == SnackBarClosedReason.action) {
        // revoke the operation
        if (isAmongTopItems) {
          _topItemsOrder = tempTopItemsOrder;
          _saveTasksOrder();
        } else
          _items[parentTaskId]?.subTask = tempSubTasks;
        notifyListeners();
      } else // Proceeds to update database
        await dbProvider.completeTask(id);
    });
  }

  //todo reordering subtasks
  void updateTaskOrder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final i = _topItemsOrder.removeAt(oldIndex);
    _topItemsOrder.insert(newIndex, i);
    _saveTasksOrder();
    notifyListeners();
  }

  String _formatDDMMYYYY(DateTime dateTime) {
    return '${dateTime.day}-${dateTime.month}-${dateTime.year}';
  }

  //todo extract sharedPreferences logic
  void _saveTasksOrder() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_tasksOrderStr, jsonEncode(_topItemsOrder));
  }

  /// initialize today's tasks
  /// Reserved to [locator]
  ///
  /// After obtaining tasks, check if it's the first time that today's tasks are
  /// retrieved, if it is then save the current order using [_saveTasksOrder]
  /// Otherwise, display tasks under saved order
  Future<void> initialize() async {
    final results = await Future.wait([
      SharedPreferences.getInstance(),
      dbProvider.todayTasks,
    ]);

    SharedPreferences prefs = results[0];
    List<dynamic> dbResults = results[1];

    _items.addAll(dbResults[0]);
    List<Task> topLevelTasks = dbResults[1];

    var time = DateTime.now();
    if (prefs.getString(_todayStr) == _formatDDMMYYYY(time)) {
      var str = prefs.getString(_tasksOrderStr);
      _topItemsOrder = (jsonDecode(str) as List).map((e) => e as int).toList();
      nTodayTask = prefs.getInt(_nTodayTaskStr);
    } else {
      _topItemsOrder = topLevelTasks.map((task) => task.id).toList();
      nTodayTask = _topItemsOrder.length;
      var json = jsonEncode(_topItemsOrder);
      prefs.setString(_tasksOrderStr, json);
      prefs.setString(_todayStr, _formatDDMMYYYY(time));
      prefs.setInt(_nTodayTaskStr, _topItemsOrder.length);
    }
    notifyListeners();
  }
}
