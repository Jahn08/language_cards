import 'package:flutter/services.dart';

class ContextProvider {
  static const MethodChannel channel = MethodChannel('context_provider');

  ContextProvider._();

  static Future<bool> isStoragePermissionRequired() =>
      channel.invokeMethod('isStoragePermissionRequired');

  static Future<String> getDownloadDirPath() =>
      channel.invokeMethod('getDownloadsDirectoryPath');

  static Future<bool> isFileExtensionSupported(String extention) =>
      channel.invokeMethod('isFileExtensionSupported', {"ext": extention});

  static Future<bool> isEmailHtmlSupported() =>
      channel.invokeMethod('isEmailHtmlSupported');
}
