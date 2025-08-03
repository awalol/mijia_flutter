import 'package:flutter/material.dart';
import 'package:mijia_flutter/main.dart';

class FloatWidget extends StatefulWidget {
  final String did;
  final Map prop;

  const FloatWidget({super.key, required this.did, required this.prop});

  @override
  State<StatefulWidget> createState() => _FloatWidgetState();
}

class _FloatWidgetState extends State<FloatWidget> {
  double _value = 0;
  double _min = 0;
  double _max = 10;
  int _divisions = 10;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    final method = widget.prop["method"];
    final valueRange = widget.prop["value-range"];
    final propResult = await client.getProp(
      widget.did,
      method["siid"],
      method["piid"],
    );
    setState(() {
      _min = (valueRange[0] as num).toDouble();
      _max = (valueRange[1] as num).toDouble();
      _divisions = ((_max - _min) / valueRange[2] as num).toInt();
      _value = (propResult["result"][0]["value"] as num).toDouble();
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
        Container(
          padding: EdgeInsets.only(bottom: 1),
          child: Text(_value.toString(), style: TextStyle(fontSize: 16)),
        ),
        SizedBox(
          width: 300,
          child: Slider(
            value: _value,
            min: _min,
            max: _max,
            divisions: _divisions,
            label: _value.toString(),
            onChanged: (value) {
              if ((widget.prop["access"] as List).contains("write")) {
                setState(() {
                  _value = value;
                });
              }
            },
            onChangeEnd: (value) async {
              final method = widget.prop["method"];
              final result = await client.setProp(
                widget.did,
                method["siid"],
                method["piid"],
                value,
              );
              logger.d(result);
              if (result["result"][0]["code"] == 0) {
                setState(() {
                  _value = value;
                });
              }
            },
          ),
        ),
      ],
    );
  }
}
