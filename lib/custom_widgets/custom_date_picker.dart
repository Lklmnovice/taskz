import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:inview_notifier_list/inview_notifier_list.dart';
import 'package:provider/provider.dart';
import 'package:taskz/model/task_model.dart';
import 'package:taskz/services/time_util.dart';

import 'package:taskz/extended_color_scheme.dart';

class _MonthData extends ChangeNotifier {
  DateTime _dateTime = DateTimeFormatter.today;

  set date(DateTime dateTime) {
    _dateTime = dateTime;
    notifyListeners();
  }

  DateTime get date => _dateTime;
}

Future<DateTime> showCustomDatePicker(BuildContext context) {
  final mainContext = context;
  return showModalBottomSheet(
    backgroundColor: Theme.of(context).colorScheme.secondary,
    context: context,
    shape: ContinuousRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
    isScrollControlled: true,
    enableDrag: true,
    builder: (context) => _PickDate(
      context: context,
      mainContext: mainContext,
    ),
  );
}

class _PickDate extends StatelessWidget {
  final _padding = const EdgeInsets.symmetric(horizontal: 10);

  final BuildContext context;
  final BuildContext
      mainContext; // fixes [39205](https://github.com/flutter/flutter/issues/39205)
  _PickDate({this.context, this.mainContext});
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(top: 0),
          child: ChangeNotifierProvider(
            create: (context) => _MonthData(),
            child: InViewNotifierCustomScrollView(
              isInViewPortCondition:
                  (deltaTop, deltaBottom, viewPortDimension) =>
                      deltaTop < (0.1 * viewPortDimension) &&
                      deltaBottom > (0.2 * viewPortDimension),
              // initialInViewIds: List.generate(24, (index) => '$index'),
              controller: scrollController,
              slivers: [
                SliverPadding(
                    padding: _padding.copyWith(top: 8),
                    sliver: _SliverQuickOptions()),
                SliverToBoxAdapter(
                  child: Divider(
                    endIndent: 12,
                    indent: 12,
                    color: Theme.of(context).colorScheme.secondaryVariant,
                    height: 24,
                  ),
                ),
                _CalendarHeader(
                    mainContext: mainContext,
                    scrollController: scrollController),
                SliverPadding(
                  padding: _padding,
                  sliver: _CalendarDates(scrollController: scrollController),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SliverQuickOptions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverFixedExtentList(
      itemExtent: 40,
      delegate: SliverChildListDelegate.fixed([
        _QuickOption(context, 'TODAY', DateTimeFormatter.today, Icons.event),
        _QuickOption(
            context, 'TOMORROW', DateTimeFormatter.tomorrow, Icons.wb_sunny),
        _QuickOption(context, 'NO DATE', null, Icons.block),
      ]),
    );
  }
}

Widget _QuickOption(
    BuildContext context, String title, DateTime trailing, IconData leading) {
  return ListTile(
    title: Text(
      title,
      style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary),
    ),
    leading: Icon(
      leading,
      color: Theme.of(context).colorScheme.primary,
    ),
    trailing: trailing != null
        ? Text(
            trailing.getWeekDay(),
            style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.secondaryVariant),
          )
        : null,
    onTap: () {
      Navigator.of(context).pop(trailing);
    },
  );
}

const CALENDAR_E_HEIGHT = 32.0;

class _FixedRow extends StatelessWidget {
  _FixedRow({
    this.strs,
    this.textColor,
  }) : assert(strs.length == 7);

  final List<String> strs;
  final Color textColor;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (final s in strs)
          Container(
            width: CALENDAR_E_HEIGHT,
            height: CALENDAR_E_HEIGHT,
            alignment: Alignment.center,
            child: Text(s, style: TextStyle(fontSize: 14, color: textColor)),
          )
      ],
    );
  }
}

class _CalendarHeader extends StatefulWidget {
  _CalendarHeader({this.mainContext, this.scrollController});

  final BuildContext mainContext;
  final ScrollController scrollController;
  @override
  __CalendarHeaderState createState() => __CalendarHeaderState();
}

class __CalendarHeaderState extends State<_CalendarHeader> {
  bool isPinned = false;

  @override
  Widget build(BuildContext context) {
    void updateState(bool state) {
      if (this.isPinned != state)
        setState(() {
          this.isPinned = state;
        });
    }

    return SliverPersistentHeader(
      pinned: true,
      delegate: _CalendarHeaderDelegate(isPinned,
          scrollController: widget.scrollController,
          mainContext: widget.mainContext,
          updateState: updateState),
    );
  }
}

class _CalendarHeaderDelegate extends SliverPersistentHeaderDelegate {
  _CalendarHeaderDelegate(this.isPinned,
      {this.scrollController,
      @required this.mainContext,
      @required this.updateState});

  final bool isPinned;
  final BuildContext mainContext;
  final ScrollController scrollController;
  final Function(bool state) updateState;

  @override
  double get minExtent =>
      _statusBar + (isPinned ? _dateBar : 0.0) + CALENDAR_E_HEIGHT + _dataRow;

