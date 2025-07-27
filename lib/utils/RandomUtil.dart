import 'dart:math';

class RandomUtil{
  static String random(int count) {
    const String chars =
        '1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final Random random = Random();
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < count; i++) {
      buffer.write(chars[random.nextInt(chars.length)]);
    }

    return buffer.toString();
  }
}