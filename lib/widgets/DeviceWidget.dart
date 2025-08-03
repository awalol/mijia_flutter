import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mijia_flutter/main.dart';
import 'package:mijia_flutter/widgets/BoolWidget.dart';
import 'package:mijia_flutter/widgets/UIntWidget.dart';

import 'FloatWidget.dart';
import 'StringWidget.dart';

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
          List<bool>.filled(deviceInfoMap["serviceDesc"].length, false),
        );
      }
    });
  }

  List<Widget> _buildPropertyWidgets(int siid) {
    List props = deviceInfoMap["props"] ?? [];
    final filter = props.where(
      (e) =>
          (e["method"]["siid"] == siid) && ((e["access"] as List).isNotEmpty),
    );
    return filter.map<Widget>((prop) {
      Widget child = _buildDefaultPropertyWidget(prop);
      switch (prop["type"]) {
        case "bool":
          child = _buildBoolPropertyWidget(prop);
          break;
        case "float":
          child = _buildFloatPropertyWidget(prop);
          break;
        case "uint8":
          if(prop["value-list"] != null){
            child = _buildUIntPropertyWidget(prop);
          }else if(prop["value-range"] != null){
            child = _buildFloatPropertyWidget(prop);
          }
          break;
        case "string":
          child = _buildStringPropertyWidget(prop);
      }
      return Column(children: [child, Divider()]);
    }).toList();
  }

  Widget _buildBoolPropertyWidget(Map prop) {
    return Container(
      padding: _horizontalPadding,
      child: BoolWidget(did: widget.did, property: prop),
    );
  }

  Widget _buildFloatPropertyWidget(Map prop) {
    return Container(
      padding: _horizontalPadding,
      child: FloatWidget(did: widget.did, prop: prop),
    );
  }

  Widget _buildUIntPropertyWidget(Map prop) {
    return Container(
      padding: _horizontalPadding,
      child: UIntWidget(did: widget.did, prop: prop),
    );
  }

  Widget _buildStringPropertyWidget(Map prop) {
    return Container(
      padding: _horizontalPadding,
      child: StringWidget(did: widget.did, prop: prop),
    );
  }

  Widget _buildDefaultPropertyWidget(Map prop) {
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
        headerBuilder: (context, isOpen) => ListTile(title: Text(value)),
        body: Column(children: _buildPropertyWidgets(int.parse(entry.key))),
        isExpanded: _isPanelOpen[i++],
      );
    }).toList();
  }

  Widget _buildDeviceTitle() {
    final iconUrl = deviceInfoMap["icon"];
    return ListTile(
      leading: iconUrl == null
          ? Icon(Icons.developer_board)
          : CachedNetworkImage(
              imageUrl: iconUrl,
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => Icon(Icons.developer_board),
            ),
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
