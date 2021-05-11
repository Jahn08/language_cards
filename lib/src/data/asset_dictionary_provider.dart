import 'dart:io' as io;
import 'dart:convert';
import 'package:flutter/material.dart';
import './asset_reader.dart';
import './dictionary_provider.dart';
import '../models/article.dart';

class AssetDictionaryProvider extends DictionaryProvider {

	static final Map<String, Map<String, dynamic>> _cache = {};

	static Map<String, String> _dicNamesCache;

	final AssetReader _reader;

	AssetDictionaryProvider(BuildContext context):
		_reader = new AssetReader(context);

	@override
	void dispose() {}

	@override
	Future<AssetArticle> lookUp(String langParam, String text) async {
		final key = text.toLowerCase();
		var dic = _cache[langParam];
		if (dic == null) {
			dic = await _getDictionaryByLang(langParam);
			if (dic == null)
				return new AssetArticle(key, []);

			_cache[langParam] = dic;
		}

		final json = dic[key];
		return new AssetArticle(key, json);
	}

	Future<Map<String, dynamic>> _getDictionaryByLang(String langParam) async {
		final dicFileName = (await _getDicNames())[langParam];
		if (dicFileName == null)
			return null;

		final compressedData = await _reader.load(['dictionaries', dicFileName]);

		final content = Utf8Codec().decode(io.gzip.decode(compressedData.buffer.asInt8List()));
		return json.decode(content);
	}

	Future<Map<String, String>> _getDicNames() async {
		if (_dicNamesCache == null) {
			final filePaths = await _reader.listAssetNames('dictionaries');
			_dicNamesCache = new Map<String, String>.fromIterable(filePaths, 
				key: (p) =>	p.split('.').first, value: (p) => p);
		}

		return _dicNamesCache;
	}

  	@override
  	Future<List<String>> getAcceptedLanguages() async => 
		(await _getDicNames()).keys.toList();

	@override
	AssetArticle get defaultArticle => new AssetArticle('', []);
}
