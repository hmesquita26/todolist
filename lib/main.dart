import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
      debugShowCheckedModeBanner: false, title: 'Tasks', home: Mytodo()));
}

class Mytodo extends StatefulWidget {
  @override
  _MytodoState createState() => _MytodoState();
}

class _MytodoState extends State<Mytodo> {
  List _taskList = [];
  Map<String, dynamic> _lastRemoved = Map();
  int _lastRemovedPos;
  final _taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _taskList = json.decode(data);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task List'),
        backgroundColor: Colors.purple,
        centerTitle: true,
        elevation: 0.0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(10.0, 1.0, 10.0, 1.0),
            color: Colors.purple,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(25),
                          bottomLeft: Radius.circular(25),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(25),
                          bottomLeft: Radius.circular(25),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(25),
                          bottomLeft: Radius.circular(25),
                        ),
                      ),
                      labelText: 'New Task',
                      labelStyle: TextStyle(color: Colors.white),
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 18.0),
                    ),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: addTask,
                  child: Icon(Icons.add),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.purple,
                    padding: EdgeInsets.symmetric(vertical: 12.5),
                    side: BorderSide(
                      color: Colors.white70,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                      ),
                      side: BorderSide(color: Colors.white70),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
                child: Container(
                  color: Colors.purple,
                  child: _taskList.length != 0
                      ? ListView.builder(
                          padding: EdgeInsets.only(top: 10.0),
                          itemCount: _taskList.length,
                          itemBuilder: newBuildItem)
                      : Container(
                          height: double.infinity,
                          width: double.infinity,
                          color: Colors.purple,
                          child: Center(
                            child: Text(
                              'Nothing task added!',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                ),
                onRefresh: _refresh),
          ),
        ],
      ),
    );
  }

  Widget newBuildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: slideRightBackground(),
      secondaryBackground: slideLeftBackground(),
      child: InkWell(
        child: CheckboxListTile(
          tileColor:
              _taskList[index]['ok'] ? Colors.purple.shade400 : Colors.purple,
          title: _taskList[index]['ok']
              ? Text(
                  _taskList[index]['title'],
                  style: TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.lineThrough),
                )
              : Text(_taskList[index]['title'],
                  style: TextStyle(color: Colors.white)),
          value: _taskList[index]['ok'],
          secondary: CircleAvatar(
            child: Icon(_taskList[index]['ok'] ? Icons.check : Icons.error),
          ),
          onChanged: (change) {
            checkTask(index, change);
          },
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          final bool res = await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  content: Text(
                      'Are you sure want to delete \"${_taskList[index]['title']}\" ?'),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Cancel',
                          style: TextStyle(color: Colors.purple)),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.white,
                        // padding: EdgeInsets.symmetric(vertical: 12.5),
                        side: BorderSide(
                          color: Colors.purple,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(25.0)),
                          // side: BorderSide(color: Colors.purple),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _lastRemoved = Map.from(_taskList[index]);
                          _lastRemovedPos = index;
                          _taskList.removeAt(index);
                          _saveData();

                          final snack = SnackBar(
                            content:
                                Text('Task ${_lastRemoved['title']} removed.'),
                            action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () {
                                  setState(() {
                                    _taskList.insert(
                                        _lastRemovedPos, _lastRemoved);
                                    _saveData();
                                  });
                                }),
                            duration: Duration(seconds: 3),
                          );
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(snack);
                        });
                        Navigator.of(context).pop();
                      },
                      child: Text('Ok', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.purple,
                        // padding: EdgeInsets.symmetric(vertical: 12.5),
                        side: BorderSide(
                          color: Colors.purple,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(25.0)),
                        ),
                      ),
                    ),
                  ],
                );
              });
          return res;
        } else {
          return null;
        }
      },
    );
  }

  Widget slideRightBackground() {
    return Container(
      color: Colors.green,
      child: Align(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
            ),
            Icon(Icons.check, color: Colors.white),
            Text(
              'Done!',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              textAlign: TextAlign.left,
            ),
          ],
        ),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  Widget slideLeftBackground() {
    return Container(
      color: Colors.red,
      child: Align(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 20,
            ),
            Icon(Icons.delete, color: Colors.white),
            Text(
              'Delete!',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              textAlign: TextAlign.right,
            ),
            SizedBox(
              width: 20,
            ),
          ],
        ),
        alignment: Alignment.centerRight,
      ),
    );
  }

  void addTask() {
    setState(() {
      if (_taskController.text.isNotEmpty) {
        Map<String, dynamic> newTask = Map();
        newTask['title'] = _taskController.text;
        _taskController.text = '';
        newTask['ok'] = false;
        _taskList.add(newTask);
        _saveData();
      } else {
        final snack = SnackBar(
          content: Text('It\'s empty, please fiil with text!'),
          duration: Duration(seconds: 3),
        );
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(snack);
      }
    });
  }

  void checkTask(index, change) {
    setState(() {
      _taskList[index]['ok'] = change;
      _saveData();
    });
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  Future<File> _saveData() async {
    String data = json.encode(_taskList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _taskList.sort((a, b) {
        if (a['ok'] && !b['ok'])
          return 1;
        else if (!a['ok'] && b['ok'])
          return -1;
        else
          return 0;
      });
      _saveData();
    });
    return null;
  }
}
