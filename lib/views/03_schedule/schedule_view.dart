import 'package:crayon/views/03_schedule/timeslot_view.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class ScheduleView extends StatefulWidget {
  const ScheduleView({Key? key}) : super(key: key);

  @override
  _ScheduleViewState createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  DateTime _focusedDay = DateTime.now();
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;

  @override
  void initState() {
    _selectedDay = _focusedDay;
    super.initState();
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    //초기화
    print("onDaySelected");
    print(selectedDay);
    print(focusedDay);
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _focusedDay = focusedDay;
        _selectedDay = selectedDay;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Schedule view build");
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          TableCalendar(
            locale: 'ko-KR',
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            availableCalendarFormats: {CalendarFormat.twoWeeks: '2 weeks'},
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(
                  color: const Color(0xffF07B3F), shape: BoxShape.circle),
            ),
            headerStyle: HeaderStyle(
              titleTextStyle:
                  const TextStyle(fontSize: 20.0, color: Colors.black),
              formatButtonVisible: false,
              titleCentered: true,
            ),
            onDaySelected: onDaySelected,
            onPageChanged: (focusedDay) {
              // No need to call `setState()` here
              _focusedDay = focusedDay;
            },
          ),
          Divider(thickness: 1.5),
          TimeSlotView(selectedDay: _selectedDay),
        ],
      ),
    );
  }
}
