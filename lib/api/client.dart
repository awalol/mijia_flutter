import 'dart:convert';
import 'dart:io';

import '../utils.dart';

class MijiaClient {
  late String deviceId;
  late int userId;
  late String serviceToken;
  late String securityToken;
  late String passToken;
  late HttpClient client = HttpClient();

  MijiaClient(Map authData) {
    deviceId = authData["deviceId"];
    userId = authData["userId"];
    serviceToken = authData["serviceToken"];
    securityToken = authData["securityToken"];
    passToken = authData["passToken"];
  }

  Future<Map> getUserInfo() async {
    HttpClientRequest request = await client.getUrl(
      Uri.parse("https://account.xiaomi.com/pass2/profile/home?userId=$userId"),
    );
    request.headers.set(
      "User-Agent",
      "APP/com.xiaomi.mihome APPV/6.0.103 iosPassportSDK/3.9.0 iOS/14.4 miHSTS",
    );
    // request.cookies.add(Cookie("PassportDeviceId",deviceId));
    request.cookies.add(Cookie("userId", userId.toString()));
    // request.cookies.add(Cookie("serviceToken",serviceToken));
    request.cookies.add(Cookie("passToken", passToken));
    HttpClientResponse response = await request.close();
    try {
      var result = jsonDecode(
        (await response.transform(utf8.decoder).join()).substring(11),
      );
      return result["data"];
    } catch (e) {
      throw Exception("登录过期");
    }
  }

  Future<Map> post(String uri, Map mapData) async {
    final jsonData = jsonEncode(mapData);
    final nonce = generateNonce();
    final signedNonce = generateSignedNonce(securityToken, nonce);
    final signature = generateSignature(uri, signedNonce, nonce, jsonData);

    Map<String, String> formBody = {
      "_nonce": nonce,
      "data": jsonData,
      "signature": signature,
    };

    final body = formBody.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');

    HttpClientRequest request = await client.postUrl(
      Uri.parse("https://api.io.mi.com/app$uri"),
    );
    request.headers.set(
      "User-Agent",
      "APP/com.xiaomi.mihome APPV/6.0.103 iosPassportSDK/3.9.0 iOS/14.4 miHSTS",
    );
    request.headers.set("x-xiaomi-protocal-flag-cli", "PROTOCAL-HTTP2");
    request.headers.contentType = ContentType.parse(
      "application/x-www-form-urlencoded",
    );
    request.cookies.add(Cookie("PassportDeviceId", deviceId));
    request.cookies.add(Cookie("userId", "$userId"));
    request.cookies.add(Cookie("serviceToken", serviceToken));
    request.write(body);
    HttpClientResponse response = await request.close();
    return jsonDecode(await response.transform(utf8.decoder).join());
  }

  Future<Map> getDeviceList() {
    return post("/home/device_list", {
      "getVirtualModel": false,
      "getHuamiDevices": 0,
    });
  }

  Future<void> getDeviceInfo(String model) async {
    HttpClientRequest request = await client.getUrl(
      Uri.parse("https://home.miot-spec.com/spec/lumi.acpartner.mcn02")
    );
    request.headers.contentType = ContentType.json;
    
  }
}
