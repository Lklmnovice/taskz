import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:taskz/custom_widgets/date_item.dart';
import 'package:taskz/custom_widgets/task_widgets.dart';
import 'package:taskz/model/task_model_new.dart';
import 'package:taskz/pages/drawer.dart';
import 'package:taskz/services/locator.dart';
import 'package:taskz/services/time_util.dart';

class _SelectedDate extends ChangeNotifier {
  _SelectedDate({Key key});

  DateTime _selectedDate = DateTimeFormatter.today;

  set selectedDate(DateTime dateTime) {
    _selectedDate = dateTime;
    notifyListeners();
  }

  DateTime get selectedDate => _selectedDate;
}

class UpcomingPage extends StatelessWidget {
  static const String pageRoute = '/upcoming_page';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => _SelectedDate(),
      builder: (context, child) => Scaffold(
        appBar: _AppBar(),
        body: _Body(),
        endDrawer: CustomDrawer(),
      ),
    );
  }
}

class _AppBar extends StatefulWidget implements PreferredSizeWidget {
  @override
  __AppBarState createState() => __AppBarState();

  @override
  Size get preferredSize => Size.fromHeight(
      AppBar().preferredSize.height + _Bottom().preferredSize.height);
}

class __AppBarState extends State<_AppBar> {
  String title = DateTimeFormatter.today.getMonthYearStr();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      centerTitle: true,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      bottom: _Bottom(setMonth: setMonth),
    );
  }

  void setMonth(DateTime dateTime) =>
      setState(() => title = dateTime.getMonthYearStr());
}

class _Bottom extends StatefulWidget implements PreferredSizeWidget {
  _Bottom({this.setMonth});

  final void Function(DateTime dateTime) setMonth;

  @override
  Size get preferredSize => Size.fromHeight(80);

  @override
  __BottomState createState() => __BottomState();
}

class __BottomState extends State<_Bottom> {
  DateTime currentDate;
  DateTime firstDate;
  final _itemCount = 105; //approximately 2 years

  ItemScrollController _scrollController;
  ItemPositionsListener _positionsListener;

  @override
  void initState() {
    super.initState();
    currentDate = DateTimeFormatter.today;
    firstDate = currentDate.toWeekStart();
    Provider.of<_SelectedDate>(context, listen: false).selectedDate =
        currentDate;
    _scrollController = ItemScrollController();
    _positionsListener = ItemPositionsListener.create();
  }

/*  @override
  void didChangeDependencies() {
    selectedDate = Provider.of<_SelectedDate>(context).selectedDate;
  }*/

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.preferredSize.width,
      height: widget.preferredSize.height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: WeekdaysRow(
              textColor: Theme.of(context).colorScheme.secondaryVariant,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    padding: EdgeInsets.all(0),
                    visualDensity: VisualDensity.compact,
                    onPressed: _scrollToPreviousItem,
                    icon: Icon(
                      Icons.arrow_left,
                      color: Theme.of(context).colorScheme.secondaryVariant,
                    )),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onEndScroll,
                    child: Consumer<_SelectedDate>(
                      builder: (context, model, _) {
                        final selectedDate = model.selectedDate;
                        debugPrint("selected date $selectedDate");
                        return ScrollablePositionedList.builder(
                          itemScrollController: _scrollController,
                          itemPositionsListener: _positionsListener,
                          scrollDirection: Axis.horizontal,
                          itemCount: _itemCount,
                          itemBuilder: (context, index) {
                            var begin = firstDate.add(Duration(
                              days: index * 7,
                            ));

                            final dates = List.generate(
                                7, (i) => begin.add(Duration(days: i)));
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final date in dates) ...[
                                  _Disabled(
                                    isDisabled: date < currentDate,
                                    child: Item(
                                      onTap: () => setSelectedDate(date),
                                      boldText: true,
                                      date: date,
                                      size: 40,
                                      textColor: (date == selectedDate)
                                          ? Theme.of(context)
                                              .colorScheme
                                              .secondary
                                          : Theme.of(context)
                                              .colorScheme
                                              .primary,
                                      boxDecoration: BoxDecoration(
                                        color: (date == selectedDate)
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primaryVariant
                                            : Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(6)),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 8,
                                  )
                                ]
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                IconButton(
                    padding: EdgeInsets.all(0),
                    visualDensity: VisualDensity.compact,
                    onPressed: _scrollToNextItem,
                    icon: Icon(
                      Icons.arrow_right,
                      color: Theme.of(context).colorScheme.secondaryVariant,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _onEndScroll(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      final pos = _positionsListener.itemPositions.value;
      if (pos.isNotEmpty) {
        double span = (pos.first.itemTrailingEdge > 1)
            ? 2 - pos.first.itemTrailingEdge
            : pos.first.itemTrailingEdge;

        int desIndex = pos
            .where((ItemPosition position) => position.itemTrailingEdge > 0)
            .reduce((ItemPosition min, ItemPosition position) {
          final itemSpan = (position.itemTrailingEdge > 1)
              ? 2 - position.itemTrailingEdge
              : position.itemTrailingEdge;

          if (itemSpan > span) {
            span = itemSpan;
            return position;
          } else
            return min;
        }).index;

        Future.delayed(Duration(milliseconds: 100), () {
          _scrollController.scrollTo(
              index: desIndex, duration: Duration(milliseconds: 300));
          widget.setMonth(firstDate.add(Duration(days: desIndex * 7)));
        });
      }
    }
    return true;
  }

  void setSelectedDate(DateTime dateTime) {
    Provider.of<_SelectedDate>(context, listen: false).selectedDate = dateTime;
  }

  int _getFirstVisibleItem(Iterable<ItemPosition> positions) {
    // Determine the first visible item by finding the item with the
    // smallest trailing edge that is greater than 0.  i.e. the first
    // item whose trailing edge in visible in the viewport.
    return positions
        .where((ItemPosition position) => position.itemTrailingEdge > 0)
        .reduce((ItemPosition min, ItemPosition position) =>
            position.itemTrailingEdge < min.itemTrailingEdge ? position : min)
        .index;
  }

  void _scrollToPreviousItem() {
    final pos = _positionsListener.itemPositions.value;
    if (pos != null) {
      int i = _getFirstVisibleItem(pos) - 1;
      _scrollController.scrollTo(
          index: (i < _itemCount) ? i : _itemCount - 1,
          duration: Duration(milliseconds: 300));
    }
  }

  void _scrollToNextItem() {
    final pos = _positionsListener.itemPositions.value;
    if (pos != null) {
      int i = _getFirstVisibleItem(pos) + 1;
      _scrollController.scrollTo(
          index: (i >= 0) ? i : 0, duration: Duration(milliseconds: 300));
    }
  }
}

class _Disabled extends StatelessWidget {
  _Disabled({this.child, this.isDisabled});

  final Widget child;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: isDisabled,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1,
        child: child,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        Consumer<_SelectedDate>(builder: (context, model, child) {
          final selectedDate = model.selectedDate;
          final Future<void> isReady = locator<TaskModel>()
              .initializePage(-1, true, selectedDate)
              .then((value) => 1);

          return TaskList(
            isReady: isReady,
            getSubModel: () => locator<TaskModel>()
                .pageId(-1, m: Model.UPCOMING, dateTime: selectedDate),
            limit: selectedDate.add(Duration(days: 1)),
          );
        }),
      ],
    );
  }
}
