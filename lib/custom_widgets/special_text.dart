import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskz/custom_widgets/tag_selection_panel.dart';
import 'package:taskz/locator.dart';
import 'package:taskz/model/label_model.dart';

abstract class CustomSpecialText extends SpecialText {
  final int start;

  CustomSpecialText(
      String startFlag,
      String endFlag,
      this.start,
      TextStyle textStyle,
      { SpecialTextGestureTapCallback onTap})
  : super(startFlag, endFlag, textStyle, onTap:onTap);

  bool isValidText();

  get content => super.getContent();
}


class TaggedText extends CustomSpecialText {
  static const String flag = "@";
  int labelId = -1;

  TaggedText({
    int start,
    TextStyle textStyle,
    SpecialTextGestureTapCallback onTap
  }): super(flag, ' ', start, textStyle, onTap: onTap);


  @override
  InlineSpan finishText() {
    final String content = this.toString();
    return BackgroundTextSpan(
        background: Paint()..color = Colors.blue.withOpacity(0.15),
        text: content,
        actualText: content,
        start: start,

        ///caret can move into special text
        deleteAll: true,
        style: textStyle,
        recognizer: (TapGestureRecognizer()
          ..onTap = () {
            if (onTap != null) onTap(content);
          }));
  }

  @override
  bool isValidText() {
    //description is unique
    final list = locator<LabelModel>().labels
      .where((e) => e.description == content)
      .toList(growable: false);

    if (list.isEmpty)
      return false;
    else {
      labelId = list[0].id;
      return true;
    }
  }


}


class MySpecialTextSpanBuilder extends SpecialTextSpanBuilder {
  /// whether show background for @somebody
  BuildContext _context;
  bool _isPanelOn;

  final FocusNode focusNode;
  final GlobalKey textFieldKey;
  final ValueNotifier<String> _notifier;
  final TextEditingController controller;

  MySpecialTextSpanBuilder(this._context, this.focusNode, this.textFieldKey, this.controller)
  : _notifier = ValueNotifier<String>(''),
    _isPanelOn = false;



  @override
  TextSpan build(String data, {TextStyle textStyle, onTap}) {
    if (data == null || data == '') {
      maybePopSelectionPanel();
      return null;
    }


    final List<InlineSpan> inlineList = <InlineSpan>[];
    if (data.isNotEmpty) {
      CustomSpecialText specialText;
      String textBuffer = '';
      //String text
      for (int i = 0; i < data.length; i++) {
        final String char = data[i];
        textBuffer += char;

        if (specialText != null) {
          if (!specialText.isEnd(textBuffer)) {
            specialText.appendContent(char);
          } else { //possible specialtext is ready
            if (specialText.isValidText()) {
              inlineList.add(specialText.finishText());
              textBuffer = '';
            } else
              textBuffer = specialText.toString();

            specialText = null;
          }
        } else {
          specialText = createSpecialText(textBuffer,
              textStyle: textStyle, onTap: onTap, index: i);
          if (specialText != null) {
            if (textBuffer.length - specialText.startFlag.length >= 0) {
              textBuffer = textBuffer.substring(
                  0, textBuffer.length - specialText.startFlag.length);
              if (textBuffer.isNotEmpty) {
                inlineList.add(TextSpan(text: textBuffer, style: textStyle));
              }
            }
            textBuffer = '';
          }
        }
      }

      if (specialText != null) {
        //there can only be one selection panel at time
        if (!_isPanelOn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            print('pushed');
            showTagsSelectionPanel(
                node: focusNode,
                key: textFieldKey,
                fullText: data,
                context: _context,
                notifier: _notifier..value = specialText.content
            ).then((String label) {
              if (label != null) {
                print('do some work');
                var str = data.substring(0, (specialText as TaggedText).start + 1)
                    + label + ' ';
                controller.text = str;
                controller.selection = TextSelection.collapsed(offset: str.length);
              } else
                print('null detected');
            });
            _isPanelOn = true;
          });
        } else { //otherwise, we update the value
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _notifier.value = specialText.content;
          });
        }
        inlineList.add(TextSpan(
            text: specialText.startFlag + specialText.content,
            style: textStyle));
      } else {
        if (textBuffer.isNotEmpty) {
          inlineList.add(TextSpan(text: textBuffer, style: textStyle));
        }
        maybePopSelectionPanel();
      }
    } else {//data is empty
      maybePopSelectionPanel();
      inlineList.add(TextSpan(text: data, style: textStyle));
    }

    return TextSpan(children: inlineList, style: textStyle);
  }


  List<int> get labelIds {
    final text = controller.text;

    TextSpan span = build(text);
    return span.children
        .where((sp) => sp is TaggedText)
        .map((e) => (e as TaggedText).labelId)
        .toList();
  }

  @override
  SpecialText createSpecialText(String textBuffer,
      {TextStyle textStyle, SpecialTextGestureTapCallback onTap, int index}) {
    if (textBuffer == null || textBuffer == "") return null;

    ///index is end index of start flag, so text start index should be index-(flag.length-1)
    if (isStart(textBuffer, TaggedText.flag)) {
      return TaggedText(
          textStyle: textStyle,
          onTap:  onTap,
          start: index - (TaggedText.flag.length - 1));
    }
    return null;
  }

  maybePopSelectionPanel() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isPanelOn) {
        print('try to pop');
        Navigator.of(_context,).popUntil((route) {
          var name = route.settings.name;
          print(name);

          return name == '/add_task';
        });
        _isPanelOn = false;
      }
     });
  }


}

