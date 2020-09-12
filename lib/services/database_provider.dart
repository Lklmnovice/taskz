import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:taskz/model/data/label.dart';
import 'package:taskz/model/data/task.dart';

//todo beautify this class
/// A non-extendable and non-instantiable helper class that provides utility to
/// interact with SQLite
class DatabaseProvider {
  Database _db;

  /// must be called right after getting new instance
  Future<void> init() async {
    print('init called()');
    await this.database;
  }

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
      } catch (_) {}

      // Copy from asset
      ByteData data = await rootBundle.load(join("assets", "task.db"));
      List<int> bytes =
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      // Write and flush the bytes written
      await File(path).writeAsBytes(bytes, flush: true);
    }

    _db = await openDatabase(
      join(await getDatabasesPath(), _dbName),
      version: 2,
      onConfigure: (db) async { await db.execute("PRAGMA foreign_keys = ON"); },
      onUpgrade: _upgrade,
    );
    return _db;
  }

  //Updating database schema to enable subtasks reordering
  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    //upgrade version 2
    //add index column to task table
    if (oldVersion < newVersion) {
      try {
        db.execute('ALTER TABLE `Task` ADD `index` int');
      } on DatabaseException catch(e) {
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

    return List.generate(results.length, (i) =>
        Label.fromData(
          results[i]['id'],
          results[i]['description'],
          results[i]['color'],
        ));
  }

  Future<int> insertLabel(Label label) async {
    final Database db = await database;

    return await db.insert('Tag', label.toMap(includeId: false), conflictAlgorithm: ConflictAlgorithm.replace);
  }


  Future<void> updateLabel(Label label) async {
    final Database db = await database;
    var map = label.toMap(includeId: false);
    await db.update('Tag', map, where: 'id = ?', whereArgs: [label.id]);
  }

  Future<void> deleteLabel(int id) async {
    final Database db = await database;

    await db.delete('Tag', where: 'id = ?', whereArgs: [id]);
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

    final List<Map<String, dynamic>> results = await db.rawQuery(_todayTaskSQL);

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
            [],
            [],
            row['parentTaskId']
        );
        map[ row['id'] ] = newTask;
      } else {
        map[ row['id'] ]
          ..description = row['description']
          ..deadlineInSeconds = row['deadline']
          ..isCompleted1 = row['isCompleted']
          ..priority = row['priority']
          ..parentId = row['parentTaskId']
          ..addLabel(row['tagId']);
        newTask = map[ row['id'] ];
      }
      //add to its parent
      if (row['parentTaskId'] != null) {
        if (!map.containsKey(row['parentTaskId'])) //creates a temporary placeholder
          map[ row['parentTaskId'] ] = Task(null, id: row['parentTaskId'], deadline: null, subTask: [newTask],);
        else
          map[ row['parentTaskId'] ].addTask(newTask);
      } else
        topLevelTasks.add(newTask);
    }
    //Adds topLevelTasks if its parentTask is not included in today's tasks
    map.forEach((id, task) => task.description ?? topLevelTasks.addAll(task.subTask));
    map.removeWhere((id, task) => task.description == null);
    return [map, topLevelTasks.toList()];
  }

  /// inserts a task into database
  ///
  /// First inserts the task
  /// Then inserts labels
  Future<int> insertTask(Task task, int parentTaskId) async {
    final Database db = await database;
    var map = task.toMap(includeId: false);
    if (parentTaskId != null)
      map['parentTaskId'] = parentTaskId;

    int id;
    await db.transaction((txn) async {
      id = await txn.insert('Task', map, conflictAlgorithm: ConflictAlgorithm.replace);

      final batch = txn.batch();
      task.labelIds.forEach((labelId) {
        batch.insert(
            'TagTask',
            {
              'tagId' : labelId,
              'taskId' : task.id
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
      });
      batch.commit();
    });

    return id;
  }

  // todo rebuild this function
  Future<void> updateTask(Task task) async {
    final Database db = await database;
    await db.update(
        'Task',
        task.toMap(includeId: false),
        where: 'id = ?',
        whereArgs: [task.id]
    );
  }

 Future<void> deleteTask(int id) async {
    final Database db = await database;

    await db.delete('Task', where: 'id = ?', whereArgs: [id]);
 }


  static final _dbName = 'playground1.db';

  static final _todayTaskSQL = '''
SELECT k.id AS id, k.description, k.deadline, k.isCompleted, k.priority, k.parentTaskId, g.id AS tagId
FROM Task k 
	LEFT JOIN TagTask tk ON k.id = tk.taskId 
	LEFT JOIN Tag g ON g.id = tk.tagId
WHERE isCompleted = 0
	AND (deadline IS NULL OR 
		(deadline >= strftime('%s', 'now','localtime',  'start of day')
			AND deadline < strftime('%s', 'now', 'localtime', '+1 day', 'start of day'))
		);
  ''';

  Future<void> completeTask(int id) async {
    final Database db = await database;
    db.rawUpdate('''
      UPDATE `Task` 
      set `isCompleted` = 1 
      where `parentTaskId` = ? OR `id` = ?;
    ''',
      [id, id]
    );
  }
}