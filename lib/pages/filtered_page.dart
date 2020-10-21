import 'package:flutter/material.dart';
import 'package:taskz/custom_widgets/custom_appBar_FAB.dart';
import 'package:taskz/custom_widgets/label_tile.dart';
import 'package:taskz/custom_widgets/task_widgets.dart';
import 'package:taskz/model/data/label.dart';
import 'package:taskz/model/task_model_new.dart';
import 'package:taskz/services/locator.dart';
import 'package:taskz/custom_widgets/custom_reorderable_sliver_list.dart'
    as Custom;

class FilteredPage extends StatefulWidget {
  FilteredPage({this.settings});

  static const pageRoute = '/filtered_page';
  final RouteSettings settings;
  @override
  _FilteredPageState createState() => _FilteredPageState();
}

class _FilteredPageState extends State<FilteredPage> {
  Future<void> isReady;
  Label label;

  final _dfabKey = GlobalKey<Custom.DraggableFloatingActionButtonState>();

  @override
  void initState() {
    label = widget.settings.arguments as Label;
    isReady = locator<TaskModel>().initializePage(label.id).then((value) => 1);
    // isReady.whenComplete(() => print('data is ready'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: CustomFAB(
        dfabKey: _dfabKey,
      ),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.secondary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: LabelTile(
          label: label,
          textColor: Theme.of(context).colorScheme.secondary,
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(6))),
      ),
      body: CustomScrollView(
        slivers: [
          TaskList(
              fabKey: _dfabKey,
              getSubModel: () =>
                  locator<TaskModel>().pageId(label.id, m: Model.FILTERED),
              isReady: isReady)
        ],
      ),
    );
  }
}
