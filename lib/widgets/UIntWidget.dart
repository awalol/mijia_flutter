import 'package:flutter/material.dart';
import 'package:mijia_flutter/main.dart';

class UIntWidget extends StatefulWidget {
  final String did;
  final Map prop;

  const UIntWidget({super.key, required this.did, required this.prop});

  @override
  State<StatefulWidget> createState() => _UIntWidgetState();
}

class _UIntWidgetState extends State<UIntWidget> {
  int _selected = 0;

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
      _selected = (propResult["result"][0]["value"] as num).toInt();
    });
    logger.d(propResult);
  }

  List<ButtonSegment> _buildButton() {
    List valueList =
        widget.prop["value-list"] ??
        [
          {"value": 0, "description": "Loading"},
        ];
    return valueList.map<ButtonSegment>((value) {
      return ButtonSegment(
        value: value["value"],
        label: Text(value["desc_zh_cn"] ?? value["description"]),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(widget.prop["desc"], style: TextStyle(fontSize: 16)),
        Spacer(),
        SegmentedButton(
          segments: _buildButton(),
          selected: {_selected},
          onSelectionChanged: (value) async {
            if (!(widget.prop["access"] as List).contains("write")) {
              return;
            }
            final method = widget.prop["method"];
            final result = await client.setProp(
              widget.did,
              method["siid"],
              method["piid"],
              value.first,
            );
            logger.d(result);
            if (result["result"][0]["code"] == 0) {
              setState(() {
                _selected = (value as num).toInt();
              });
            }
          },
        ),
      ],
    );
  }
}
