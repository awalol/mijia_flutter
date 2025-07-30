import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

String random(int count) {
  const String chars =
      '1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  final Random random = Random();
  final StringBuffer buffer = StringBuffer();

  for (int i = 0; i < count; i++) {
    buffer.write(chars[random.nextInt(chars.length)]);
  }

  return buffer.toString();
}

String generateNonce() {
  return random(16);
}

String generateSignedNonce(String secret, String nonce) {
  final secretDecode = base64Decode(secret);
  final nonceDecode = base64Decode(nonce);
  final bytes = <int>[];
  bytes.addAll(secretDecode);
  bytes.addAll(nonceDecode);
  final result = base64Encode(sha256.convert(bytes).bytes);
  return result;
}

String generateSignature(
  String url,
  String signedNonce,
  String nonce,
  String data,
) {
  final sign = "$url&$signedNonce&$nonce&data=$data";
  final hmac = Hmac(sha256, base64Decode(signedNonce));
  final result = base64Encode(hmac.convert(utf8.encode(sign)).bytes);
  return result;
}
