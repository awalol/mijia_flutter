import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import 'package:flutter/material.dart';
import 'package:mijia_flutter/api/client.dart';

import '../main.dart';
import '../utils/RandomUtil.dart';

class MijiaLogin {
  static var data = {};

  static Future<Map> loginByQrCode(BuildContext context) async {
    // 发起登录
    final client = Dio();
    // 使用Dio会出现 Unhandled Exception: DioException [unknown]: null 但是在其他的URL无法复现
    var request = await HttpClient().getUrl(
      Uri.parse(
        "https://account.xiaomi.com/pass/serviceLogin?sid=xiaomiio&_json=true",
      ),
    );
    request.headers.set(
      "User-Agent",
      "APP/com.xiaomi.mihome APPV/6.0.103 iosPassportSDK/3.9.0 iOS/14.4 miHSTS",
    );
    var result = jsonDecode(
      (await (await request.close()).transform(utf8.decoder).join()).substring(
        11,
      ),
    );
    logger.d("serviceLogin: $result");

    // 获取登录二维码
    var response = await client.get(
      "https://account.xiaomi.com/longPolling/loginUrl",
      queryParameters: {
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
      },
    );
    result = jsonDecode(response.data.toString().substring(11));
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
      response = await client.get(
        result["lp"],
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );
    } on DioException catch (e) {
      client.close();
      if (e.type == DioExceptionType.receiveTimeout) {
        logger.e("lp: 二维码超时 ${e.message}");
      }
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
    result = jsonDecode(response.data.toString().substring(11));
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

    // --------------------------------------------
    final n = "nonce=$nonce&$securityToken";
    final clientSign = Uri.encodeComponent(
      base64Encode(sha1.convert(utf8.encode(n)).bytes),
    );
    response = await client.get("$location&clientSign=$clientSign");
    data["userId"] = userId;
    data["securityToken"] = securityToken;
    data["deviceId"] = RandomUtil.random(16);
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
