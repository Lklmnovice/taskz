import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskz/model/label_model.dart';
import 'package:taskz/custom_widgets/form_add_label.dart' as Form;


class AddLabelPage extends StatefulWidget {
  @override
  _AddLabelPageState createState() => _AddLabelPageState();
}

class _AddLabelPageState extends State<AddLabelPage> {
  final _form = GlobalKey<FormState>();
  TextEditingController _controller;
  Form.ColorWrapper _colorWrapper;

  @override
  void initState() {
    _controller = TextEditingController();
    _colorWrapper = Form.ColorWrapper(color: Form.Colors[4]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Label'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              if (_form.currentState.validate()) {
                Provider.of<LabelModel>(context, listen: false)
                    .insertLabel(_controller.text, Form
                        .colorHexToIntWithHash(_colorWrapper.color));
                Navigator.pop(context);
              }
            },
          )
        ],
      ),
      body: Form.FormAddLabel(
        key: _form,
        colorWrapper: _colorWrapper,
        descCon: _controller,
      )
    );
  }
}

