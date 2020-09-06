abstract class BaseStorage<T> {
    Future<List<T>> fetch({ int skipCount, int takeCount, int parentId });

    Future<T> find(int id);

    Future<bool> save(T word);

    Future<void> remove(Iterable<int> ids);
}
