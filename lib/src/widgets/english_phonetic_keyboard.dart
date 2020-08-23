import 'package:flutter/material.dart';
import './input_keyboard.dart';

class EnglishPhoneticKeyboard extends InputKeyboard {
    static const PHONETIC_SYMBOLS = const <String>[
        'ʌ', 'ɑ:', 'æ', 'e', 'ə', 'ɜ:ʳ', 'ɪ', 'i:', 'ɒ', 'ɔ:', 'ʊ', 'u:',
        'aɪ', 'aʊ', 'eɪ', 'oʊ', 'ɔɪ', 'eəʳ', 'ɪəʳ', 'ʊəʳ', 'b', 'd', 'f',
        'g', 'h', 'j', 'k', 'l', 'm', 'n', 'ŋ', 'p', 'r', 's', 't', 
        'tʃ', 'θ', 'ð', 'v', 'w', 'z', 'ʒ', 'dʒ'
    ];

    EnglishPhoneticKeyboard(String initialValue, { Key key }): 
        super(PHONETIC_SYMBOLS, 15, key: key, initialValue: initialValue);
}
