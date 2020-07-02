import 'package:get_it/get_it.dart';
import 'package:taskz/model/label_model.dart';
import 'package:taskz/model/task_model.dart';

import 'database_provider.dart';

final locator = GetIt.I;

void setup() {
  locator.registerSingletonAsync<DatabaseProvider>(() async {
    final dbProvider = DatabaseProvider();
    await dbProvider.init();
    return dbProvider;
  });

  locator.registerSingletonWithDependencies<LabelModel>(() => LabelModel(),
      dependsOn: [DatabaseProvider]);

  locator.registerSingletonWithDependencies<TaskModel>(() => TaskModel(),
      dependsOn: [DatabaseProvider, LabelModel]);

}