import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskz/custom_widgets/label_tile.dart';
import 'package:taskz/model/label_model.dart';
import 'package:taskz/extended_color_scheme.dart';
import 'package:taskz/pages/home_page.dart';
import 'package:taskz/pages/upcoming_page.dart';
import 'package:taskz/pages/add_edit_label.dart';

class CustomDrawer extends StatelessWidget {
  final iconSize = 32.0;
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ChangeNotifierProvider<_Group>(
        create: (context) => _Group(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Placeholder()),
            Expanded(child: _options(context)),
            _CustomTile(
                builder: (context, checked, toggleState) => AnimatedContainer(
                      decoration: BoxDecoration(
                        color: checked
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        boxShadow: checked ? kElevationToShadow[2] : null,
                      ),
                      duration: Duration(milliseconds: 200),
                      curve: Curves.easeIn,
                      child: ListTile(
                        onTap: toggleState,
                        leading: Icon(
                          Icons.settings,
                          color: checked
                              ? Colors.white
                              : Theme.of(context).colorScheme.primaryVariant,
                        ),
                        title: Text(
                          'Settings',
                          style: TextStyle(
                              color: checked
                                  ? Colors.white
                                  : Theme.of(context)
                                      .colorScheme
                                      .primaryVariant),
                        ),
                      ),
                    )),
          ],
        ),
      ),
    );
  }

  Widget _options(BuildContext context) {
    final defaultColor = Theme.of(context).colorScheme.primaryVariant;
    final currentRoute = ModalRoute.of(context).settings.name;

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          _CustomTile(
              initialState: currentRoute == HomePage.pageRoute,
              builder: (context, checked, toggleState) => ListTile(
                    onTap: () {
                      toggleState();
                      Future.delayed(
                          Duration(
                            milliseconds: 200,
                          ), () {
                        Navigator.of(context)
                          ..pop()
                          ..pushReplacementNamed(HomePage.pageRoute);
                      });
                    },
                    leading: Icon(
                      Icons.today,
                      color: checked ? Colors.white : defaultColor,
                    ),
                    title: Text(
                      'Today',
                      style: TextStyle(
                          color: checked ? Colors.white : defaultColor),
                    ),
                  )),
          _CustomTile(
            initialState: currentRoute == UpcomingPage.pageRoute,
            builder: (context, checked, toggleState) => ListTile(
              onTap: () {
                toggleState();
                Future.delayed(
                    Duration(
                      milliseconds: 200,
                    ),
                    () => Navigator.of(context)
                        .pushReplacementNamed(UpcomingPage.pageRoute));
              },
              leading: Icon(
                Icons.perm_contact_calendar,
                color: checked ? Colors.white : defaultColor,
              ),
              title: Text(
                'Upcoming',
                style: TextStyle(color: checked ? Colors.white : defaultColor),
              ),
            ),
          ),
          _CustomTile(
            shareGroup: false,
            builder: (context, checked, toggleState) => ExpansionTile(
              leading: Icon(
                Icons.today,
                color: checked ? Colors.white : defaultColor,
              ),
              title: Text(
                'Projects',
                style: TextStyle(
                    color: checked
                        ? Theme.of(context).colorScheme.primaryVariant2
                        : defaultColor),
              ),
              children: <Widget>[],
            ),
          ),
          _CustomTile(
            shareGroup: false,
            builder: (context, checked, toggleState) => Consumer<LabelModel>(
              builder: (context, model, _) {
                return ExpansionTile(
                  onExpansionChanged: (_) => toggleState(),
                  trailing: Wrap(
                    spacing: 12,
                    children: <Widget>[
                      Icon(Icons.expand_more),
                      GestureDetector(
                          child: Icon(Icons.add),
                          onTap: () {
                            Navigator.pop(context);
                            Future.delayed(Duration(milliseconds: 100),
                                () => showUpdateTag(context));
                          }),
                    ],
                  ),
                  leading: Icon(
                    Icons.today,
                    color: checked
                        ? Theme.of(context).colorScheme.secondaryVariant2
                        : defaultColor,
                  ),
                  title: Text(
                    'Labels',
                    style: TextStyle(
                        color: checked
                            ? Theme.of(context).colorScheme.secondaryVariant2
                            : defaultColor),
                  ),
                  children: <Widget>[
                    for (var label in model.labels)
                      LabelTile(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          backgroundColor: Colors.grey[300],
                          textColor: Theme.of(context).colorScheme.primary,
                          label: label,
                          iconSize: iconSize,
                          onTap: () {
                            Navigator.pop(context);
                            Future.delayed(Duration(milliseconds: 100),
                                () => showUpdateTag(context, label));
                          })
                  ],
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class _CustomTile extends StatelessWidget {
  _CustomTile(
      {@required this.builder,
      this.initialState = false,
      this.shareGroup = true});

  final bool initialState, shareGroup;
  final Widget Function(
      BuildContext context, bool checked, Function toggleState) builder;

  @override
  Widget build(BuildContext context) {
    if (shareGroup)
      Provider.of<_Group>(context, listen: false).register(this);
    else
      Provider.of<_Group>(context, listen: false).registerSingle(this);
    void toggleState() {
      if (shareGroup)
        Provider.of<_Group>(context, listen: false).setActive(this);
      else
        Provider.of<_Group>(context, listen: false).toggleSingle(this);
    }

    if (initialState)
      WidgetsBinding.instance.addPostFrameCallback((_) => toggleState());

    return Consumer<_Group>(builder: (context, getState, child) {
      bool checked = getState(shareGroup, this);
      return AnimatedContainer(
        decoration: BoxDecoration(
          color: checked
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          boxShadow: checked ? kElevationToShadow[2] : null,
        ),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeIn,
        child: builder(context, checked, toggleState),
      );
    });
  }
}

class _Group extends ChangeNotifier {
  Map<_CustomTile, bool> map;
  Map<_CustomTile, bool> mapSingle;

  _Group() {
    map = <_CustomTile, bool>{};
    mapSingle = <_CustomTile, bool>{};
  }

  register(_CustomTile tile) {
    assert(tile != null);
    if (!map.containsKey(tile)) {
      map[tile] = false;
    }
  }

  registerSingle(_CustomTile tile) {
    assert(tile != null);
    if (!mapSingle.containsKey(tile)) {
      mapSingle[tile] = false;
    }
  }

  setActive(_CustomTile tile) {
    assert(tile != null);
    map.forEach((key, value) => map[key] = key == tile);

    notifyListeners();
  }

  toggleSingle(_CustomTile tile) {
    assert(tile != null);
    mapSingle[tile] = !(mapSingle[tile] ?? false);

    notifyListeners();
  }

  bool call(bool shareGroup, _CustomTile tile) =>
      shareGroup ? map[tile] ?? false : mapSingle[tile] ?? false;
}
