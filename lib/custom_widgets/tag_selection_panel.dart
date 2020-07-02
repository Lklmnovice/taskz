import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskz/model/data/label.dart';
import 'package:taskz/model/label_model.dart';

import 'label_tile.dart';

const kMaxPanelWidth = 160.0;
const kMaxPanelHeight = 180.0;


typedef CustomCallBack = void Function(String label, int atPositon);

Future<String> showTagsSelectionPanel({
    ValueNotifier<String> notifier,
    BuildContext context,
    String fullText,
    GlobalKey key,
    FocusNode node}) {

  return Navigator.of(context,).push(_PopupSelectionRoute<String>(
    fullText: fullText,
    key: key,
    node: node,
    valueNotifier: notifier
  ));
}

class _PopupSelectionRoute<T> extends TransitionRoute<T>{


  //from _PopupMenuRoute in [showMenu]
  _PopupSelectionRoute({
    this.key,
    this.node,
    this.fullText,
    this.valueNotifier,
  });

  final GlobalKey key;
  final FocusNode node;
  final String fullText;
  final ValueNotifier<String> valueNotifier;

  @override
  Animation<double> createAnimation() {
    return CurvedAnimation(
      parent: super.createAnimation(),
      curve: Curves.linear,
      reverseCurve: const Interval(0.0, 2.0 / 3.0),
    );
  }


  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => Duration(milliseconds: 300);


  @override
  Iterable<OverlayEntry> createOverlayEntries() sync* {
    yield OverlayEntry(
      opaque: false,
      maintainState: true,
      builder: buildPage,
    );
  }

  Widget buildPage(BuildContext context) {

    TextPainter painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        style: TextStyle(fontSize: 16),
        text: fullText,
      ),
    );
//    var box = key.currentContext.findRenderObject() as RenderBox;
//    double width = box.size.width - 2;
    double width = node.size.width - 2;
//    double width = 381.42857142857144 - 2;

    painter.layout(maxWidth: width);
    var lines = painter.computeLineMetrics();
    var cursorPosition = lines.last.width;
    var _offsetDy =  node.size.height + node.offset.dy;
    var _offsetDx = node.offset.dx;
    var left =_offsetDx + cursorPosition + 10;

    //todo add restrictions
//    node.offset.dy - 40 + node.size.height
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
            children: <Widget>[
        Positioned(
        // Decides where to place the tag on the screen.
          bottom: constraints.maxHeight - _offsetDy + 40,
          left: (left < constraints.maxWidth - kMaxPanelWidth)
              ? left
              : constraints.maxWidth - kMaxPanelWidth,
          // Tag code.
          child: SelectionPanel(notifier: valueNotifier),
        ),
            ]
        );
      },
    );

  }


}



/// Displays a label selection panel
///
/// When user try to insert a label to a task, he can
/// start by inserting an 'at' sign or by tapping on
/// the label button, either way this panel should pop up,
/// allowing user to select from the available labels
class SelectionPanel extends StatefulWidget {
  final ValueNotifier<String> notifier;

  SelectionPanel({this.notifier});

  @override
  _SelectionPanelState createState() => _SelectionPanelState();
}

class _SelectionPanelState extends State<SelectionPanel> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return ValueListenableBuilder(
      valueListenable: widget.notifier,
      builder: (context, text, _) {
        final model = Provider.of<LabelModel>(context, listen: false);
        final labels = _fetchMatchingLabels(model, text);

        final addNewLabelTile = ListTile(
            title: Text('Insert a new Label'),
            leading: Icon(Icons.add),
            onTap: () {
              model.insertLabel(text, Label.kDefaultColorValue);

              Navigator.of(context,).pop(text);
            });

        return Material(
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: kElevationToShadow[3],
                borderRadius: BorderRadius.all(Radius.circular(6))
            ),
            constraints: BoxConstraints(
              minWidth: kMaxPanelWidth,
              maxWidth: kMaxPanelWidth,
              maxHeight: kMaxPanelHeight,
              minHeight: 0
            ),
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  for (var label in labels)
                    LabelTile(
                        label: label,
                        onTap: () =>
                            Navigator.of(context,).pop(label.description)
                    ),
                  addNewLabelTile,
                ],
              ),
            ),
          ),
        );
      }
    );
  }
  
  //todo refactor the speacial text builder function
  /// Finds labels that match user input
  /// or otherwise return an empty iterable
  Iterable<Label> _fetchMatchingLabels(LabelModel model, String text) {
    if (text.isEmpty)
      return model.labels;
    return model.labels.where((label) =>
        label.description.toLowerCase().startsWith(text.toLowerCase()));
  }



}


