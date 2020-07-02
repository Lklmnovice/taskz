
import 'package:flutter/material.dart';
import 'package:taskz/custom_widgets/extended_form_text_field.dart';
import 'package:taskz/custom_widgets/special_text.dart';
import 'package:taskz/locator.dart';
import 'package:taskz/model/task_model.dart';

class AddTaskPage extends StatefulWidget {
  @override
  _AddTaskPageState createState() => _AddTaskPageState();

  static const _months = [
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
  ];
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TextEditingController controller = TextEditingController();


  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onWillPop(context, controller).then<void>((value) {
        if (value) {
          Navigator.of(context).pop(true);
        };
      }),
      child: Scaffold(
        backgroundColor: Colors.grey[600].withOpacity(0.8),
        body: Stack(
          children: <Widget>[
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _AddTask(textController: controller),
            ),
          ],
        ),
      ),
    );
  }
}



class _AddTask extends StatefulWidget {
  final TextEditingController textController;

  _AddTask({this.textController});

  @override
  __AddTaskState createState() => __AddTaskState();
}

class __AddTaskState extends State<_AddTask> {
  final _formKey = GlobalKey<FormState>();
  final _textFieldKey = GlobalKey();
  final FocusNode _focusNode = FocusNode();

  var _datetime = DateTime.now();



  @override
  Widget build(BuildContext context) {
    final builder = MySpecialTextSpanBuilder(
        context,
        _focusNode,
        _textFieldKey,
        widget.textController..clear());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      child: Form(
        key: _formKey,
        onWillPop: () async {
          return await _onWillPop(context, widget.textController);
        },
        child: IntrinsicHeight(
          child: Column(
            children: <Widget>[
              ExtendedTextFormField(
                key: _textFieldKey,
                specialTextSpanBuilder: builder,
                focusNode: _focusNode..requestFocus(),
                textInputAction: TextInputAction.send,
                validator: (value) {
                  return value.isEmpty ? 'empty string' : null;
                },
                controller: widget.textController,
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
                      widget.textController.text = widget.textController.text + '@',
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
                            lastDate: DateTime.now().add(Duration(days: 366))
                        ).then((value) {
                          setState(() {
                            if (value != null)
                              _datetime = value;
                          });
                        });
                      },
                      icon: Icon(Icons.book),
                      label: Text(_formatDateTime(_datetime))),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        String desc = widget.textController.text;
                        var ids = builder.labelIds;

                        locator<TaskModel>().insertTask(desc, _datetime, ids, null);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dateTime) {
    return dateTime.day.toString().padLeft(2, '0') +
        AddTaskPage._months[dateTime.month - 1];
  }

}


Future<bool> _onWillPop(BuildContext context, TextEditingController _textController) async {
  if (_textController.text.isNotEmpty)
    return await _showAlertDialog(context);
  else
    return true;
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
