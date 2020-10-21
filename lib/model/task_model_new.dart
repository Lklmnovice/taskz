import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:taskz/model/data/task.dart';
import 'package:taskz/services/database_provider.dart';
import 'package:taskz/services/locator.dart';
import 'package:taskz/services/shared_preferences.dart';
import 'package:taskz/services/time_util.dart';

const PAGE_TODAY_STR = 'TODAY';
const TODAY_COMPLETED_TASK = 'TODAY_COMPLETED_N';
const TODAY_TOTAL_TASK = 'TODAY_TOTAL_TASK';

enum Model { TODAY, FILTERED, UPCOMING }

class TaskModel extends ChangeNotifier {  
  TaskModel._()
      : _items = {},
        _pageModel = {},
        dbProvider = locator<DatabaseProvider>();

  static Future<TaskModel> initialize() async {
    final model = TaskModel._();
    await model._initialize();
    return model;
  }

  final DatabaseProvider dbProvider;
  final Map<int, Task> _items; //contains unfinished or due tasks since today

  final Map<String, _PageOrderModel> _pageModel;

  bool needsRebuildUpcomingTasks = true;
  Map<String, List<Task>> upcomingTasks;

  /// initialize the taskModel by
  /// 1. populating it with all unfinished tasks
  /// 2. create [_PageOrderModel] for today's task
  Future<void> _initialize() async {
    final map = await dbProvider.allUnfinishedTasks;
    _items.addAll(map);
    await initializePage(-1);
  }

  /// Requires a page id in order to access a view of database
  ///
  /// Today page ==> -1
  /// Pages where tasks are filtered by tag ==> tag.id
  _PageOrderModel pageId(int id, {Model m = Model.TODAY, DateTime dateTime}) {
    switch (m) {
      case Model.TODAY:
        return _pageModel['TODAY'];
        break;
      case Model.FILTERED:
        return _pageModel['LABEL$id'];
        break;
      case Model.UPCOMING:
        dateTime ??= DateTimeFormatter.today;
        return _pageModel['UPCOMING${dateTime.toHyphenedYYYYMMDD()}'];
        break;
    }
  }

  /// Returns number of tasks in the given date
  int countTasksInDate(DateTime dateTime) {
    if (dateTime == null) return 0;
    if (needsRebuildUpcomingTasks || upcomingTasks == null) {
      upcomingTasks = {};
      _items.forEach((_, task) {
        if (task.deadline != null)
          upcomingTasks.update(
              task.deadline.toHyphenedYYYYMMDD(), (list) => list..add(task),
              ifAbsent: () => [task]);
      });
      needsRebuildUpcomingTasks = false;
    }

    return upcomingTasks[dateTime.toHyphenedYYYYMMDD()]?.length ?? 0;
  }

  /// Initialize the data model to the given page
  ///
  /// For upcoming page, you should provide [upcoming]= true and [dateTime]
  Future<void> initializePage(int id,
      [bool upcoming = false, DateTime dateTime]) async {
    if (upcoming) {
      dateTime ??= DateTimeFormatter.today;

      List<Task> possibleTopItems = await dbProvider.getTasksOnDate(dateTime);
      _pageModel.putIfAbsent(
          'UPCOMING${dateTime.toHyphenedYYYYMMDD()}',
          () => _PageOrderModel._(
                topItems: _findTopFilteredItems(possibleTopItems, id),
                pageString: 'UPCOMING$id',
                model: this,
              ));
    } else if (id >= 0) {
      List<Task> possibleTopItems = await dbProvider.labelFilteredTasks(id);
      _pageModel.putIfAbsent(
          'LABEL$id',
          () => _PageOrderModel._(
                topItems: _findTopFilteredItems(possibleTopItems, id),
                pageString: 'LABEL$id',
                model: this,
              ));
    } else if (id == -1) {
      List<Task> topTasks = (await dbProvider.todayTasks)[1];

      final topItems = topTasks.map((e) => e.id).toList();
      //today page
      _pageModel.putIfAbsent(
          'TODAY',
          () => _PageOrderModel._(
              deadline: DateTimeFormatter.tomorrow,
              model: this,
              pageString: PAGE_TODAY_STR,
              topItems: topItems));
    }
  }

