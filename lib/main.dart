import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mijia_flutter/api/client.dart';
import 'package:mijia_flutter/api/login.dart';
import 'package:mijia_flutter/widgets/DeviceWidget.dart';

final logger = Logger();
late MijiaClient client;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.level = Level.debug;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        fontFamily: Platform.isWindows ? "微软雅黑" : null
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Map authData = {};
  List<Widget> deviceWidgets = [];

  Future<void> _incrementCounter(BuildContext context) async {
    // var result = await MijiaLogin(context).loginByQrCode();
    // MijiaLogin(context).saveAuthData();
    // logger.d(result);
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Flex(
            direction: Axis.horizontal,
            children: [
              TextButton(
                onPressed: () => MijiaLogin.loginByQrCode(context),
                child: Text("扫码登录"),
              ),
              TextButton(
                onPressed: () => MijiaLogin.saveAuthData(),
                child: Text("保存登录信息"),
              ),
              TextButton(
                onPressed: () async {
                  authData = await MijiaLogin.loadAuthData();
                  client = MijiaClient(authData);
                },
                child: Text("加载登录信息"),
              ),
              TextButton(
                onPressed: () async {
                  final userInfo = await client.getUserInfo();
                  logger.d(userInfo);
                },
                child: Text("获取用户信息"),
              ),
              TextButton(
                onPressed: () async {
                  deviceWidgets.clear();
                  final deviceList = await client.getDeviceList();
                  final list = deviceList["result"]["list"];
                  for (final device in list) {
                    logger.d(device["did"]);
                    logger.d(device["model"]);
                    setState(() {
                      deviceWidgets.add(
                        DeviceWidget(
                          did: device["did"],
                          authData: authData,
                          model: device["model"],
                        ),
                      );
                    });
                  }
                },
                child: Text("获取全部设备列表"),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: deviceWidgets),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _incrementCounter(context),
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
