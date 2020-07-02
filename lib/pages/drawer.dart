import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskz/custom_widgets/label_tile.dart';
import 'package:taskz/model/label_model.dart';
import 'package:taskz/custom_widgets/circular_icon.dart';

class CustomDrawer extends StatelessWidget {
  final iconSize = 32.0;
  @override
  Widget build(BuildContext context) {


    return Drawer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          DrawerHeader(child: Placeholder()),
          
          Expanded(child: _options()),
          Divider(
            indent:  16,
            endIndent: 16,
            thickness: 1,
          ),
          ListTile(
            leading: CircularIcon(
              icon: Icon(Icons.settings, color: Colors.white,),
              size: iconSize,
            ),
            title: Text('Settings'),
          ),
      ]),
    );
  }

  Widget _options() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 8),
      children: <Widget>[
        ListTile(
          leading: CircularIcon(
            icon: Icon(Icons.today, color: Colors.white,),
            size: iconSize,
          ),
          title: Text('Today'),
        ),

        ListTile(
          leading: CircularIcon(
            icon: Icon(Icons.perm_contact_calendar, color: Colors.white,),
            size: iconSize,
          ),
          title: Text('Upcoming'),
        ),

        ExpansionTile(
          leading: CircularIcon(
            icon: Icon(Icons.today, color: Colors.white,),
            size: iconSize,
          ),
          title: Text('Projects'),
          children: <Widget>[],
        ),

        Consumer<LabelModel>(
          builder: (context, model, _) {
            return ExpansionTile(
              trailing: Wrap(
                spacing: 12,
                children: <Widget>[
                  Icon(Icons.expand_more),
                  GestureDetector(
                      child: Icon(Icons.add),
                      onTap: () => Navigator.pushNamed(context, "/add_label")
                  ),
                ],
              ),
              leading: CircularIcon(
                icon: Icon(Icons.today, color: Colors.white,),
                size: iconSize,
              ),
              title: Text('Labels'),
              initiallyExpanded: false,
              children: <Widget>[
                for (var label in model.labels)
                  LabelTile(
                      label: label,
                      iconSize: iconSize,
                      onTap: () => Navigator.pushNamed(
                          context, '/update_label',
                          arguments: label)
                  )
              ],
            );
          },
        ),

      ],);

  }
}





