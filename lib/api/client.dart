import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:dio/dio.dart';

class MijiaClient {
  late String deviceId;
  late int userId;
  late String serviceToken;
  late String securityToken;
  late String passToken;
  late Dio client;

  MijiaClient(Map authData) {
    deviceId = authData["deviceId"];
    userId = authData["userId"];
    serviceToken = authData["serviceToken"];
    securityToken = authData["securityToken"];
    passToken = authData["passToken"];

    client = Dio(
      BaseOptions(
        baseUrl: "https://api.io.mi.com/app",
        headers: {
          "User-Agent":
              "APP/com.xiaomi.mihome APPV/6.0.103 iosPassportSDK/3.9.0 iOS/14.4 miHSTS",
          "x-xiaomi-protocal-flag-cli": "PROTOCAL-HTTP2",
          "Cookie":
              "PassportDeviceId=$deviceId;userId=$userId;serviceToken=$serviceToken;",
        },
      ),
    );
  }

  Future<Map> getUserInfo() async {
    final response = await client.getUri(
      Uri.parse(
        "https://account.xiaomi.com/pass2/profile/home?userId=2300736747",
      ),
    );
    try {
      var result = jsonDecode(response.data.toString().substring(11));
      return result["data"];
    } catch (e) {
      throw Exception("登录过期");
    }
  }
}
