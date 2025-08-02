import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mijia_flutter/main.dart';
import 'package:mijia_flutter/widgets/BoolWidget.dart';

class DeviceWidget extends StatefulWidget {
  final String did;
  final Map authData;
  final String model;

  const DeviceWidget({
    super.key,
    required this.did,
    required this.authData,
    required this.model,
  });

  @override
  State<StatefulWidget> createState() => _DeviceWidgetState();
}

class _DeviceWidgetState extends State<DeviceWidget> {
  Map deviceInfo = {};
  final List<bool> _isOpen = <bool>[];

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  void _loadDeviceInfo() async {
    final info = await client.getDeviceInfo(widget.model);
    setState(() {
      deviceInfo = info;
    });
  }

  List<Widget> _getW() {
    List<Widget> widgets = [];
    for (final prop in deviceInfo["props"]) {
      switch (prop["type"]) {
        case "bool":
          widgets.add(
            Container(
              padding: EdgeInsets.only(left: 16, right: 16),
              child: BoolWidget(did: widget.did, prop: prop),
            ),
          );
        default:
          widgets.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.only(left: 16, right: 16),
                  child: Text(prop["name"], style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          );
      }
    }
    return widgets;
  }

  List<ExpansionPanel> _e() {
    List<ExpansionPanel> ep = [];
    var i = 0;
    deviceInfo["serviceDesc"]?.forEach((key, value) {
      _isOpen.add(false);
      ep.add(
        ExpansionPanel(
          headerBuilder: (context, isOpen) {
            return ListTile(title: Text(value));
          },
          body: Column(children: _getW()),
          isExpanded: _isOpen[i++],
        ),
      );
    });
    return ep;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: <Widget>[
          ListTile(
            leading: deviceInfo["icon"] == null
                ? Icon(Icons.developer_board)
                : Image.network(deviceInfo["icon"]),
            title: Text(
              deviceInfo["name"] ?? "正在加载...",
              style: TextStyle(fontSize: 18),
            ),
            // subtitle: Text('Music by Julie Gable. Lyrics by Sidney Stein.'),
          ),
          Container(
            padding: EdgeInsets.only(left: 16, right: 16),
            child: ExpansionPanelList(
              children: [..._e()],
              expansionCallback: (i, isExpanded) {
                setState(() {
                  _isOpen[i] = isExpanded;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
