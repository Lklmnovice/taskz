/// Task data class
///
/// ```sql
/// CREATE TABLE "Task" (
/// "id"	INTEGER PRIMARY KEY AUTOINCREMENT,
/// "description"	TEXT NOT NULL,
/// "deadline"	INTEGER,
/// "isCompleted"	INTEGER NOT NULL DEFAULT 0 CHECK(isCompleted>=0 AND isCompleted<=1),
/// "priority"	INTEGER DEFAULT 1 CHECK(priority>=1 AND priority<=4),
/// "parentTaskId"	INTEGER,
/// FOREIGN KEY("parentTaskId") REFERENCES "Task"("id") ON UPDATE CASCADE ON DELETE CASCADE
/// ```
///
class Task {
  int id;
  String description;
  DateTime deadline;
  bool isCompleted;
  int priority;

  int parentId;

  List<Task> subTask=[];
  List<int> labelIds=[];

  Task(this.description, {
    this.id,
    this.deadline,
    this.isCompleted=false,
    this.priority=1,
    this.subTask,
    this.labelIds,
    this.parentId}) {

    this.subTask ??= [];
    this.labelIds ??= [];
  }

  factory Task.fromData(int id, String description,
      int seconds,
      int isCompleted,
      int priority,
      [List<Task> subTask, List<int> labelIds, parentId]) {

    var task = Task(
      description,
      id: id,
      priority: priority,
      subTask: subTask,
      labelIds: labelIds,
      parentId: parentId,
    ) ..isCompleted1 = isCompleted
      ..deadlineInSeconds = seconds;

    return task;
  }

  void addTask(Task task) {
    this.subTask.add(task);
  }

  void addLabel(int label) {
    this.labelIds.add(label);
  }

  set deadlineInSeconds(int seconds) {
    this.deadline = seconds == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }

  int get deadlineInSeconds {
    return deadline != null ? deadline.millisecondsSinceEpoch ~/ 1000 : null;
  }

  set isCompleted1(int isComplted1) {
    this.isCompleted = isComplted1 == 1;
  }

  @override
  String toString() {
    return 'task{id=$id, description=$description, deadline=$deadline, isCompleted=$isCompleted, '
        'priority=$priority， labels={$labelIds}, subtasks={$subTask}';

  }

  @override
  bool operator ==(dynamic other) {
    return this.id == other.id;
  }

  /// Convert the data to a map
  ///
  /// parentId and labelIds won't be part of the result
  /// thus, they need to be handled separately
  Map<String, dynamic> toMap({bool includeId=true}) {
    Map<String, dynamic> map = {
      if (includeId) 'id' : id,
      'description' : description,
      'deadline' : deadlineInSeconds,
      'isCompleted' : isCompleted==null ? null : (isCompleted ? 1 : 0),
      'parentTaskId' : parentId,
    };

    map.removeWhere((key, value) => value == null);

    return map;
  }


}