import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskz/services/database_provider.dart';
import 'package:taskz/services/locator.dart';
import 'package:taskz/services/time_util.dart';
import 'data/task.dart';

class TaskModel extends ChangeNotifier {
  TaskModel()
      : _items = {},
        dbProvider = locator<DatabaseProvider>();

  final DatabaseProvider dbProvider;
  final Map<int, Task>
      _items; //contains unfinished or due tasks for today or even future
  List<int> _topItemsOrder; //only top-level items of _items
  Map<String, List<Task>> upcomingTasks;
  int nTodayTask;

  static const _todayStr = 'DATE';
  static const _tasksOrderStr = 'TASKS_ORDER';
  static const _nTodayTaskStr = 'TASKS_NUM';

  bool needsRebuildUpcomingTasks = true;

  /// Gets a list of top-level tasks
  List<Task> get todayTasks {
    return List.generate(_topItemsOrder.length, (index) {
      return _items[_topItemsOrder[index]];
    });
  }

  Future<int> countTasksInDate(DateTime dateTime) async {
    if (dateTime == null) return 0;
    if (needsRebuildUpcomingTasks || upcomingTasks == null) {
      upcomingTasks = await dbProvider.upcomingTasks;
      needsRebuildUpcomingTasks = false;
    }

    return upcomingTasks[dateTime.toHyphenedYYYYMMDD()]?.length ?? 0;
  }

  /// Insert a task into database
  ///
  /// 1. insert task into 'Task' table
  /// 2. insert tagIDs into 'TagTask' table
  /// Both of them will be handled by [DatabaseProvider.insertTask]
  /// [posBefore] defines the position where the task will be inserted
  Future<void> insertTask(String description, DateTime deadline,
      [List<int> labelIds,
      int parentId,
      String note = '',
      int posBefore = -1]) async {
    Task task = Task(description,
        labelIds: labelIds, deadline: deadline, note: note, parentId: parentId);
    var id = await dbProvider.insertTask(task);
    task.id = id;
    _items[id] = task;

    // whether to display it
    assert(task.isCompleted == false);
    if (deadline <= DateTimeFormatter.tomorrow) {
      if (!task.hasParent) {
        if (posBefore != -1)
          _topItemsOrder.insert(posBefore, id);
        else
          _topItemsOrder.add(id);
        _saveTasksOrder();
      } else {
        print('${task.hasParent} ==> ${task.parentId}');
        _items[parentId].subTask.add(task);
      }
    }

    notifyListeners();
  }

  /// Updates a task
  ///
  /// Only updates descriptive filed of a task
  Future<void> updateTask(
    int id,
    String description,
    DateTime deadline, [
    List<int> labelIds,
    String note = '',
  ]) async {
    // in order to update a task, the user has to press an existing one on the
    // screen which means it must already be part of [_items]
    assert(_items[id] != null);
    assert(_items[id].id == id);
    final prevDate = _items[id].deadline;
    final task = _items[id]
      ..description = description
      ..labelIds = labelIds
      ..deadline = deadline
      ..note = note;
    await dbProvider.updateTask(task);

    if (deadline > prevDate) {
      if (_topItemsOrder.remove(id)) _saveTasksOrder();
      _items.remove(id);
    }
    notifyListeners();
  }

  /// Deletes a task
  Future<void> deleteTask(int id) async {
    if (_topItemsOrder.remove(id)) _saveTasksOrder();
    _items.remove(id);
    needsRebuildUpcomingTasks = true;
    await dbProvider.deleteTask(id);

    notifyListeners();
  }

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
    if (prefs.getString(_todayStr) == time.toHyphenedYYYYMMDD()) {
      var str = prefs.getString(_tasksOrderStr);
      _topItemsOrder = (jsonDecode(str) as List).map((e) => e as int).toList();
      nTodayTask = prefs.getInt(_nTodayTaskStr);
    } else {
      _topItemsOrder = topLevelTasks.map((task) => task.id).toList();
      nTodayTask = _topItemsOrder.length;
      var json = jsonEncode(_topItemsOrder);
      prefs.setString(_tasksOrderStr, json);
      prefs.setString(_todayStr, time.toHyphenedYYYYMMDD());
      prefs.setInt(_nTodayTaskStr, _topItemsOrder.length);
    }
    notifyListeners();
  }
}
