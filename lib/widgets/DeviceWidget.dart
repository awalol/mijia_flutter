import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DeviceWidget extends StatefulWidget{
  final String did;

  const DeviceWidget({super.key,required this.did});

  @override
  State<StatefulWidget> createState() => _DeviceWidgetState();
}

class _DeviceWidgetState extends State<DeviceWidget>{
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const ListTile(
            leading: Icon(Icons.album),
            title: Text('The Enchanted Nightingale'),
            subtitle: Text('Music by Julie Gable. Lyrics by Sidney Stein.'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(
                child: const Text('BUY TICKETS'),
                onPressed: () {
                  /* ... */
                },
              ),
              const SizedBox(width: 8),
              TextButton(
                child: const Text('LISTEN'),
                onPressed: () {
                  /* ... */
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }
}