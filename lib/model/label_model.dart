import 'package:flutter/foundation.dart';
import 'package:taskz/custom_widgets/tag.dart';
import 'package:taskz/locator.dart';
import 'package:taskz/model/data/label.dart';

import '../database_provider.dart';
import 'package:taskz/database_provider.dart';

class LabelModel extends ChangeNotifier {
  final DatabaseProvider dbProvider;
  final Map<int,Label> _items;


  LabelModel()
      : _items={},
      dbProvider = locator<DatabaseProvider>() { //service injection
    _initializeLabels();
  }

  Iterable<Label> get labels => _items.values;


  void insertLabel(String description, int colorValue) async{
    var label = Label(description, colorValue: colorValue);
    var id = await dbProvider.insertLabel(label);

    label.id = id;

    _items[id] = label;
    notifyListeners();
  }

  Tag getTagByID(int id) {
    if (_items.isNotEmpty) {
      var label = _items[id];
      return Tag(desc: label.description, color: label.colorValue,);
    } else
      return null;
  }


  //todo implement this method
  void updateByID(int id, String description, int colorValue) async {
    var label = Label(description, id: id, colorValue: colorValue);

    await dbProvider.updateLabel(label);

    _items[id] = label;
    notifyListeners();
  }

  void deleteByID(int id) async {
    await dbProvider.deleteLabel(id);

    _items.remove(id);
    notifyListeners();
  }


  Future<void> _initializeLabels() async {
      final labels = await dbProvider.labels;
      labels.forEach((label) { _items[label.id] = label; });

      notifyListeners();
  }


}