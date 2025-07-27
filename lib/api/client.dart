import 'dart:convert';
import 'dart:io';

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
    HttpClient client = HttpClient();
    HttpClientRequest request = await client.getUrl(
      Uri.parse(
        "https://account.xiaomi.com/pass2/profile/home?userId=$userId",
      ),
    );
    request.headers.set(
      "User-Agent",
      "APP/com.xiaomi.mihome APPV/6.0.103 iosPassportSDK/3.9.0 iOS/14.4 miHSTS",
    );
    // request.cookies.add(Cookie("PassportDeviceId",deviceId));
    request.cookies.add(Cookie("userId",userId.toString()));
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
}
