import 'package:flutter/foundation.dart';
import 'package:taskz/custom_widgets/tag.dart';
import 'package:taskz/model/data/label.dart';
import 'package:taskz/services/database_provider.dart';
import 'package:taskz/services/locator.dart';



class LabelModel extends ChangeNotifier {
  LabelModel()
      : _items={},
        dbProvider = locator<DatabaseProvider>();


  final DatabaseProvider dbProvider;
  final Map<int,Label> _items;





  Iterable<Label> get labels => _items.values;

  void insertLabel(String description, int colorValue) async {
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

  /// Retrieves data from database
  /// Reserved to [locator]
  Future<void> initialize() async {
      final labels = await dbProvider.labels;
      labels.forEach((label) { _items[label.id] = label; });
      notifyListeners();
  }


}