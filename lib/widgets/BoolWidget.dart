import 'package:flutter/material.dart';
import '../main.dart';

class BoolWidget extends StatefulWidget {
  final String did;
  final Map property;

  const BoolWidget({
    super.key,
    required this.did,
    required this.property,
  });

  @override
  State<StatefulWidget> createState() => _BoolWidgetState();
}

class _BoolWidgetState extends State<BoolWidget> {
  bool _isSwitched = false;
  static const TextStyle _propertyTextStyle = TextStyle(fontSize: 16);

  @override
  void initState() {
    super.initState();
    _initProperty();
  }

  void _initProperty() async {
    final method = widget.property["method"];
    final propertyResult = await client.getProp(
      widget.did,
      method["siid"],
      method["piid"],
    );
    logger.d(propertyResult);
    setState(() {
      _isSwitched = propertyResult["result"][0]["value"];
    });
  }

  Widget _buildSwitch() {
    final method = widget.property["method"];
    return Switch(
      value: _isSwitched,
      onChanged: (value) async {
        final result = await client.setProp(
          widget.did,
          method["siid"],
          method["piid"],
          value,
        );
        logger.d(result);
        if (result["result"][0]["code"] == 0) {
          setState(() {
            _isSwitched = value;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          widget.property["desc"],
          style: _propertyTextStyle,
        ),
        Spacer(),
        _buildSwitch(),
      ],
    );
  }
}