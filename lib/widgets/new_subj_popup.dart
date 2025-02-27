// import 'dart:developer';

import 'package:flutter/material.dart';
import '../core/helpers/database.dart';

class NewSubjPopup extends StatefulWidget {
  const NewSubjPopup({super.key});

  @override
  _NewSubjPopupState createState() => _NewSubjPopupState();
}

class _NewSubjPopupState extends State<NewSubjPopup> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _endTimeManuallySet = false;
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  late String _selectedDay;

  String formatTimeNumber(int n) {
    return n.toString().padLeft(2, '0');
  }

  TimeOfDay addHours(TimeOfDay time, int hours) {
    final totalMinutes = time.hour * 60 + time.minute + (hours * 60);
    return TimeOfDay(
      hour: (totalMinutes ~/ 60) % 24,
      minute: totalMinutes % 60,
    );
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        // Only update end time if it hasn't been manually set
        if (!_endTimeManuallySet) {
          _endTime = addHours(picked, 2);
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? addHours(_startTime ?? TimeOfDay.now(), 2),
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
        _endTimeManuallySet = true; // Mark that end time has been manually set
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final now = TimeOfDay.now();
    _startTime = now;
    _endTime = addHours(now, 2);
    final today = DateTime.now().weekday;
    _selectedDay = _days[today - 1];
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _roomController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Widget _buildDayDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedDay,
      decoration: const InputDecoration(
        labelText: 'Day',
        labelStyle: TextStyle(color: Colors.black),
      ),
      items: _days.map((String day) {
        return DropdownMenuItem<String>(
          value: day,
          child: Text(day),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedDay = newValue;
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a day';
        }
        return null;
      },
    );
  }

  bool isFormValid() {
    return _startTime != null &&
        _endTime != null &&
        _subjectController.text.isNotEmpty &&
        _roomController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Subject'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      onTap: _pickStartTime,
                      decoration: InputDecoration(
                        labelText: 'Start Time*',
                        labelStyle: const TextStyle(color: Colors.black),
                        hintText: 'Select start time',
                        errorText: _startTime == null ? 'Required' : null,
                      ),
                      controller: TextEditingController(
                        text: _startTime?.format(context) ?? '',
                      ),
                      validator: (value) {
                        if (_startTime == null) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      onTap: _pickEndTime,
                      decoration: InputDecoration(
                        labelText: 'End Time*',
                        labelStyle: const TextStyle(color: Colors.black),
                        hintText: 'Select end time',
                        errorText: _endTime == null ? 'Required' : null,
                      ),
                      controller: TextEditingController(
                        text: _endTime?.format(context) ?? '',
                      ),
                      validator: (value) {
                        if (_endTime == null) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject*',
                  labelStyle: TextStyle(color: Colors.black),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a subject';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(
                  labelText: 'Room*',
                  labelStyle: TextStyle(color: Colors.black),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a room';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Link',
                  labelStyle: TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(height: 10),
              _buildDayDropdown(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final result = {
                'startTime':
                    '${formatTimeNumber(_startTime!.hour)}:${formatTimeNumber(_startTime!.minute)}',
                'endTime':
                    '${formatTimeNumber(_endTime!.hour)}:${formatTimeNumber(_endTime!.minute)}',
                'subject': _subjectController.text,
                'room': _roomController.text,
                'link': _linkController.text,
                'day': _selectedDay
              };

              final timeStr = "${result["startTime"]}-${result["endTime"]}";

              final db = DatabaseHelper();

              await db.insert('subjects', {
                'name': result['subject'],
                'room': result['room'],
                'hours': timeStr,
                'day': result['day'],
                'link': result['link']
              });

              Navigator.of(context).pop(result);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

Future<Map<String, dynamic>?> showNewSubjPopup(BuildContext context) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => const NewSubjPopup(),
  );
}
