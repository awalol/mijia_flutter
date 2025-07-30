import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../utils.dart';

class MijiaLogin {
  static var data = {};

  static Future<Map> loginByQrCode(BuildContext context) async {
    // 发起登录
    final client = HttpClient();
    client.userAgent = "APP/com.xiaomi.mihome APPV/6.0.103 iosPassportSDK/3.9.0 iOS/14.4 miHSTS";
    // 使用Dio会出现 Unhandled Exception: DioException [unknown]: null 但是在其他的URL无法复现
    var request = await client.getUrl(
      Uri.parse(
        "https://account.xiaomi.com/pass/serviceLogin?sid=xiaomiio&_json=true",
      ),
    );
    var response = await request.close();
    var result = jsonDecode(
      (await (response).transform(utf8.decoder).join()).substring(11),
    );
    logger.d("serviceLogin: $result");

    // 获取登录二维码
    final params = {
      '_qrsize': "360",
      'qs': result["qs"],
      'bizDeviceType': '',
      'callback': result['callback'],
      '_json': 'true',
      'theme': '',
      'sid': 'xiaomiio',
      'needTheme': 'false',
      'showActiveX': 'false',
      'serviceParam':
          Uri.parse(result["location"]).queryParameters["serviceParam"] ?? '',
      '_local': 'zh_CN',
      '_sign': result['_sign'],
      '_dc': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    request = await client.getUrl(
      Uri.parse(
        "https://account.xiaomi.com/longPolling/loginUrl",
      ).replace(queryParameters: params),
    );
    response = await request.close();
    result = jsonDecode(
      (await (response).transform(utf8.decoder).join()).substring(11),
    );
    logger.d("loginUrl: $result");

    // 显示二维码
    final qrUrl = result["qr"].toString();
    if (!context.mounted) {
      throw Exception("content unmount");
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("扫码登录"),
        content: SizedBox(
          width: 360,
          height: 360,
          child: qrUrl.isNotEmpty
              ? Image.network(qrUrl)
              : const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("二维码获取失败"),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              client.close();
              Navigator.of(context).pop();
            },
            child: Text("取消"),
          ),
        ],
      ),
    );

    // 等待登录结果
    try {
      request = await client.getUrl(Uri.parse(result["lp"]));
      response = await request.close().timeout(Duration(seconds: 60));
    } on TimeoutException catch (e) {
      client.close();
      logger.e("lp: 二维码超时 ${e.message}");
      rethrow;
    }
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    if (response.statusCode != 200) {
      client.close();
      logger.e("lp: ${response.statusCode}");
      throw Exception("lp: 用户取消 ${response.statusCode}");
    }
    result = jsonDecode(
      (await (response).transform(utf8.decoder).join()).substring(11),
    );
    logger.d("lp: $result");
    if (result["code"] != 0) {
      final code = data["code"] = result["code"];
      final message = data["message"] = result["desc"];
      client.close();
      throw Exception("登录失败 $code $message");
    }
    final nonce = result["nonce"];
    final location = result["location"];
    final userId = result["userId"];
    final securityToken = result["ssecurity"];
    final passToken = result["passToken"];
    final cUserId = result["cUserId"];

    // // 神奇小米，无法正常解析Set-Cookie，需手动拼接
    // final setCookies = response.headers['set-cookie'];
    // List<Cookie> cookies = [];
    // var stringBuilder = "";
    // if(setCookies != null){
    //   for(var i = 0;i < setCookies.length;i++){
    //     if(i % 2 == 1){
    //       cookies.add(Cookie.fromSetCookieValue("$stringBuilder ${setCookies[i]}"));
    //       stringBuilder = "";
    //     }else{
    //       stringBuilder += setCookies[i];
    //     }
    //   }
    // }

    // --------------------------------------------
    final n = "nonce=$nonce&$securityToken";
    final clientSign = Uri.encodeComponent(
      base64Encode(sha1.convert(utf8.encode(n)).bytes),
    );
    logger.d("$location&clientSign=$clientSign");
    request = await client.getUrl(
      Uri.parse("$location&clientSign=$clientSign"),
    );
    response = await request.close();

    final setCookies = response.headers['set-cookie'];
    if(setCookies == null){
      throw Exception("serviceToken fail");
    }
    for(var setCookie in setCookies){
      final cookie = Cookie.fromSetCookieValue(setCookie);
      data[cookie.name] = cookie.value;
    }
    data["userId"] = userId;
    data["securityToken"] = securityToken;
    data["deviceId"] = random(16);
    data["passToken"] = passToken;
    data["cUserId"] = cUserId;
    client.close();
    saveAuthData();
    return data;
  }

  static void saveAuthData() {
    final directory = Directory.current;
    Directory("${directory.path}/config").createSync();
    final configFile = File(
      "${directory.path}/config/auth.json",
    ).openWrite(mode: FileMode.write);
    final json = JsonEncoder.withIndent('  ').convert(data);
    configFile.write(json);
    configFile.close();
  }

  static Future<Map> loadAuthData() async {
    final directory = Directory.current;
    final configFile = await File(
      "${directory.path}/config/auth.json",
    ).readAsString();
    logger.d("loadAuthData: $configFile");
    data = jsonDecode(configFile);
    return data;
  }
}
