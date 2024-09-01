bool isNullOrEmpty(String str) => str == null || str.isEmpty;

String getValueOrDefault(String val, String def) =>
    isNullOrEmpty(val) ? def : val;

List<String> splitLocalizedText(String text) => text.split('@');
