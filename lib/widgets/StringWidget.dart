import 'package:flutter/material.dart';
import 'package:mijia_flutter/main.dart';

class StringWidget extends StatefulWidget {
  final String did;
  final Map prop;

  const StringWidget({super.key, required this.did, required this.prop});

  @override
  State<StatefulWidget> createState() => _StringWidgetState();
}

class _StringWidgetState extends State<StringWidget> {
  String _value = "";
  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    final method = widget.prop["method"];
    final propResult = await client.getProp(
      widget.did,
      method["siid"],
      method["piid"],
    );
    setState(() {
      _value = propResult["result"][0]["value"] as String;
    });
    logger.d(propResult);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(widget.prop["desc"], style: TextStyle(fontSize: 16)),
        Spacer(),
        Text(_value,style: TextStyle(fontSize: 16),)
      ],
    );
  }
}
