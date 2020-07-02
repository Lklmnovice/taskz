import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskz/custom_widgets/custom_list.dart';
import 'package:taskz/model/label_model.dart';
import 'add_task.dart';
import 'package:taskz/pages/drawer.dart';

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //todo load date from sqlite and parse it into a list
    return Scaffold(
      resizeToAvoidBottomInset: false,
      endDrawer: CustomDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          Navigator.of(context).pushNamed('/add_task');
        },
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        child: Icon(Icons.add)
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          Column(
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      'Today',
                      style: Theme.of(context).textTheme.headline3.apply(color: Colors.white),
                    ),
                    RichText(

                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyText1.apply(color: Colors.white),
                        children: <TextSpan>[
                          TextSpan(text: 'TUE', style: TextStyle(fontWeight: FontWeight.w600)),
                          TextSpan(
                              text: ' 2020-06-02',
                          )],
                      ),
                    ),
                    Container(width: 32, child: Divider(height: 20, color: Colors.grey, thickness: 1,)),
                    Text(
                        '3/7 completed',
                        style: Theme.of(context).textTheme.bodyText1.apply(color: Colors.grey)),
                    SizedBox(height: 8,)
                  ],
                ),
              ),

              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0,),
                  child: CustomList(),
                )
              )
            ],),
        ],),
    );
  }
}
