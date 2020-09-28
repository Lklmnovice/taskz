import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskz/model/data/label.dart';
import 'package:taskz/model/label_model.dart';

Future<void> showUpdateTag(BuildContext context, [Label label]) {
  return showModalBottomSheet(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      context: context,
      shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.only(
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16),
            child: _AddLabelPage(label: label),
          ));
}

class _AddLabelPage extends StatefulWidget {
  _AddLabelPage({this.label});

  final Label label;
  @override
  _AddLabelPageState createState() => _AddLabelPageState();
}

class _AddLabelPageState extends State<_AddLabelPage> {
  final _form = GlobalKey<FormState>();
  TextEditingController _controller;
  ColorWrapper _colorWrapper;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();

    if (widget.label == null)
      _colorWrapper = ColorWrapper(color: _Colors[4]);
    else {
      _colorWrapper =
          ColorWrapper(color: ('#' + widget.label.colorString).toUpperCase());
      _controller.text = widget.label.description;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label == null ? '> add new tag' : '> edit your tag',
          textAlign: TextAlign.left,
          style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12),
        ),
        Divider(
          color: Theme.of(context).colorScheme.secondaryVariant,
        ),
        FormAddLabel(
          formKey: _form,
          colorWrapper: _colorWrapper,
          descCon: _controller,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            (widget.label == null)
                ? Container()
                : IconButton(
                    icon: Icon(
                      Icons.delete_forever,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () {
                      Provider.of<LabelModel>(context, listen: false)
                          .deleteByID(widget.label.id);
                      Navigator.pop(context);
                    },
                  ),
            FlatButton(
                child: Text(
                  (widget.label == null) ? 'ADD' : 'UPDATE',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error),
                ),
                onPressed: () {
                  if (_form.currentState.validate()) {
                    if (widget.label == null)
                      Provider.of<LabelModel>(context, listen: false)
                          .insertLabel(_controller.text,
                              colorHexToIntWithHash(_colorWrapper.color));
                    else
                      Provider.of<LabelModel>(context, listen: false)
                          .updateByID(widget.label.id, _controller.text,
                              colorHexToIntWithHash(_colorWrapper.color));
                    Navigator.pop(context);
                  }
                }),
          ],
        ),
      ],
    );
  }
}

class FormAddLabel extends StatefulWidget {
  final Key formKey;
  final TextEditingController descCon;
  final ColorWrapper colorWrapper;

  FormAddLabel({this.formKey, this.descCon, this.colorWrapper});

  @override
  _FormAddLabelState createState() => _FormAddLabelState();
}

