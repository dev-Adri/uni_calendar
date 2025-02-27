import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:uni_calendar_2/core/helpers/database.dart';
import '../widgets/subject_block.dart';
import '../widgets/new_subj_popup.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Add this import for Timer

import 'dart:convert' show json; // This gives us access to json.decode()
import 'package:flutter/services.dart'
    show rootBundle; // This gives us access to rootBundle

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

List<String> weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday'
];

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timer;

  String? day;

  Future<void> loadDataFromJson() async {
    try {
      // Load the JSON file from assets
      final String jsonString = await rootBundle.loadString('assets/db.json');
      final Map<String, dynamic> data = json.decode(jsonString);

      final db = DatabaseHelper();

      // Clean the database first
      await db.clean('subjects');

      // Insert data for each day
      for (var day in weekdays) {
        final subjects = data[day] as List<dynamic>;
        for (var subject in subjects) {
          await db.insert('subjects', {
            'name': subject['name'],
            'room': subject['room'],
            'hours': subject['hours'],
            'link': subject['link'],
            'day': day,
          });
        }
      }
    } catch (e) {
      log("error loading database: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    // Start the timer when the widget is created
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        // This empty setState will trigger a rebuild
      });
    });
    day = getWeekDay();
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    _timer?.cancel();
    super.dispose();
  }

  String getWeekDay() {
    DateTime now = DateTime.now();
    return weekdays[now.weekday - 1];
  }

  Future<List<Map<String, dynamic>>> getBy(String day) async {
    final db = DatabaseHelper();
    return await db.getBy('subjects', day);
  }

  DateTime parseTimeString(String timeStr) {
    final now = DateTime.now();
    final time = timeStr.split('-')[0];
    final parts = time.split(':');
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  bool isSubjectActive(String timeRange) {
    final currentTime = TimeOfDay.now();
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;

    final times = timeRange.split('-');
    final startTime = times[0].split(':');
    final endTime = times[1].split(':');

    final startMinutes = int.parse(startTime[0]) * 60 + int.parse(startTime[1]);
    final endMinutes = int.parse(endTime[0]) * 60 + int.parse(endTime[1]);

    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Ακαδημαϊκό πρόγραμμα'),
            actions: [
              IconButton(
                icon: const Icon(Icons.wifi),
                onPressed: () async {
                  bool? confirmLoad = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                              title: const Text("Connection confirmation"),
                              content: const Text(
                                  "Do you want to connect and load data from server?"),
                              actions: [
                                TextButton(
                                  child: const Text("Yes"),
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                  },
                                ),
                                TextButton(
                                  child: const Text("No"),
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                  },
                                ),
                              ]));
                  if (confirmLoad == true) {
                    // load local db for now
                    await loadDataFromJson();
                    setState(() {});
                  }
                },
              ),
              // refresh button
              IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    day = getWeekDay();
                    setState(() {});
                  }),
              // delete button
              IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final db = DatabaseHelper();
                    await db.clean('subjects');
                    setState(() {});
                  }),
              // add button
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  final result = await showNewSubjPopup(context);
                  if (result != null) {
                    setState(() {});
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${DateFormat("d MMMM y").format(DateTime.now())} (${DateFormat("d/M/y").format(DateTime.now())})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // drop down pick day button
                    DropdownButton(
                      value: day,
                      icon: const Icon(Icons.arrow_drop_down),
                      items: weekdays
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        day = value;
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: getBy(day ?? getWeekDay()),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Text('No data found for $day');
                      } else {
                        final results =
                            List<Map<String, dynamic>>.from(snapshot.data!);
                        results.sort((a, b) {
                          final timeA = parseTimeString(a['hours']);
                          final timeB = parseTimeString(b['hours']);
                          return timeA.compareTo(timeB);
                        });

                        return Column(
                          children: results.map((entry) {
                            final isActive = isSubjectActive(entry['hours']);
                            return Opacity(
                              opacity: isActive ? 1.0 : 0.3,
                              child: SubjectBlock(
                                hour: entry['hours'] ?? '',
                                subjName: entry['name'] ?? '',
                                room: entry['room'] ?? '',
                                link: entry['link'] ?? '',
                                id: entry['id'].toString(),
                                onDelete: () {
                                  setState(() {});
                                },
                              ),
                            );
                          }).toList(),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
