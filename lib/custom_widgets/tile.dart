import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskz/model/label_model.dart';
import 'package:taskz/model/data/task.dart';


class CustomTile extends StatelessWidget {

  final List<CustomTile> subTasks;
  final Task task;
  final bool isParent;

  CustomTile({@required this.task, @required this.subTasks, this.isParent=false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isParent
          ? BoxDecoration(
        boxShadow: kElevationToShadow[3],
        borderRadius: BorderRadius.all(Radius.circular(6))
      )
          : null,
      child: Material(
        child: Column(
          children: <Widget>[
            _CustomTileContent(task:task,),
            if (subTasks.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(left: 24),
                child: ListView(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics() ,
                  children: subTasks,
                ),
              ),
          ],
        ),
      ),
    );
  }
}



class _CustomTileContent extends StatefulWidget {
  final Task task;

  _CustomTileContent({@required this.task});


  @override
  _CustomTileContentState createState() => _CustomTileContentState();
}

class _CustomTileContentState extends State<_CustomTileContent> {
  bool state = false;

  @override
  Widget build(BuildContext context) {
    return Ink(
      height: 60,
      child: InkWell(
        onTap: _changeState,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Checkbox(
              onChanged: (newValue){_changeState();},
              value: this.state,
            ),
            SizedBox(width: 12,),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(this.widget.task.description,
                    style: TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),

                  Consumer<LabelModel>(
                    builder: (context, model,_) {
                      return Row(
                        children: <Widget>[
                          for (var id in this.widget.task.labelIds) ...[
                            model.getTagByID(id),
                            SizedBox(width: 12)
                          ]
                        ],
                      );},
                  ),
                ],),
            ),
          ],),
      ),
    );
  }

  void _changeState() {
    setState(() {
      //todo invoke task detail page
      this.state = !this.state;
    });

  }
}


