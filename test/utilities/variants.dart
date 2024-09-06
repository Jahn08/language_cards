enum ReturnNavigationWay { byOSButton, byBarBackButton }

class DoubleVariant<T1, T2> {
  final T1 value1;

  final T2 value2;

  final String? name1;

  final String? name2;

  DoubleVariant(this.value1, this.value2, {this.name1, this.name2});

  @override
  String toString() {
    return "value1=${name1 ?? value1}; value2=${name2 ?? value2}";
  }
}
