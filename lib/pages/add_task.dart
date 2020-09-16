import 'package:flutter/material.dart';
import 'package:taskz/custom_widgets/extended_form_text_field.dart';
import 'package:taskz/custom_widgets/special_text.dart';
import 'package:taskz/model/task_model.dart';
import 'package:taskz/services/locator.dart';

class _AddTask extends StatefulWidget {
  _AddTask();

  @override
  __AddTaskState createState() => __AddTaskState();
}

class __AddTaskState extends State<_AddTask> {
  final _formKey = GlobalKey<FormState>();
  final _textFieldKey = GlobalKey();
  final FocusNode _focusNode = FocusNode()..requestFocus();
  final TextEditingController textController = TextEditingController();

  var _datetime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    var posBefore = (ModalRoute.of(context).settings.arguments ?? -1) as int;
    final builder = MySpecialTextSpanBuilder(
        context, _focusNode, _textFieldKey, textController);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      child: Form(
        key: _formKey,
        onWillPop: () async {
          return await _onWillPop(context, textController).then((value) {
            if (!value) _focusNode.requestFocus();
            return value;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ExtendedTextFormField(
              key: _textFieldKey,
              specialTextSpanBuilder: builder,
              focusNode: _focusNode,
              textInputAction: TextInputAction.send,
              validator: (value) {
                return value.isEmpty ? 'empty string' : null;
              },
              controller: textController,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              decoration: InputDecoration(
                labelText: 'Enter a new task',
              ),
            ),
            SizedBox(
              height: 16,
            ),
            Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.label),
                  onPressed: () =>
                      textController.text = textController.text + '@',
                ),
                IconButton(
                  icon: Icon(Icons.flag),
                ),
                IconButton(
                  icon: Icon(Icons.description),
                ),
                Spacer(
                  flex: 5,
                ),
                //todo extract this as widget
                OutlineButton.icon(
                    onPressed: () {
                      showDatePicker(
                              context: context,
                              initialDate: _datetime,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 366)))
                          .then((value) {
                        setState(() {
                          if (value != null) _datetime = value;
                        });
                      });
                    },
                    icon: Icon(Icons.book),
                    label: Text(_formatDateTime(_datetime))),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (_formKey.currentState.validate()) {
                      String desc = textController.text;
                      var ids = builder.labelIds;
                      locator<TaskModel>()
                          .insertTask(desc, _datetime, ids, null, posBefore);
                      //todo: update UI so user know whether a new task is successfully added
                      _formKey.currentState.reset();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dateTime) {
    return dateTime.day.toString().padLeft(2, '0') +
        [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dic'
        ][dateTime.month - 1];
  }

  Future<bool> _onWillPop(
      BuildContext context, TextEditingController _textController) async {
    if (_textController.text.isNotEmpty) {
      _focusNode.unfocus();
      return await _showAlertDialog(context);
    } else
      return true;
  }
}

Future<bool> _showAlertDialog(BuildContext context) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        content: Text('Do you want to discard the draft??'),
        actions: <Widget>[
          FlatButton(
            child: Text('Yes'),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
          FlatButton(
            child: Text('No'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          )
        ],
      );
    },
  );
}

void showAddTaskPanel(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: ContinuousRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
    builder: (context) => Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _AddTask(),
    ),
  );
}
