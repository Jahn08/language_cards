import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import '../models/article.dart';
import './asset_reader.dart';
import './dictionary_provider.dart';

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
		
		final dic = await _getCachedDictionary(langParam);
		if (dic == null)
			return new AssetArticle(key, []);

		final json = dic[key];
		return new AssetArticle(key, (json as List<dynamic>)?.cast<Map<String, dynamic>>());
	}

	Future<Map<String, dynamic>> _getCachedDictionary(String langParam) async {
		var dic = _cache[langParam];
		if (dic == null) {
			dic = await _getDictionaryByLang(langParam);
			if (dic != null)
				_cache[langParam] = dic;
		}

		return dic;
	}

	Future<Map<String, dynamic>> _getDictionaryByLang(String langParam) async {
		final dicFileName = (await _getDicNames())[langParam];
		if (dicFileName == null)
			return null;

		final compressedData = await _reader.load(['dictionaries', dicFileName]);

		final content = const Utf8Codec().decode(io.gzip.decode(compressedData.buffer.asInt8List()));
		return json.decode(content) as Map<String, dynamic>;
	}

	Future<Map<String, String>> _getDicNames() async {
		if (_dicNamesCache == null) {
			final filePaths = await _reader.listAssetNames('dictionaries');
			_dicNamesCache = <String, String>{
				for (final p in filePaths)
					p.split('.').first: p
			};
		}

		return _dicNamesCache;
	}
	
	@override
	Future<Iterable<String>> searchForLemmas(String langParam, String text) async {
		final dic = await _getCachedDictionary(langParam);
		if (dic == null)
			return [];

		final key = text.toLowerCase();
		return dic.keys.where((k) => k.startsWith(key));
	}

  	@override
  	Future<List<String>> getAcceptedLanguages() async => 
		(await _getDicNames()).keys.toList();
}
