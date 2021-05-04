import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:local_auth/auth_strings.dart';
import 'package:local_auth/local_auth.dart';

abstract class AuthService {

  /// 授权，返回[true]代表授权成功
  Future<bool> authenticate();

  /// 取消授权，返回[true]代表成功
  Future<bool> stopAuthenticate();

}

class AuthServiceImpl implements AuthService {
  final _auth = LocalAuthentication();

  bool isAuthenticated = false;

  final androidString = const AndroidAuthMessages(
      cancelButton: "取消",
      goToSettingsButton: "设置",
      goToSettingsDescription: "请设置你的指纹",
      biometricRequiredTitle: "请验证指纹",
      biometricNotRecognized: "指纹识别失败，请重新验证"
  );

  final iosString = const IOSAuthMessages(
      cancelButton: "取消",
      goToSettingsButton: "设置",
      goToSettingsDescription: "请设置你的指纹",
      lockOut: "指纹识别失败，请重新验证"
  );

  @override
  Future<bool> authenticate() async {
    try {
      List<BiometricType> availableBiometrics =
      await _auth.getAvailableBiometrics();

      if (Platform.isIOS) {
        if (availableBiometrics.contains(BiometricType.face)) {
          // Face ID.
        } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
          // Touch ID.
        }
      }
      isAuthenticated = await _auth.authenticate(
          localizedReason: '授权以访问账号',
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: true,
          androidAuthStrings: androidString,
          iOSAuthStrings: iosString
      );
      return isAuthenticated;
    } on PlatformException catch (e) {
      print(e);
    }
    return false;
  }

  @override
  Future<bool> stopAuthenticate() async {
    return await _auth.stopAuthentication();
  }
}