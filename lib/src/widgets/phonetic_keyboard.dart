import 'package:flutter/material.dart';
import 'package:language_cards/src/models/language.dart';
import './input_keyboard.dart';

class _EnglishPhoneticKeyboard extends InputKeyboard {
    static const phonetic_symbols = const <String>[
        'ɑ:', 'ʌ', 'ə', 'æ', 'e', 'ɛ', 'ɜ:ʳ', 'ɪ',  'i', 'i:', 
		'ɒ', 'ɔ:', 'ʊ', 'u:', 'aɪ', 'aʊ', 'eɪ', 'oʊ', 'ɔɪ', 
		'eəʳ', 'ɪəʳ', 'ʊəʳ', 'b', 'd', 'dʒ', 'ð', 'f', 'g', 
		'h', 'j', 'k', 'l', 'm', 'n', 'ŋ', 'p', 'r', 's', 'ʃ',
		't', 'tʃ', 'θ', 'v', 'w', 'z', 'ʒ', 'ˈ', 'ˌ', '.'
    ];

    _EnglishPhoneticKeyboard(String initialValue, { Key key }): 
        super(phonetic_symbols, 15, key: key, initialValue: initialValue);
}

class _FrenchPhoneticKeyboard extends InputKeyboard {
    static const phonetic_symbols = const <String>[
        'a', 'ɑ', 'ɑ̃', 'œ̃', 'e', 'ɛ', 'ɛː', 'ɛ̃', 'ə', 'i', 
		'o', 'ɔ̃', 'ɔ', 'ø', 'œ', 'œ̃', 'u', 'ɥ', 'y', 'b', 
		'd', 'f', 'g', 'j', 'k', 'l', 'm', 'n', 'ŋ', 'ɲ',   
		'p', 'ʁ', 's', 'ʃ', 't', 'v', 'w', 'z', 'ʒ', '.', '‿'
    ];

    _FrenchPhoneticKeyboard(String initialValue, { Key key }): 
        super(phonetic_symbols, 15, key: key, initialValue: initialValue);
}

class _SpanishPhoneticKeyboard extends InputKeyboard {
    static const phonetic_symbols = const <String>[
		'a', 'e', 'ɛ', 'i', 'o', 'u', 'ʝ', 'ɟʝ', 'b', 'β', 
		'd', 'ð', 'f', 'g', 'ɣ', 'j', 'k', 'l', 'ʎ', 'm', 'ɱ', 'n', 
		'ŋ', 'ɲ', 'p', 'r', 'ɾ', 's', 'ʃ', 't', 'ts', 'tʃ', 'θ', 
		'v', 'w', 'x', 'z', 'ˈ', '.'
    ];

    _SpanishPhoneticKeyboard(String initialValue, { Key key }): 
        super(phonetic_symbols, 15, key: key, initialValue: initialValue);
}

class _ItalianPhoneticKeyboard extends InputKeyboard {
    static const phonetic_symbols = const <String>[
		'a', 'e', 'ɛ', 'i', 'o', 'ɔ', 'u', 'ø', 'y',  
		'b', 'd', 'dz', 'dʒ', 'ʒ', 'f', 'g', 'h', 'j', 
		'k', 'l', 'ʎ', 'm', 'ɱ', 'n', 'ŋ', 'ɲ', 'p', 
		'r', 's', 'ʃ', 't', 'ts', 'tʃ', 'θ', 'v', 'w', 
		'x', 'z', 'ˈ', 'ˌ', '.', ':'
    ];

    _ItalianPhoneticKeyboard(String initialValue, { Key key }): 
        super(phonetic_symbols, 15, key: key, initialValue: initialValue);
}

class _GermanPhoneticKeyboard extends InputKeyboard {
    static const phonetic_symbols = const <String>[
		'a', 'ã', 'ɐ', 'ɐ̯', 'e', 'ɛ', 'ɛ̃', 'ə', 'i', 'ɪ', 'i̯',
		'o', 'õ', 'o̯', 'ɔ', 'œ', 'œ̃', 'ø', 'u', 'ʊ', 'u̯', 'y', 
		'y̑', 'ʏ', 'aɪ', 'aʊ', 'ɔʏ', 'ər', 'ɛɪ', 'ɔʊ', 'b', 'ç', 
		'd', 'dʒ', 'ʒ', 'ð', 'f', 'g', 'h', 'j', 'k', 'l', 'l̩', 
		'm', 'm̩', 'n', 'n̩', 'ŋ', 'p', 'pf', 'r', 'ʁ', 'ɹ', 's', 'ʃ', 
		't', 'ts', 'tʃ', 'θ', 'v', 'x', 'z', 'ʔ', ':', 'ˈ', 'ˌ'
    ];

    _GermanPhoneticKeyboard(String initialValue, { Key key }): 
        super(phonetic_symbols, 15, key: key, initialValue: initialValue);
}

class _RussianPhoneticKeyboard extends InputKeyboard {
    static const phonetic_symbols = const <String>[
		'a', 'æ', 'ɐ', 'ə', 'e', 'ɛ', 'i', 'ɨ', 'ɪ', 'ᵻ', 'ɵ', 'o',  
		'ʊ', 'u', 'ʉ', 'b', 'd', 'dz', 'dʑ', 'f', 'g', 'ɣ', 'j', 'k', 
		'l', 'm', 'n', 'ʐ', 'p', 'r', 's', 'ʂ', 'ɕː', 't', 't͡s', 't͡ɕ', 
		'v', 'x', 'ʐ', 'ʑː', 'z', 'ʲ', 'ˈ'
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
