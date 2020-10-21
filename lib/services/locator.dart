import 'package:get_it/get_it.dart';
import 'package:taskz/model/label_model.dart';
import 'package:taskz/model/task_model_new.dart';
import 'package:taskz/services/database_provider.dart';
import 'package:taskz/services/shared_preferences.dart';

final locator = GetIt.I;

void setup() {
  locator.registerSingletonAsync<SharedPreferenceProvider>(() async {
    return await SharedPreferenceProvider.getInstance();
  });

  locator.registerSingletonAsync<DatabaseProvider>(() async {
    final dbProvider = DatabaseProvider();
    await dbProvider.init();

    return dbProvider;
  });

  locator.registerSingletonAsync<LabelModel>(() async {
    final model = LabelModel();
    await model.initialize();
    return model;
  }, dependsOn: [DatabaseProvider]);

  locator.registerSingletonAsync<TaskModel>(() async {
    return await TaskModel.initialize();
  }, dependsOn: [DatabaseProvider, LabelModel, SharedPreferenceProvider]);
}
