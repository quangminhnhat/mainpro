import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/ScheduleService.dart';

class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  State<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  final ScheduleService _scheduleService = ScheduleService();
  bool _isLoading = true;
  String? _currentWeekStart;
  String? _prevWeekStart;
  String? _nextWeekStart;
  List<dynamic> _days = [];
  List<dynamic> _scheduleData = [];

  @override
  void initState() {
    super.initState();
    _fetchSchedule();
  }

  Future<void> _fetchSchedule({String? weekStart}) async {
    setState(() => _isLoading = true);
    final result = await _scheduleService.getMySchedule(weekStart: weekStart);
    if (mounted) {
      if (result['success']) {
        setState(() {
          _days = result['days'];
          _scheduleData = result['scheduleData'];
          _currentWeekStart = result['weekStart'];
          _prevWeekStart = result['prevWeekStart'];
          _nextWeekStart = result['nextWeekStart'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () => _fetchSchedule(),
            tooltip: 'Current Week',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildWeekNavigator(),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 20,
                        headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
                        columns: [
                          const DataColumn(label: Text('Period', style: TextStyle(fontWeight: FontWeight.bold))),
                          ..._days.map((day) => DataColumn(
                            label: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(day['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(day['date'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal)),
                              ],
                            ),
                          )),
                        ],
                        rows: List.generate(15, (index) {
                          final period = index + 1;
                          return DataRow(
                            cells: [
                              DataCell(Text('P $period', style: const TextStyle(fontWeight: FontWeight.bold))),
                              ..._days.map((day) {
                                final classes = _scheduleData.where((cls) => 
                                  cls['date'] == day['iso'] && 
                                  cls['startPeriod'] <= period && 
                                  cls['endPeriod'] >= period
                                ).toList();

                                if (classes.isEmpty) {
                                  return const DataCell(Text(''));
                                }

                                final cls = classes.first;
                                final bool isRegular = cls['type'] == 'regular';

                                return DataCell(
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    margin: const EdgeInsets.symmetric(vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isRegular ? Colors.blue.shade50 : Colors.orange.shade50,
                                      border: Border(left: BorderSide(color: isRegular ? Colors.blue : Colors.orange, width: 4)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(cls['courseName'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                        Text(cls['className'], style: const TextStyle(fontSize: 9), overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWeekNavigator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _fetchSchedule(weekStart: _prevWeekStart),
          ),
          if (_days.isNotEmpty)
            Text(
              '${_days[0]['date']} - ${_days[6]['date']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _fetchSchedule(weekStart: _nextWeekStart),
          ),
        ],
      ),
    );
  }
}
