class DataGroup {

    static const lengthField = 'length';

    final int length;

    final Map<String, dynamic> fields;

    DataGroup(Map<String, dynamic> values): 
        length = values[lengthField] as int,
        fields = new Map.fromEntries(values.entries.where((e) => e.key != DataGroup.lengthField));

    operator[](String prop) => fields[prop];
}
