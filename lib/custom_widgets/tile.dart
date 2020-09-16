import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskz/custom_widgets/circular_check_box.dart';
import 'package:taskz/model/label_model.dart';
import 'package:taskz/model/data/task.dart';

import 'package:taskz/model/task_model.dart';
import 'package:taskz/services/locator.dart';

class TaskWidget extends StatelessWidget {
  final Key key;
  final List<TaskWidget> subTasks;
  final Task task;
  final bool isParent;

  TaskWidget(
      {this.key,
      @required this.task,
      @required this.subTasks,
      this.isParent = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
        margin: EdgeInsets.symmetric(
          vertical: 8,
        ),
        shape: isParent
            ? ContinuousRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)))
            : null,
        elevation: isParent ? 4 : 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _TaskContentTile(
                isParent: isParent,
                task: task,
              ),
              if (subTasks.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(left: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: subTasks,
                  ),
                ),
            ],
          ),
        ));
  }
}

class _TaskContentTile extends StatefulWidget {
  final Task task;
  final bool isParent;

  _TaskContentTile({@required this.task, @required this.isParent});

  @override
  _TaskContentTileState createState() => _TaskContentTileState();
}

class _TaskContentTileState extends State<_TaskContentTile> {
  bool state = false;

  @override
  Widget build(BuildContext context) {
    return Ink(
      height: widget.isParent ||
              (widget.task.labelIds != null && widget.task.labelIds.isNotEmpty)
          ? 64
          : 32,
      child: InkWell(
        onTap: _changeState,
        child: Column(
          children: <Widget>[
            Flexible(
                fit: FlexFit.tight,
                flex: 3,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    CircularCheckBox(
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      visualDensity: VisualDensity.compact,
                      onChanged: (newValue) => _changeState(),
                      value: this.state,
                    ),
                    SizedBox(
                      width: 12,
                    ),
                    Text(
                      this.widget.task.description,
                      style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )),
            if (widget.task.labelIds != null && widget.task.labelIds.isNotEmpty)
              Flexible(
                fit: FlexFit.tight,
                flex: 1,
                child: Consumer<LabelModel>(
                  builder: (context, model, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        for (var id in widget.task.labelIds) ...[
                          model.getTagByID(id),
                          SizedBox(width: 12)
                        ]
                      ],
                    );
                  },
                ),
              )
          ],
        ),
      ),
    );
  }

  void _changeState() {
    setState(() {
      //todo invoke task detail page
      this.state = !this.state;
      if (state) {
        Future.delayed(
            Duration(
              milliseconds: 350,
            ),
            () => locator<TaskModel>().completeTask(context, widget.task.id));
      }
    });
  }
}