  /// Inserts a new task into database
  ///
  /// Adds the new task into [_items] as well
  /// Needs to notify model explicitly after invocation
  Future<void> _insertTask(Task task) async {
    needsRebuildUpcomingTasks = true;
    var id = await dbProvider.insertTask(task);
    task.id = id;
    _items[id] = task;
  }

  /// Updates a task
  Future<void> _updateTask(Task task) async {
    await dbProvider.updateTask(task);
    notifyListeners();
  }

  /// Deletes a Task
  Future<void> _deleteTask(int id) async {
    needsRebuildUpcomingTasks = true;
    final task = _items.remove(id);
    if (task.hasParent) _items[task.parentId]?.subTask?.remove(task);

    await dbProvider.deleteTask(id);
    notifyListeners();
  }

  Future<void> _completeTask(int id) async {
    needsRebuildUpcomingTasks = true;
    await dbProvider.completeTask(id);
  }

  _notify() {
    notifyListeners();
  }

  /// Filters out sub-tasks that already have a parent task with given label
  List<int> _findTopFilteredItems(List<Task> possibleTopItems, int labelId) {
    Set<int> top = {}; //top level items
    Set<int> pool = {}; //potential top level items
    //categorization
    for (var task in possibleTopItems) {
      if (!_items[task.id].hasParent)
        top.add(task.id);
      else
        pool.add(task.id);
    }
    // determines top-level items from pool
    for (var id in pool) {
      int parent = _items[id].parentId;
      while (parent != null && !_items[parent].labelIds.contains(labelId)) {
        parent = _items[parent].parentId;
      }
      if (parent == null) top.add(id);
    }

    return top.toList();
  }

  get todayTotalTask =>
      locator<SharedPreferenceProvider>().preferences.getInt(TODAY_TOTAL_TASK);
  get todayTotalCompletedTasks => locator<SharedPreferenceProvider>()
      .preferences
      .getInt(TODAY_COMPLETED_TASK);
}

class _PageOrderModel {
  _PageOrderModel._(
      {List<int> topItems, this.pageString, this.model, this.deadline}) {
    if (_shouldReadFromPreferences()) {
      this.topItems = _fromPreferences();
    } else {
      this.topItems = topItems;
      _saveOrderInPreference();
      if (pageString == PAGE_TODAY_STR) _initializedTotalTasks();
    }
  }

  List<int> topItems;
  final String pageString;
  final TaskModel model;
  final DateTime deadline;

  /// Inserts a new task into database
  insertTask(String description, DateTime deadline,
      [List<int> labelIds,
      int parentId,
      String note = '',
      int posBefore = -1]) async {
    Task task = Task(description,
        labelIds: labelIds, deadline: deadline, note: note, parentId: parentId);
    await model._insertTask(task);

    // whether to display it
    assert(task.isCompleted == false);
    if (task.hasParent)
      model._items[task.parentId].subTask.add(task);
    else if (this.deadline == null ||
        (this.deadline != null && task.deadline <= this.deadline)) {
      if (posBefore != -1)
        topItems.insert(posBefore, task.id);
      else
        topItems.add(task.id);
      if (pageString == PAGE_TODAY_STR) _incTotalTask();
      _saveOrderInPreference();
    }

    model._notify();
  }

  /// Updates a task
  ///
  /// Only descriptive filed can be updated
  Future<void> updateTask(
    int id,
    String description,
    DateTime deadline, [
    List<int> labelIds,
    String note = '',
  ]) async {
    assert(model._items[id] != null);
    assert(model._items[id].id == id);

    final prevDate = model._items[id].deadline;
    final task = model._items[id]
      ..description = description
      ..labelIds = labelIds
      ..deadline = deadline
      ..note = note;

    if (this.deadline != null && deadline > prevDate) if (topItems.remove(id))
      _saveOrderInPreference();

    await model._updateTask(task);
  }

  /// Deletes a Task
  Future<void> deleteTask(int id) async {
    if (topItems.remove(id)) {
      _saveOrderInPreference();
      if (pageString == PAGE_TODAY_STR) _decTotalTask();
    }
    print('delete task id $id');
    await model._deleteTask(id);
  }

