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

const EdgeInsets _horizontalPadding = EdgeInsets.only(left: 16, right: 16);

class _DeviceWidgetState extends State<DeviceWidget> {
  Map<dynamic, dynamic> deviceInfoMap = {};
  final List<bool> _isPanelOpen = <bool>[];

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  void _loadDeviceInfo() async {
    final info = await client.getDeviceInfo(widget.model);
    setState(() {
      deviceInfoMap = info;
      // 确保panel展开状态与面板数量同步
      _isPanelOpen.clear();
      if (deviceInfoMap["serviceDesc"] != null) {
        _isPanelOpen.addAll(
            List<bool>.filled(deviceInfoMap["serviceDesc"].length, false));
      }
    });
  }

  List<Widget> _buildPropertyWidgets() {
    final List props = deviceInfoMap["props"] ?? [];
    return props.map<Widget>((prop) {
      switch (prop["type"]) {
        case "bool":
          return _buildBoolPropertyWidget(prop);
        default:
          return _buildDefaultPropertyWidget(prop);
      }
    }).toList();
  }

  Widget _buildBoolPropertyWidget(Map<String, dynamic> prop) {
    return Container(
      padding: _horizontalPadding,
      child: BoolWidget(did: widget.did, prop: prop),
    );
  }

  Widget _buildDefaultPropertyWidget(Map<String, dynamic> prop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: _horizontalPadding,
          child: Text(prop["name"], style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  List<ExpansionPanel> _buildExpansionPanels() {
    final serviceDesc = deviceInfoMap["serviceDesc"] ?? {};
    int i = 0;
    return serviceDesc.entries.map<ExpansionPanel>((entry) {
      final value = entry.value;
      return ExpansionPanel(
        headerBuilder: (context, isOpen) =>
            ListTile(title: Text(value)),
        body: Column(children: _buildPropertyWidgets()),
        isExpanded: _isPanelOpen[i++],
      );
    }).toList();
  }

  Widget _buildDeviceTitle() {
    final iconUrl = deviceInfoMap["icon"];
    return ListTile(
      leading: iconUrl == null
          ? Icon(Icons.developer_board)
          : Image.network(iconUrl),
      title: Text(
        deviceInfoMap["name"] ?? "正在加载...",
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: <Widget>[
          _buildDeviceTitle(),
          Container(
            padding: _horizontalPadding,
            child: ExpansionPanelList(
              children: _buildExpansionPanels(),
              expansionCallback: (index, isExpanded) {
                setState(() {
                  _isPanelOpen[index] = isExpanded;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
