import 'package:circular_check_box/circular_check_box.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskz/custom_widgets/date_button.dart';
import 'package:taskz/model/data/task.dart';
import 'package:taskz/model/label_model.dart';
import 'package:taskz/model/task_model_new.dart';
import 'package:taskz/pages/add_task.dart';
import 'package:taskz/services/locator.dart';
import 'package:taskz/services/time_util.dart';

Future<void> showEditTask(
  BuildContext context,
  Task task,
) {
  final mainContext = context;
  return showModalBottomSheet(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      context: context,
      shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => _EditTaskPage(
            mainContext: mainContext,
            task: task,
          ));
}

class _EditTaskPage extends StatefulWidget {
  _EditTaskPage({this.mainContext, this.task});

  final Task task;
  final BuildContext mainContext;
  @override
  __EditTaskPageState createState() => __EditTaskPageState();
}

class __EditTaskPageState extends State<_EditTaskPage> {
  DateTime _dateTime = DateTimeFormatter.today;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _controllerNote = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.task.description;
    _controllerNote.text = widget.task.note;
  }

  @override
  void dispose() {
    super.dispose();
    _controllerNote.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.only(
            top: 12, bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DraggableScrollableSheet(
          expand: false,
          minChildSize: 0.3,
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            final model = locator<LabelModel>();
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  controller: scrollController,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '> Edit your task',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                        Divider(
                          color: Theme.of(context).colorScheme.secondaryVariant,
                        ),
                        TextFormField(
                          textInputAction: TextInputAction.done,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            hintText: 'tap to edit',
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                          ),
                          controller: _controller,
                          validator: (value) =>
                              value.isEmpty ? 'empty description' : null,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 10,
                              children: [
                                for (final id in widget.task.labelIds)
                                  model.getTagByID(id),
                              ],
                            ),
                            DateButton(
                              initialDateTime: _dateTime,
                              mainContext: widget.mainContext,
                              setTime: (date) => setState(() {
                                if (_dateTime != null) _dateTime = date;
                              }),
                            ),
                          ],
                        ),
                        Divider(
                          color: Theme.of(context).colorScheme.secondaryVariant,
                        ),
                        TextFormField(
                          textInputAction: TextInputAction.done,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          controller: _controllerNote,
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              hintText: 'tap to edit',
                              labelText: 'Description:',
                              labelStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always),
                        ),
                        Divider(
                          color: Theme.of(context).colorScheme.secondaryVariant,
                        ),
                        Text(
                          'Subtasks: ',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          controller: scrollController,
                          itemBuilder: (context, index) {
                            if (index == widget.task.subTask.length)
                              return _AddNewTaskTile(
                                task: widget.task,
                              );
                            else
                              return _SubtaskTile(
                                  task: widget.task.subTask[index]);
                          },
                          itemCount: widget.task.subTask.length + 1,
                        )
                      ],
                    ),
                  ),
                ),
                if (MediaQuery.of(context).viewInsets.bottom == 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: kElevationToShadow[2],
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.delete_forever,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () {
                              Provider.of<TaskModel>(context, listen: false)
                                  .pageId(-1)
                                  .deleteTask(widget.task.id);
                              Navigator.pop(context);
                            },
                          ),
                          FlatButton(
                              child: Text(
                                'UPDATE',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.error),
                              ),
                              onPressed: () {
                                if (formKey.currentState.validate()) {
                                  Provider.of<TaskModel>(context, listen: false)
                                      .pageId(-1)
                                      .updateTask(
                                          widget.task.id,
                                          _controller.text,
                                          _dateTime,
                                          widget.task
                                              .labelIds, //todo add ability to modify labels
                                          _controllerNote.text ?? '');
                                  Navigator.pop(context);
                                }
                              }),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ));
  }
}

class _AddNewTaskTile extends StatelessWidget {
  _AddNewTaskTile({this.task});

  final Task task;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => showAddTaskPanel(context, parentId: task.id),
      leading: Icon(Icons.add),
      title: Text(
        'add new task',
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondaryVariant,
        ),
      ),
    );
  }
}

class _SubtaskTile extends StatefulWidget {
  _SubtaskTile({this.task});

  final Task task;
  @override
  __SubtaskTileState createState() => __SubtaskTileState();
}

class __SubtaskTileState extends State<_SubtaskTile> {
  bool state = false;
  //todo add slide to complete
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircularCheckBox(
        onChanged: (value) => locator,
        value: state,
      ),
      title: Text(widget.task.description,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
          )),
      onTap: () => showEditTask(context, widget.task),
    );
  }
}
