import 'package:flutter_test/flutter_test.dart';
import 'package:piec/core/crypto/e2ee_engine.dart';
import 'package:piec/core/models/avatar_config.dart';

void main() {
  test('E2EE Cryptographic Engine encrypts and decrypts correctly', () {
    final crypto = E2EEEngine();
    const plainText = 'Hello Cyber World! 🚀';
    const userA = 'user_alex';
    const userB = 'user_sophia';

    final enc = crypto.encryptMessage(
      plainText: plainText,
      senderId: userA,
      receiverId: userB,
    );

    expect(enc['cipherText'], isNotEmpty);
    expect(enc['iv'], isNotEmpty);
    expect(enc['cipherText'], isNot(equals(plainText)));

    final decrypted = crypto.decryptMessage(
      cipherText: enc['cipherText']!,
      ivBase64: enc['iv']!,
      senderId: userA,
      receiverId: userB,
    );

    expect(decrypted, equals(plainText));
  });

  test('E2EE Safety Fingerprint generates 12-digit code', () {
    final crypto = E2EEEngine();
    final fp = crypto.generateSafetyFingerprint('user_123', 'user_456');
    expect(fp.replaceAll(' ', '').length, equals(12));
  });

  test('AvatarConfig 3D serialization and copyWith', () {
    const config = AvatarConfig(
      hairStyle: HairStyle.cyberPunkFade,
      accessory: AvatarAccessory.studioHeadphonesLed,
      irisColor: IrisColor.cyberCyan,
      auraEffect: AvatarAuraEffect.cyberSparks,
    );

    final jsonMap = config.toMap();
    final restored = AvatarConfig.fromMap(jsonMap);

    expect(restored.hairStyle, equals(HairStyle.cyberPunkFade));
    expect(restored.accessory, equals(AvatarAccessory.studioHeadphonesLed));
    expect(restored.irisColor, equals(IrisColor.cyberCyan));
    expect(restored.auraEffect, equals(AvatarAuraEffect.cyberSparks));
  });
}
