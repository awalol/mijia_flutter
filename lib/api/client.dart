import 'dart:convert';
import 'dart:io';

import '../main.dart';
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

  Future<Map> getDeviceInfo(String model) async {
    var result = await loadDeviceInfoCache(model);
    if (result.isNotEmpty) {
      return result;
    }
    logger.d("getDeviceInfoOnline");
    HttpClientRequest request = await client.getUrl(
      Uri.parse("https://home.miot-spec.com/spec/$model"),
    );
    HttpClientResponse response = await request.close();
    final responseData = await response.transform(utf8.decoder).join();
    var data = RegExp(r'data-page="(.*?)">')
        .allMatches(responseData)
        .first
        .group(1)
        .toString()
        .replaceAll("&quot;", '"')
        .replaceAll("&amp;", "&");
    final jsonData = jsonDecode(data);
    final product = jsonData["props"]["product"];
    result.addAll({
      "name": product["name"],
      "model": product["model"],
      "icon": product["icon_real"],
    });
    final props = <Map>[];
    final serviceDesc = {};
    for (final service in jsonData["props"]["spec"]["services"].values) {
      final siid = service["iid"];
      serviceDesc["$siid"] = service["description"];
      Map<String, dynamic> properties = service["properties"];
      for (final prop in properties.values) {
        props.add({
          "name": prop["name"],
          "desc": prop["desc_zh_cn"] ?? prop["desc"],
          "type": prop["format"],
          "unit": prop["unit"],
          "value-range": prop["value-range"],
          "value-list": prop["value-list"],
          "access": prop["access"],
          "method":{
            "siid": siid,
            "piid": prop["iid"],
          }
        });
      }
    }
    result["props"] = props;
    result["serviceDesc"] = serviceDesc;
    saveDeviceInfoCache(model, result);
    return result;
  }

  Future<Map> loadDeviceInfoCache(String model) async {
    var result = {};
    final cacheFile = File("${Directory.current.path}/config/$model.json");
    if (await cacheFile.exists()) {
      logger.d("getDeviceInfoByCache");
      result = jsonDecode(await cacheFile.readAsString());
    }
    return result;
  }

  Future<void> saveDeviceInfoCache(String model, Map data) async {
    final directory = Directory.current;
    Directory("${directory.path}/config").createSync();
    final cacheFile = File(
      "${directory.path}/config/$model.json",
    ).openWrite(mode: FileMode.write);
    final json = JsonEncoder.withIndent('  ').convert(data);
    cacheFile.write(json);
    cacheFile.close();
  }

  Future<Map> getProp(String did, int siid, int piid) {
    return post("/miotspec/prop/get", {
      "params": [
        {"did": did, "siid": siid, "piid": piid},
      ],
    });
  }

  Future<Map> setProp(String did, int siid, int piid, dynamic value) {
    return post("/miotspec/prop/set", {
      "params": [
        {"did": did, "siid": siid, "piid": piid, "value": value},
      ],
    });
  }
}
