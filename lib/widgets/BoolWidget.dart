import 'package:flutter/material.dart';

import '../main.dart';

class BoolWidget extends StatefulWidget{
  final String did;
  final Map prop;
  const BoolWidget({super.key,required this.did,required this.prop});

  @override
  State<StatefulWidget> createState() => _BoolWidgetState();
}

class _BoolWidgetState extends State<BoolWidget>{
  bool _isSwitched = false;

  @override
  void initState() {
    super.initState();
    _initProp();
  }

  void _initProp() async{
    final currentProp = await client.getProp(widget.did, widget.prop["method"]["siid"], widget.prop["method"]["piid"]);
    logger.d(currentProp);
    setState(() {
      _isSwitched = currentProp["result"][0]["value"];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(widget.prop["desc"], style: TextStyle(fontSize: 16)),
        Spacer(),
        Switch(
          value: _isSwitched,
          onChanged: (value) async{

            final result = await client.setProp(widget.did, widget.prop["method"]["siid"], widget.prop["method"]["piid"], value);
            logger.d(result);
            if(result["result"][0]["code"] == 0){
              setState(() {
                _isSwitched = value;
              });
            }
          },
        ),
      ],
    );
  }

}