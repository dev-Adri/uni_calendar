import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/helpers/database.dart';

class SubjectBlock extends StatefulWidget {
  final String hour;
  final String subjName;
  final String room;
  final String link;
  final String id;

  final VoidCallback onDelete;

  const SubjectBlock(
      {super.key,
      required this.hour,
      required this.subjName,
      required this.room,
      required this.link,
      required this.id,
      required this.onDelete});

  @override
  _SubjectBlockState createState() => _SubjectBlockState();
}

class _SubjectBlockState extends State<SubjectBlock> {
  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () async {
          if (widget.link != "") {
            log(widget.link);
            final Uri url = Uri.parse(widget.link);
            _launchUrl(url);
          } else {
            log('Empty link');
          }
        },
        child: Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(5)),
            child: Row(
              children: [
                Expanded(flex: 3, child: Center(child: Text(widget.hour))),
                // make the subject name and room into a column
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(widget.subjName, textAlign: TextAlign.center),
                      Text(
                        widget.room,
                        style: const TextStyle(color: Colors.green),
                      ),
                      // Text("ID IS : ${widget.id}")
                    ],
                  ),
                ),
                Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            bool? confirmDelete = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Confirm Delete"),
                                content: Text(
                                    "Are you sure you want to delete the subject ${widget.subjName}"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false), // Cancel
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true), // Confirm
                                    child: const Text("Delete",
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );

                            if (confirmDelete == true) {
                              final db = DatabaseHelper();
                              await db.delete('subjects', int.parse(widget.id));
                              widget.onDelete(); // Trigger refresh
                            }
                          },
                        ),
                        IconButton(
                            // to be continued ....
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              // spawn a new screen to edit the subject
                            })
                      ],
                    )),
                Container()
              ],
            )),
      ),
    );
  }
}
