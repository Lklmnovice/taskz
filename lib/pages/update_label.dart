import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskz/model/data/label.dart';
import 'package:taskz/model/label_model.dart';
import 'package:taskz/custom_widgets/form_add_label.dart' as Form;


class UpdateLabelPage extends StatefulWidget {
  @override
  _UpdateLabelPageState createState() => _UpdateLabelPageState();
}

class _UpdateLabelPageState extends State<UpdateLabelPage> {
  final _form = GlobalKey<FormState>();
  TextEditingController _controller;
  Form.ColorWrapper _colorWrapper;

  @override
  void initState() {
    _controller = TextEditingController();
    _colorWrapper = Form.ColorWrapper(color: Form.Colors[4]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Label label = ModalRoute.of(context).settings.arguments;
    _controller.text = label.description;
    _colorWrapper.color = ('#' + label.colorString).toUpperCase();

    return Scaffold(
        appBar: AppBar(
          title: Text('Update Label'),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                Provider.of<LabelModel>(context, listen: false)
                    .deleteByID(label.id);
                Navigator.pop(context);
              },
            ),
            IconButton(
              icon: Icon(Icons.sync),
              onPressed: () {
                if (_form.currentState.validate()) {
                  Provider.of<LabelModel>(context, listen: false)
                      .updateByID(label.id, _controller.text,
                      Form.colorHexToIntWithHash(_colorWrapper.color));
                  Navigator.pop(context);
                }
              },
            ),
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

