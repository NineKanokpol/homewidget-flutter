import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:homewidget/services/alram_service.dart';

class FullScreenCustom extends StatefulWidget {
  final String? payload; // Expecting payload to contain the player ID

  FullScreenCustom({Key? key, this.payload}) : super(key: key);

  @override
  State<FullScreenCustom> createState() => _FullScreenCustomState();
}

class _FullScreenCustomState extends State<FullScreenCustom> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.alarm_rounded, size: 100, color: Colors.white),
            Container(
              margin: EdgeInsets.only(top: 24,bottom: 24),
              child: Text(
                'ถึงเวลาละหมาด',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
            CupertinoButton(
              color: Colors.red,
              child: const Text("หยุดการแจ้งเตือน",style: TextStyle(color: Colors.white,fontSize: 20),),
              onPressed: () async {
                await AlarmService().stopAlarm();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}