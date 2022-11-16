/// Example event class.
class Event {
  String time;
  int possibleSlots;
  List possibleChildList;
  Event(this.time, this.possibleSlots,this.possibleChildList);

  String showTime(){
    return time;
  }
  @override
  String toString() => time;
}