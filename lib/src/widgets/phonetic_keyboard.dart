import 'package:flutter/material.dart';
import 'package:language_cards/src/models/language.dart';
import './input_keyboard.dart';

class _EnglishPhoneticKeyboard extends InputKeyboard {
    static const phonetic_symbols = const <String>[
        'ʌ', 'ɑ:', 'æ', 'e', 'ə', 'ɛ', 'ɜ:ʳ', 'ɪ', 'i:', 'ɒ', 'ɔ:', 'ʊ', 
		'u:', 'aɪ', 'aʊ', 'eɪ', 'oʊ', 'ɔɪ', 'eəʳ', 'ɪəʳ', 'ʊəʳ', 'b', 'd', 
		'f', 'g', 'h', 'j', 'k', 'l', 'm', 'n', 'ŋ', 'p', 'r', 's', 't', 
        'tʃ', 'θ', 'ð', 'v', 'w', 'z', 'ʒ', 'dʒ', 'ˈ', 'ˌ', '.'
    ];

    _EnglishPhoneticKeyboard(String initialValue, { Key key }): 
        super(phonetic_symbols, 15, key: key, initialValue: initialValue);
}

class _FrenchPhoneticKeyboard extends InputKeyboard {
    static const phonetic_symbols = const <String>[
        'a', 'ɑ', 'ɑ̃', 'ə', 'œ̃', 'e', 'ɛ', 'ɛː', 'ɛ̃', 'i', 'o', 'ɔ̃', 'ɔ', 'u', 
		'y', 'ø', 'œ', 'b', 'd', 'dʒ', 'f', 'g', 'j', 'k', 'l', 'm', 'n', 'ŋ', 'ɲ',   
		'p', 'ʁ', 's', 'ʃ', 't', 'tʃ', 'v', 'w', 'x', 'z', 'ʒ', 'ɥ', '.', '‿'
    ];

    _FrenchPhoneticKeyboard(String initialValue, { Key key }): 
        super(phonetic_symbols, 15, key: key, initialValue: initialValue);
}

class _SpanishPhoneticKeyboard extends InputKeyboard {
    static const phonetic_symbols = const <String>[
		'a', 'e', 'ɛ', 'i', 'o', 'u', 'ɣ', 'ʎ',  'ʝ', 'ɟ',   
		'b', 'd', 'f', 'g', 'j', 'ɟʝ', 'k', 'l', 'm', 'ɱ', 'n', 
		'ŋ', 'ɲ', 'p', 'r', 'ɾ', 's', 'ʃ', 't', 'ts', 'tʃ', 
		'v', 'w', 'x', 'z', 'β', 'ð', 'θ', 'ˈ', '.'
    ];

    _SpanishPhoneticKeyboard(String initialValue, { Key key }): 
        super(phonetic_symbols, 15, key: key, initialValue: initialValue);
}

class _ItalianPhoneticKeyboard extends InputKeyboard {
    static const phonetic_symbols = const <String>[
		'a', 'e', 'i', 'o', 'ɔ', 'ø', 'u', 'ɛ', 'y', 'ʎ', 'b', 'd', 
		'dz', 'dʒ', 'f', 'g', 'h', 'j', 'k', 'l', 'm', 'ɱ', 'n', 
		'ŋ', 'ɲ', 'p', 'r', 's', 'ʃ', 't', 'ts', 'tʃ', 'v', 'w', 
		'x', 'z', 'ʒ', 'θ', 'ˈ', 'ˌ', '.', ':'
    ];

    _ItalianPhoneticKeyboard(String initialValue, { Key key }): 
        super(phonetic_symbols, 15, key: key, initialValue: initialValue);
}

class _GermanPhoneticKeyboard extends InputKeyboard {
    static const phonetic_symbols = const <String>[
		'a', 'ã', 'ɐ', 'ɐ̯', 'e', 'ɛ', 'ɛ̃', 'ə', 'ɪ', 'i', 'i̯', 'o', 'õ', 'o̯', 'ɔ', 
		'œ', 'œ̃', 'ø', 'ʊ', 'u', 'u̯', 'ʏ', 'y', 'y̑', 'aɪ', 'aʊ', 'ɔʏ', 'ər',   
		'ɛɪ', 'ɔʊ', 'b', 'ç', 'd', 'dʒ', 'f', 'g', 'h', 'j', 'k', 'l', 'l̩', 
		'm', 'm̩', 'n', 'n̩', 'ŋ', 'p', 'pf', 'r', 'ʁ', 'ɹ', 's', 'ʃ', 
		't', 'ts', 'tʃ', 'v', 'x', 'z', 'ʒ', 'ð', 'θ', ':', 'ˈ', 'ˌ'
    ];

    _GermanPhoneticKeyboard(String initialValue, { Key key }): 
        super(phonetic_symbols, 15, key: key, initialValue: initialValue);
}

class _RussianPhoneticKeyboard extends InputKeyboard {
    static const phonetic_symbols = const <String>[
		'a', 'æ', 'ɐ', 'ə', 'ɛ', 'e', 'ɨ', 'i', 'ɪ', 'ᵻ', 'o', 'ɵ', 
		'ʊ', 'u', 'ʉ', 'b', 'd', 'dz', 'dʑ', 'f', 'g', 'j', 'k', 'l', 
		'm', 'n', 'ʐ', 'p', 'r', 's', 'ʂ', 'ɕː', 't', 't͡s', 't͡ɕ', 'v', 
		'x', 'ɣ', 'γ', 'ʐ', 'ʑː', 'z', 'ʲ', 'ˈ'
	];

    _RussianPhoneticKeyboard(String initialValue, { Key key }): 
        super(phonetic_symbols, 15, key: key, initialValue: initialValue);
}

class PhoneticKeyboard {

	PhoneticKeyboard._();

	static InputKeyboard getLanguageSpecific({ 
		String initialValue, Key key, Language lang = Language.english 
	}) {
		switch (lang ?? Language.english) {
			case Language.english:
				return new _EnglishPhoneticKeyboard(initialValue, key: key);
			case Language.spanish:
				return new _SpanishPhoneticKeyboard(initialValue, key: key);
			case Language.german:
				return new _GermanPhoneticKeyboard(initialValue, key: key);
			case Language.russian:
				return new _RussianPhoneticKeyboard(initialValue, key: key);
			case Language.french:
				return new _FrenchPhoneticKeyboard(initialValue, key: key);
			case Language.italian:
				return new _ItalianPhoneticKeyboard(initialValue, key: key);
			default:
				return new _EnglishPhoneticKeyboard(initialValue, key: key);
		}
	}
}