  /// Completes a task
  ///
  /// It will display a [SnackBar] that allows user to revoke a completion.
  /// Otherwise after the timeout, the completion will be definitive.
  /// There must be a scaffold in the given [context]
  Future<void> completeTask(BuildContext context, int id) async {
    //complete the task and its sub-tasks
    var parentTaskId = model._items[id].parentId;
    var tempSubTasks = parentTaskId != null
            ? List<Task>.from(model._items[parentTaskId]?.subTask ?? [])
            : [],
        tempTopItemsOrder = List<int>.from(topItems);
    var isAmongTopItems = false;

    if (topItems.contains(id)) {
      topItems.remove(id);
      _saveOrderInPreference();
      isAmongTopItems = true;
      if (pageString == PAGE_TODAY_STR) _incCompletedTask();
    } else
      model._items[parentTaskId].subTask.removeWhere((s) => s.id == id);
    model._notify();

    final scaffold = Scaffold.of(context);
    scaffold
        .showSnackBar(SnackBar(
          content: Text('A task has been completed'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              scaffold.hideCurrentSnackBar();
              print('todo pressed');
            },
          ),
        ))
        .closed
        .then((SnackBarClosedReason reason) async {
      if (reason == SnackBarClosedReason.action) {
        // revoke the operation
        if (isAmongTopItems) {
          topItems = tempTopItemsOrder;
          _saveOrderInPreference();
          if (pageString == PAGE_TODAY_STR) _decCompletedTask();
        } else
          model._items[parentTaskId]?.subTask = tempSubTasks;
        model._notify();
      } else // Proceeds to update database
        await model._completeTask(id);
    });
  }

  /// Obtains a list of tasks
  /// Gets a list of top-level tasks
  List<Task> get tasks {
    return List.generate(topItems.length, (index) {
      return model._items[topItems[index]];
    });
  }

  /// Updates top-level items order
  void updateTaskOrder(int oldIndex, int newIndex) {
    print('$oldIndex ==> $newIndex');
    // if (oldIndex < newIndex) newIndex -= 1;
    final i = topItems.removeAt(oldIndex);
    topItems.insert(newIndex, i);
    _saveOrderInPreference();
    model._notify();
  }

  /// Saves top-items' order in user preferences
  Future<void> _saveOrderInPreference() async {
    final prefs = locator<SharedPreferenceProvider>().preferences;
    prefs.setString(pageString + '_Order', jsonEncode(topItems));
  }

  /// Determines whether should read the value from preferences or use the given
  /// value instead
  bool _shouldReadFromPreferences() {
    final prefs = locator<SharedPreferenceProvider>().preferences;
    final dateStr = prefs.getString(pageString + '_Date');

    return dateStr == DateTimeFormatter.today.toHyphenedYYYYMMDD();
  }

  /// Reads top items from preferences
  List<int> _fromPreferences() {
    final prefs = locator<SharedPreferenceProvider>().preferences;
    final str = prefs.getString(pageString + '_Order');
    return (jsonDecode(str) as List).map((e) => e as int).toList();
  }

  void _incTotalTask() => locator<SharedPreferenceProvider>()
      .preferences
      .increaseInt(TODAY_TOTAL_TASK);

  void _decTotalTask() => locator<SharedPreferenceProvider>()
      .preferences
      .decreaseInt(TODAY_TOTAL_TASK);

  void _incCompletedTask() => locator<SharedPreferenceProvider>()
      .preferences
      .increaseInt(TODAY_COMPLETED_TASK);

  void _decCompletedTask() => locator<SharedPreferenceProvider>()
      .preferences
      .decreaseInt(TODAY_COMPLETED_TASK);

  void _initializedTotalTasks() {
    final prefs = locator<SharedPreferenceProvider>().preferences;
    prefs.setInt(TODAY_COMPLETED_TASK, 0);
    assert(this.topItems != null);
    prefs.setInt(TODAY_TOTAL_TASK, topItems.length);

    prefs.setString(
        pageString + '_Date', DateTimeFormatter.today.toHyphenedYYYYMMDD());
  }
}
