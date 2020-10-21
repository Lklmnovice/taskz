import 'package:flutter/material.dart';
import 'package:taskz/pages/add_task.dart';
import 'package:taskz/custom_widgets/custom_reorderable_sliver_list.dart'
    as Custom;

class CustomFAB extends StatelessWidget {
  CustomFAB({this.dfabKey});

  final dfabKey;

  @override
  Widget build(BuildContext context) {
    return Custom.DraggableFloatingActionButton(
      key: dfabKey,
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Navigator.of(context).pushNamed('/add_task');
            showAddTaskPanel(context);
          },
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.secondary,
          child: Icon(Icons.add)),
    );
  }
}
