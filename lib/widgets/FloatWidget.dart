import 'package:flutter/cupertino.dart';

class FloatWidget extends StatefulWidget{
  final String did;
  final Map prop;
  const FloatWidget({super.key,required this.did,required this.prop});

  @override
  State<StatefulWidget> createState() => _FloatWidgetState();
}

class _FloatWidgetState extends State<FloatWidget>{
  @override
  Widget build(BuildContext context) {
    return(Text("hi"));
  }

}