class _FormAddLabelState extends State<FormAddLabel> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            TextFormField(
              autofocus: true,
              decoration: InputDecoration(
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.secondaryVariant),
                  ),
                  labelText: 'Description:',
                  labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary),
                  floatingLabelBehavior: FloatingLabelBehavior.always),
              controller: widget.descCon,
              validator: (value) => value.isEmpty ? 'empty description' : null,
            ),
            ButtonTheme(
              alignedDropdown: true,
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color:
                              Theme.of(context).colorScheme.secondaryVariant),
                    ),
                    labelText: 'Color:',
                    labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary),
                    floatingLabelBehavior: FloatingLabelBehavior.always),
                value: widget.colorWrapper.color,
                items: [
                  for (final color in _Colors)
                    DropdownMenuItem<String>(
                      value: color,
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.label,
                            color: Color(colorHexToIntWithHash(color)),
                          ),
                          SizedBox(
                            width: 16,
                          ),
                          Text(color)
                        ],
                      ),
                    )
                ],
                validator: (value) {
                  return _Colors.contains(value) ? null : 'not a color';
                },
                isExpanded: true,
                hint: Text('Choose a color'),
                onChanged: (value) {
                  setState(() {
                    widget.colorWrapper.color = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ColorWrapper {
  String color;
  ColorWrapper({this.color});
}

int colorHexToIntWithHash(String color) {
  return int.parse(color.substring(1), radix: 16);
}

const List<String> _Colors = [
  '#FFF44336',
  '#FFFFEBEE',
  '#FFFFCDD2',
  '#FFEF9A9A',
  '#FFE57373',
  '#FFEF5350',
  '#FFE53935',
  '#FFD32F2F',
  '#FFC62828',
  '#FFB71C1C',
  '#FFFF8A80',
  '#FFFF5252',
  '#FFFF1744',
  '#FFD50000',
  '#FFFCE4EC',
  '#FFF8BBD0',
  '#FFF48FB1',
  '#FFF06292',
  '#FFEC407A',
  '#FFE91E63',
  '#FFD81B60',
  '#FFC2185B',
  '#FFAD1457',
  '#FF880E4F',
  '#FFFF80AB',
  '#FFFF4081',
  '#FFF50057',
  '#FFC51162',
  '#FFF3E5F5',
  '#FFE1BEE7',
  '#FFCE93D8',
  '#FFBA68C8',
  '#FFAB47BC',
  '#FF9C27B0',
  '#FF8E24AA',
  '#FF7B1FA2',
  '#FF6A1B9A',
  '#FF4A148C',
  '#FFEA80FC',
  '#FFE040FB',
  '#FFD500F9',
  '#FFAA00FF',
  '#FFEDE7F6',
  '#FFD1C4E9',
  '#FFB39DDB',
  '#FF9575CD',
  '#FF7E57C2',
  '#FF673AB7',
  '#FF5E35B1',
  '#FF512DA8',
  '#FF4527A0',
  '#FF311B92',
  '#FFB388FF',
  '#FF7C4DFF',
  '#FF651FFF',
  '#FF6200EA',
  '#FFE8EAF6',
  '#FFC5CAE9',
  '#FF9FA8DA',
  '#FF7986CB',
  '#FF5C6BC0',
  '#FF3F51B5',
  '#FF3949AB',
  '#FF303F9F',
  '#FF283593',
  '#FF1A237E',
  '#FF8C9EFF',
  '#FF536DFE',
  '#FF3D5AFE',
  '#FF304FFE',
  '#FFE3F2FD',
  '#FFBBDEFB',
  '#FF90CAF9',
  '#FF64B5F6',
  '#FF42A5F5',
  '#FF2196F3',
  '#FF1E88E5',
  '#FF1976D2',
  '#FF1565C0',
  '#FF0D47A1',
  '#FF82B1FF',
  '#FF448AFF',
  '#FF2979FF',
  '#FF2962FF',
  '#FFE1F5FE',
  '#FFB3E5FC',
  '#FF81D4FA',
  '#FF4FC3F7',
  '#FF29B6F6',
  '#FF03A9F4',
  '#FF039BE5',
  '#FF0288D1',
  '#FF0277BD',
  '#FF01579B',
  '#FF80D8FF',
  '#FF40C4FF',
  '#FF00B0FF',
  '#FF0091EA',
  '#FFE0F7FA',
  '#FFB2EBF2',
  '#FF80DEEA',
  '#FF4DD0E1',
  '#FF26C6DA',
  '#FF00BCD4',
  '#FF00ACC1',
  '#FF0097A7',
  '#FF00838F',
  '#FF006064',
  '#FF84FFFF',
  '#FF18FFFF',
  '#FF00E5FF',
  '#FF00B8D4',
  '#FFE0F2F1',
  '#FFB2DFDB',
  '#FF80CBC4',
  '#FF4DB6AC',
  '#FF26A69A',
  '#FF009688',
  '#FF00897B',
  '#FF00796B',
  '#FF00695C',
  '#FF004D40',
  '#FFA7FFEB',
  '#FF64FFDA',
  '#FF1DE9B6',
  '#FF00BFA5',
  '#FFE8F5E9',
  '#FFC8E6C9',
  '#FFA5D6A7',
  '#FF81C784',
  '#FF66BB6A',
  '#FF4CAF50',
  '#FF43A047',
  '#FF388E3C',
  '#FF2E7D32',
  '#FF1B5E20',
  '#FFB9F6CA',
  '#FF69F0AE',
  '#FF00E676',
  '#FF00C853',
  '#FFF1F8E9',
  '#FFDCEDC8',
  '#FFC5E1A5',
  '#FFAED581',
  '#FF9CCC65',
  '#FF8BC34A',
  '#FF7CB342',
  '#FF689F38',
  '#FF558B2F',
  '#FF33691E',
  '#FFCCFF90',
  '#FFB2FF59',
  '#FF76FF03',
  '#FF64DD17',
  '#FFF9FBE7',
  '#FFF0F4C3',
  '#FFE6EE9C',
  '#FFDCE775',
  '#FFD4E157',
  '#FFCDDC39',
  '#FFC0CA33',
  '#FFAFB42B',
  '#FF9E9D24',
  '#FF827717',
  '#FFF4FF81',
  '#FFEEFF41',
  '#FFC6FF00',
  '#FFAEEA00',
  '#FFFFFDE7',
  '#FFFFF9C4',
  '#FFFFF59D',
  '#FFFFF176',
  '#FFFFEE58',
  '#FFFFEB3B',
  '#FFFDD835',
  '#FFFBC02D',
  '#FFF9A825',
  '#FFF57F17',
  '#FFFFFF8D',
  '#FFFFFF00',
  '#FFFFEA00',
  '#FFFFD600',
  '#FFFFF8E1',
  '#FFFFECB3',
  '#FFFFE082',
  '#FFFFD54F',
  '#FFFFCA28',
  '#FFFFC107',
  '#FFFFB300',
  '#FFFFA000',
  '#FFFF8F00',
  '#FFFF6F00',
  '#FFFFE57F',
  '#FFFFD740',
  '#FFFFC400',
  '#FFFFAB00',
  '#FFFFF3E0',
  '#FFFFE0B2',
  '#FFFFCC80',
  '#FFFFB74D',
  '#FFFFA726',
  '#FFFF9800',
  '#FFFB8C00',
  '#FFF57C00',
  '#FFEF6C00',
  '#FFE65100',
  '#FFFFD180',
  '#FFFFAB40',
  '#FFFF9100',
  '#FFFF6D00',
  '#FFFBE9E7',
  '#FFFFCCBC',
  '#FFFFAB91',
  '#FFFF8A65',
  '#FFFF7043',
  '#FFFF5722',
  '#FFF4511E',
  '#FFE64A19',
  '#FFD84315',
  '#FFBF360C',
  '#FFFF9E80',
  '#FFFF6E40',
  '#FFFF3D00',
  '#FFDD2C00',
  '#FFEFEBE9',
  '#FFD7CCC8',
  '#FFBCAAA4',
  '#FFA1887F',
  '#FF8D6E63',
  '#FF795548',
  '#FF6D4C41',
  '#FF5D4037',
  '#FF4E342E',
  '#FF3E2723',
  '#FFFAFAFA',
  '#FFF5F5F5',
  '#FFEEEEEE',
  '#FFE0E0E0',
  '#FFBDBDBD',
  '#FF9E9E9E',
  '#FF757575',
  '#FF616161',
  '#FF424242',
  '#FF212121',
  '#FFECEFF1',
  '#FFCFD8DC',
  '#FFB0BEC5',
  '#FF90A4AE',
  '#FF78909C',
  '#FF607D8B',
  '#FF546E7A',
  '#FF455A64',
  '#FF37474F',
  '#FF263238',
  '#FF000000',
];