  @override
  double get maxExtent =>
      _statusBar + (isPinned ? _dateBar : 0.0) + CALENDAR_E_HEIGHT + _dataRow;

  double get _statusBar => MediaQuery.of(mainContext).padding.top;
  final _dateBar = 56.0;
  final _dataRow = 12.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateState(shrinkOffset > 0);
    });
    return AnimatedOpacity(
      duration: Duration(milliseconds: 200),
      opacity: isPinned ? 1 : 0.7,
      child: Container(
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            boxShadow: isPinned ? kElevationToShadow[3] : null),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isPinned)
              Container(
                padding: EdgeInsets.only(top: _statusBar),
                height: _dateBar + _statusBar,
                width: double.infinity,
                color: Theme.of(context).colorScheme.primary,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Consumer<_MonthData>(
                      builder: (_, model, __) => Text(
                        model.date.getMonthStr(),
                        style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ),
                    Positioned(
                        right: 6,
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_drop_up,
                            size: 32,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: () => scrollController.animateTo(0,
                              duration: Duration(seconds: 1),
                              curve: Curves.easeInOut),
                        ))
                  ],
                ),
              ),
            _FixedRow(
              textColor: Theme.of(context).colorScheme.primaryVariant2,
              strs: const ['M', 'T', 'T', 'W', 'F', 'S', 'S'],
            ),
            Container(
              height: _dataRow,
              child: Text(
                'Mon 17 Jun   2 task due',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.secondaryVariant,
                    fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );

    // return Container(color: isPinned ? Colors.blue : Colors.yellow);
  }

  @override
  bool shouldRebuild(covariant _CalendarHeaderDelegate oldDelegate) {
    return isPinned != oldDelegate.isPinned;
  }
}

class _CalendarDates extends StatelessWidget {
  _CalendarDates({this.scrollController}) {
    final begin = DateTimeFormatter.today;
    _data = <DateTime>[begin];
    var temp = begin.toMonthStart();
    for (var i = 0; i < 24; i++) {
      _data.add(temp.add(Duration(days: 32)).toMonthStart());
      temp = _data.last;
    }
  }
  final ScrollController scrollController;
  List<DateTime> _data;
  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) => _Month(
            begin: _data[index],
            scrollController: scrollController,
            index: index),
        childCount: _data.length,
      ),
    );
  }
}

class _Month extends StatelessWidget {
  /// [begin] inclusive ==> [end] inclusive
  _Month({@required this.begin, this.end, this.scrollController, this.index}) {
    end ??= begin.toMonthEnd();
    _data = [];
    for (var i = 1; i < begin.weekday; i++) _data.add(null);

    final _end = end.add(Duration(days: 1));
    for (var i = begin;
        i.microsecondsSinceEpoch < _end.microsecondsSinceEpoch;
        i = i.add(Duration(days: 1))) _data.add(i);

    _data = List.unmodifiable(_data);
  }

  final ScrollController scrollController;
  final DateTime begin;
  DateTime end;
  List<DateTime> _data;
  final int index;

  @override
  Widget build(BuildContext context) {
    return InViewNotifierWidget(
      id: '$index',
      builder: (context, isInView, child) {
        if (isInView)
          WidgetsBinding.instance.addPostFrameCallback((_) =>
              Provider.of<_MonthData>(context, listen: false).date = begin);
        return child;
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            begin.getMonthStr(),
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary),
          ),
          _getDays()
        ],
      ),
    );
  }

  Widget _getDays() {
    return GridView.builder(
      controller: scrollController,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        childAspectRatio: 1,
        crossAxisCount: 7,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, index) => _Item(
        date: _data[index],
        textColor: Theme.of(context).colorScheme.primary,
      ),
      itemCount: _data.length,
      shrinkWrap: true,
    );
  }
}

class _Item extends StatelessWidget {
  _Item({this.textColor, this.date});

  final Color textColor;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final String str = date?.day?.toString();
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(date),
      child: Consumer<TaskModel>(
        builder: (context, model, child) {
          return FutureBuilder<int>(
              future: model.countTasksInDate(date),
              builder: (context, snapshot) {
                final _widget = (str != null && snapshot.hasData)
                    ? Positioned(
                        bottom: 0,
                        child: (snapshot.data == 0)
                            ? Container()
                            : (snapshot.data < 4) ? _Dot() : _Dot.double(),
                      )
                    : Container();
                return Container(
                    width: CALENDAR_E_HEIGHT,
                    height: CALENDAR_E_HEIGHT,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (child != null) child,
                        if (_widget != null) _widget
                      ],
                    ));
              });
        },
        child: str != null
            ? Text(str, style: TextStyle(fontSize: 14, color: textColor))
            : Container(),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  _Dot.double() : isDouble = true;
  _Dot() : isDouble = false;

  final bool isDouble;
  final _size = 5.0;

  @override
  Widget build(BuildContext context) {
    return isDouble
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle),
              ),
              SizedBox(width: 2),
              Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle),
              ),
            ],
          )
        : Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle),
          );
  }
}
