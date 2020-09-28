import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:taskz/model/data/label.dart';
import 'package:taskz/model/data/task.dart';
import 'time_util.dart';

/// A non-extendable and non-instantiable helper class that provides utility to
/// interact with SQLite
class DatabaseProvider {
  Database _db;
  static final _dbName = 'playground1.db';

  /// must be called right after getting new instance
  Future<void> init() async => await this.database;

  /// Get an instance of Database
  ///
  /// There will be only a single instance of database throughout the lifecycle
  /// of the application.
  /// If the instance of database is not created yet and the database is not even
  /// present in the path, a preloaded database will be duplicated.
  Future<Database> get database async {
    if (_db != null) return _db;

    var path = join(await getDatabasesPath(), _dbName);
    var exists = await databaseExists(path);

    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {} //todo add error page

      // Copy from asset
      ByteData data = await rootBundle.load(join("assets", "task.db"));
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      // Write and flush the bytes written
      await File(path).writeAsBytes(bytes, flush: true);
    }

    _db = await openDatabase(
      join(await getDatabasesPath(), _dbName),
      version: 3,
      onConfigure: (db) async {
        await db.execute("PRAGMA foreign_keys = ON");
      },
      onUpgrade: _upgrade,
    );
    return _db;
  }

  //Updating database schema to enable subtasks reordering
  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    //upgrade versions
    if (oldVersion < newVersion) {
      try {
        if (oldVersion < 2)
          db.execute('ALTER TABLE `Task` ADD `${Task.cIndex}` int');
        if (oldVersion < 3)
          db.execute('ALTER TABLE `Task` ADD `${Task.cNote}` TEXT');
      } on DatabaseException catch (e) {
        print('Error during update database' + e.toString());
        //exit program
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      }
    }
  }

  /// Get tags from database
  ///
  /// After getting the instance of [database], it queries all the tags.
  Future<List<Label>> get labels async {
    final Database db = await database;

    final List<Map<String, dynamic>> results = await db.query('Tag');
    return List.generate(
        results.length,
        (i) => Label.fromData(
              results[i][Label.cId],
              results[i][Label.cDescription],
              results[i][Label.cColor],
            ));
  }

  /// Inserts a new label
  Future<int> insertLabel(Label label) async {
    final Database db = await database;

    return await db.insert(Label.TABLE, label.toMap(includeId: false),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Updates a label
  Future<void> updateLabel(Label label) async {
    final Database db = await database;

    var map = label.toMap(includeId: false);
    await db.update(Label.TABLE, map, where: 'id = ?', whereArgs: [label.id]);
  }

  /// Delets a label
  Future<void> deleteLabel(int id) async {
    final Database db = await database;

    await db.delete(Label.TABLE, where: 'id = ?', whereArgs: [id]);
  }

  /// Get today's tasks from database
  ///
  /// Only unfinished tasks before 12 o'clock pm will be returned.
  /// It returns a 2-item list
  /// [
  ///   everySingleTask:     Map<int, Task>,
  ///   topLevelTasks:       List<Task>
  /// ]
  Future<List<dynamic>> get todayTasks async {
    final Database db = await database;

    final List<Map<String, dynamic>> results = await db.rawQuery('''
SELECT k.${Task.cId} AS id, k.${Task.cDescription}, k.${Task.cDeadline}, k.${Task.cIsCompleted}, k.${Task.cPriority}, k.${Task.cParentTaskId}, g.id AS tagId, k.${Task.cNote}
FROM Task k 
	LEFT JOIN TagTask tk ON k.id = tk.taskId 
	LEFT JOIN Tag g ON g.id = tk.tagId
WHERE isCompleted = 0
	AND (deadline IS NULL OR 
		(deadline >= strftime('%s', 'now','localtime',  'start of day')
			AND deadline < strftime('%s', 'now', 'localtime', '+1 day', 'start of day'))
		);
  ''');
    return _parseTasks(results);
  }

  /// inserts a task into database
  ///
  /// First inserts the task
  /// Then inserts labels
  /// It wont updates id of original Task
  Future<int> insertTask(Task task) async {
    final Database db = await database;
    var map = task.toMap(includeId: false);
    // if (parentTaskId != null) map['parentTaskId'] = parentTaskId;

    int id;
    await db.transaction((txn) async {
      id = await txn.insert(Task.TABLE, map,
          conflictAlgorithm: ConflictAlgorithm.replace);

      final batch = txn.batch();
      task.labelIds.forEach((labelId) {
        batch.insert('TagTask', {'tagId': labelId, 'taskId': id},
            conflictAlgorithm: ConflictAlgorithm.replace);
      });
      batch.commit();
    });

    return id;
  }

  /// Updates a task
  Future<void> updateTask(Task task) async {
    final Database db = await database;

    await db.update(Task.TABLE, task.toMap(includeId: false),
        where: 'id = ?', whereArgs: [task.id]);
  }

  /// Deletes a task by id
  Future<void> deleteTask(int id) async {
    final Database db = await database;

    await db.delete(Task.TABLE, where: 'id = ?', whereArgs: [id]);
  }

  /// Get every uncompleted tasks from today
  ///
  /// Returns a Map
  /// {
  /// String: dateTime.toHyphenedYYYYMMDD
  /// List<Task>: tasks in that given date
  /// }
  Future<Map<String, List<Task>>> get upcomingTasks async {
    final Database db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
SELECT k.id AS id, k.description, k.deadline, k.isCompleted, k.priority, k.parentTaskId, g.id AS tagId
FROM Task k 
	LEFT JOIN TagTask tk ON k.id = tk.taskId 
	LEFT JOIN Tag g ON g.id = tk.tagId
WHERE isCompleted = 0
	AND (deadline >= strftime('%s', 'now','localtime',  'start of day')
		);
  ''');
    final Map<int, Task> map = _parseTasks(results)[0]; //get every single tasks
    final Map<String, List<Task>> ret = {};
    map.forEach((_, task) {
      if (task.deadline != null)
        ret.update(
            task.deadline.toHyphenedYYYYMMDD(), (list) => list..add(task),
            ifAbsent: () => [task]);
    });

    return ret;
  }

  /// Completes a task by id
  ///
  /// If a parent task gets completed, all its child tasks are getting completed
  /// as well
  Future<void> completeTask(int id) async {
    final Database db = await database;
    db.rawUpdate('''
      UPDATE `Task` 
      set `isCompleted` = 1 
      where `parentTaskId` = ? OR `id` = ?;
    ''', [id, id]);
  }

  /// Parses data queried to Task
  ///
  /// Returns two objects
  /// 1: a map that contains every single task
  /// 2: a list that contains top-level tasks
  List<dynamic> _parseTasks(final List<Map<String, dynamic>> results) {
    Map<int, Task> map = {};
    Set<Task> topLevelTasks = {};

    for (var row in results) {
      Task newTask;
      //initialize task in map
      if (!map.containsKey(row['id'])) {
        newTask = Task.fromData(
            row['id'],
            row['description'],
            row['deadline'],
            row['isCompleted'],
            row['priority'],
            row['note'],
            [],
            [],
            row['parentTaskId']);
        map[row['id']] = newTask;
      } else {
        // a duplicate row found that might not be initialized yet
        map[row['id']]
          ..description = row['description']
          ..deadlineInSeconds = row['deadline']
          ..isCompleted1 = row['isCompleted']
          ..priority = row['priority']
          ..parentId = row['parentTaskId']
          ..note = row['note']
          ..addLabel(row['tagId']);
        newTask = map[row['id']];
      }
      //add to its parent
      if (row['parentTaskId'] != null) {
        if (!map.containsKey(row[
            'parentTaskId'])) //creates a temporary placeholder not initialized
          map[row['parentTaskId']] = Task(
            null,
            id: row['parentTaskId'],
            deadline: null,
            subTask: [newTask],
          );
        else
          map[row['parentTaskId']].addTask(newTask);
      } else
        topLevelTasks.add(newTask);
    }
    //Add task into topLevelTasks if its parentTask is not included in today's tasks
    map.forEach(
        (id, task) => task.description ?? topLevelTasks.addAll(task.subTask));
    map.removeWhere((id, task) => task.description == null);
    return [map, topLevelTasks.toList()];
  }
}
