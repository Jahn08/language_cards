import 'package:meta/meta.dart';
import 'data_group.dart';

abstract class DataProvider {

    Future<void> close();

    Future<void> update(String tableName, List<Map<String, dynamic>> entities);

    Future<List<int>> add(String tableName, List<Map<String, dynamic>> entities);

    Future<int> delete(String tableName, List<dynamic> ids);
    
	Future<int> count(String tableName, { Map<String, dynamic> filters });

    Future<List<DataGroup>> groupBy(String tableName, 
        { @required String groupField, List<dynamic> groupValues, Map<String, dynamic> filters });

    Future<List<DataGroup>> groupBySeveral(String tableName, 
        { @required List<String> groupFields, Map<String, List<dynamic>> groupValues });

    Future<List<Map<String, dynamic>>> fetch(String tableName, { @required String orderBy,
        int take, int skip, Map<String, dynamic> filters });

    Future<Map<String, dynamic>> findById(String tableName, dynamic id);
}
