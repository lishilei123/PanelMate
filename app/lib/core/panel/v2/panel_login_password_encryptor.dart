import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/asymmetric/api.dart' as pointycastle;

class PanelLoginPasswordEncryptor {
  const PanelLoginPasswordEncryptor._();

  static String encryptPassword(
    String password, {
    required String panelPublicKeyCookie,
    Random? random,
  }) {
    final secureRandom = random ?? Random.secure();
    final aesKey = _randomHex(16, secureRandom);
    final ivBytes = _randomBytes(16, secureRandom);
    final publicKey = encrypt.RSAKeyParser().parse(
      _decodePanelPublicKey(panelPublicKeyCookie),
    );

    final rsa = encrypt.Encrypter(
      encrypt.RSA(
        publicKey: publicKey as pointycastle.RSAPublicKey,
        encoding: encrypt.RSAEncoding.PKCS1,
      ),
    );
    final aes = encrypt.Encrypter(
      encrypt.AES(
        encrypt.Key.fromUtf8(aesKey),
        mode: encrypt.AESMode.cbc,
        padding: 'PKCS7',
      ),
    );
    final iv = encrypt.IV(Uint8List.fromList(ivBytes));

    return [
      rsa.encrypt(aesKey).base64,
      iv.base64,
      aes.encrypt(password, iv: iv).base64,
    ].join(':');
  }

  static String _decodePanelPublicKey(String cookieValue) {
    final decodedCookie = Uri.decodeComponent(
      cookieValue.trim().replaceAll('"', ''),
    );
    if (decodedCookie.startsWith('-----BEGIN')) {
      return decodedCookie;
    }
    return utf8.decode(base64.decode(decodedCookie));
  }

  static String _randomHex(int byteCount, Random random) {
    return _randomBytes(byteCount, random)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  static List<int> _randomBytes(int byteCount, Random random) {
    return List<int>.generate(byteCount, (_) => random.nextInt(256));
  }
}
