import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:taskz/custom_widgets/custom_appBar_FAB.dart';
import 'package:taskz/custom_widgets/custom_reorderable_sliver_list.dart'
    as Custom;
import 'package:taskz/custom_widgets/task_widgets.dart';
import 'package:taskz/model/task_model_new.dart';
import 'package:taskz/pages/drawer.dart';
import 'package:taskz/services/locator.dart';
import 'package:taskz/services/time_util.dart';
import '../extended_color_scheme.dart';

const APPBAR_HEIGHT = 56.0;
const MAIN_MARGIN = 24.0;

class HomePage extends StatelessWidget {
  static const pageRoute = '/';
  final _backdropKey = GlobalKey<__BackDropState>();
  final _dfabKey = GlobalKey<Custom.DraggableFloatingActionButtonState>();
  final _drawerKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _drawerKey,
      endDrawer: CustomDrawer(),
      floatingActionButton: CustomFAB(
        dfabKey: _dfabKey,
      ),
      body: Stack(
        children: <Widget>[
          _BackDrop(key: _backdropKey),
          CustomScrollView(
            slivers: <Widget>[
              DailyInfoAppBar(backdropKey: _backdropKey, drawerKey: _drawerKey),
              TaskList(
                limit: DateTimeFormatter.tomorrow,
                fabKey: _dfabKey,
                isReady: locator.allReady(),
                getSubModel: () =>
                    locator<TaskModel>().pageId(-1, m: Model.TODAY),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class DailyInfoAppBar extends StatefulWidget {
  final Key backdropKey;
  final Key drawerKey;
  DailyInfoAppBar({this.backdropKey, this.drawerKey});

  @override
  _DailyInfoAppBarState createState() => _DailyInfoAppBarState();
}

class _DailyInfoAppBarState extends State<DailyInfoAppBar> {
  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      floating: false,
      delegate: _DailyInfoAppBarDelegate(
          context: context,
          backdropKey: widget.backdropKey,
          drawerKey: widget.drawerKey),
    );
  }
}

class _DailyInfoAppBarDelegate implements SliverPersistentHeaderDelegate {
  _DailyInfoAppBarDelegate({this.context, this.backdropKey, this.drawerKey})
      : topPadding = MediaQuery.of(context).padding.top,
        _tweenHeader = TextStyleTween(
            begin: const TextStyle(color: Colors.white, fontSize: 16),
            end: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        _tweenShift = Tween<Offset>(
            begin: Offset.zero,
            end: Offset(-MediaQuery.of(context).size.width, 0)),
        _tweenPadding = EdgeInsetsTween(
            begin: EdgeInsets.only(left: MAIN_MARGIN, top: 116),
            end: EdgeInsets.only(
                left: MAIN_MARGIN,
                top: (APPBAR_HEIGHT + MediaQuery.of(context).padding.top) / 2));

  @override
  double get maxExtent => 200;
  @override
  double get minExtent => APPBAR_HEIGHT + topPadding;
  final BuildContext context;
  final double topPadding;

  final TextStyleTween _tweenHeader;
  final EdgeInsetsTween _tweenPadding;
  final Tween<Offset> _tweenShift;
  final GlobalKey<__BackDropState> backdropKey;
  final GlobalKey<ScaffoldState> drawerKey;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress =
        (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0) as double;
    final dayTextStyle = _tweenHeader.lerp(progress);
    final infoBarOffset = _tweenShift.lerp(progress);
    final dayMargin = _tweenPadding.lerp(progress);

    WidgetsBinding.instance.addPostFrameCallback(
        (_) => backdropKey.currentState.updateProgress(progress));

    return Stack(children: <Widget>[
      if (progress >= 0.99)
        AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(6))),
          actions: <Widget>[
            IconButton(
                onPressed: () {
                  drawerKey.currentState.openEndDrawer();
                },
                icon: Icon(Icons.menu))
          ],
        ),
      Padding(
        padding: const EdgeInsets.only(left: MAIN_MARGIN, top: APPBAR_HEIGHT),
        child: Opacity(
            opacity: 1 - progress,
            child: Text(
              'Today',
              style: TextStyle(
                  fontSize: 48,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            )),
      ),
      Padding(
          // test
          padding: dayMargin,
          child: Text.rich(TextSpan(
              text: DateTimeFormatter.today.getWeekDay(),
              style: dayTextStyle,
              children: [
                TextSpan(
                  text: ' ' * 2 + DateTimeFormatter.today.toHyphenedYYYYMMDD(),
                  style: TextStyle(fontWeight: FontWeight.w300),
                ),
              ]))),
      Padding(
          padding: EdgeInsets.only(
              left: MAIN_MARGIN, right: MAIN_MARGIN, bottom: 16),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: ClipRect(
              child: Transform.translate(
                  offset: infoBarOffset, //animation
                  child: TodayProgressIndicator()),
            ),
          )),
    ]);
  }

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => false;

  @override
  OverScrollHeaderStretchConfiguration stretchConfiguration;

  @override
  FloatingHeaderSnapConfiguration snapConfiguration;
}

class TodayProgressIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
//    final model = locator<TaskModel>();
//    int completed = model.tasks.length;
//    int uncompleted = model.nTodayTask;
    return FutureBuilder<void>(
      future: locator.allReady(),
      builder: (context, snapshot) {
        final model = snapshot.hasData ? Provider.of<TaskModel>(context) : null;
        int total = snapshot.hasData ? model.todayTotalTask : 0;
        int finished = snapshot.hasData ? model.todayTotalCompletedTasks : 0;
        if (total == 0) total = 1;
        double value =
            snapshot.hasData ? (finished / total).clamp(0.0, 1.0) : 1;

        return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: LinearProgressIndicator(
                  semanticsLabel: 'The amount of work completed for today',
                  semanticsValue: (value * 100).toInt().toString() + '%',
                  value: value < 0.1 ? 1 : value,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(!snapshot.hasData
                      ? Theme.of(context).colorScheme.error
                      : value > 0.1
                          ? Theme.of(context).colorScheme.primaryVariant2
                          : Colors.white),
                ),
              ),
              SizedBox(
                width: 16,
              ),
              Text(
                '$finished/$total',
                style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primaryVariant2),
              )
            ]);
      },
    );
  }
}

class _BackDrop extends StatefulWidget {
  final Key key;

  _BackDrop({this.key}) : super(key: key);

  @override
  __BackDropState createState() => __BackDropState();
}

class __BackDropState extends State<_BackDrop> {
  double progress = 0;

  @override
  Widget build(BuildContext context) {
    final Tween<double> _tweenHeight = Tween<double>(
      begin: MediaQuery.of(context).size.height * 0.5,
      end: APPBAR_HEIGHT + MediaQuery.of(context).padding.top,
    );
    return AnimatedContainer(
      duration: Duration(milliseconds: 100),
      height: _tweenHeight.lerp(progress),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(6)),
      ),
    );
  }

  void updateProgress(double progress) {
    setState(() {
      this.progress = progress;
    });
  }
}
