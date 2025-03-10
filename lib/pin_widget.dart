import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinWidgetDemo extends StatefulWidget {
  const PinWidgetDemo({Key? key}) : super(key: key);

  @override
  State<PinWidgetDemo> createState() => _PinWidgetDemoState();
}

class _PinWidgetDemoState extends State<PinWidgetDemo> {
  // This must match the channel name in MainActivity
  static const _channel = MethodChannel('com.example.homewidget/widgetPinChannel');

  Future<void> _requestPinWidget() async {
    try {
      final bool? wasPinAttempted = await _channel.invokeMethod<bool>('pinWidget');
      // "wasPinAttempted" indicates if we could trigger the request
      // (not necessarily that it was successful),
      // because the user still must confirm.
      if (wasPinAttempted == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pin request sent. Please confirm!')),
        );
      } else {
        // Possibly show that it's not supported or an error occurred
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pin request not supported!')),
        );
      }
    } catch (e) {
      debugPrint('Error pinning widget: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pin Widget Demo'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _requestPinWidget,
          child: const Text('Pin Widget to Home Screen'),
        ),
      ),
    );
  }
}