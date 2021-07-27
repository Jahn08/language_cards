import 'package:flutter/services.dart';

class IOContextProvider {
	static const MethodChannel channel = const MethodChannel('io_context_provider');

	IOContextProvider._();

	static Future<bool> isStoragePermissionRequired() => channel.invokeMethod('isStoragePermissionRequired');

	static Future<String> getDownloadDirPath() => channel.invokeMethod('getDownloadsDirectoryPath');
		
	static Future<bool> isFileExtensionSupported(String extention) => 
		channel.invokeMethod('isFileExtensionSupported', { "ext": extention });
}
