part of 'di.dart';

class _TypeRegistration<T extends Object, G extends Object> {
  final _defaultGroup = DiGroup(T);
  final LinkedHashMap<DiGroup, _ServiceFactory<T, G>> groupedFactories =
      LinkedHashMap<DiGroup, _ServiceFactory<T, G>>();

  void dispose() {
    for (final factory in groupedFactories.values.toList().reversed) {
      factory.dispose();
    }
    groupedFactories.clear();
  }

  bool get isEmpty => groupedFactories.isEmpty;

  _ServiceFactory<T, G>? getFactory(DiGroup<G> group) {
    final factory = groupedFactories[_defaultGroup];
    if (group.value == null) return factory;

    if (groupedFactories[group] == null && factory != null) {
      groupedFactories[group] = factory.copyWithGroup(group);
    }

    return groupedFactories[group];
  }

  void setFactory(_ServiceFactory<T, G> serviceFactory) => groupedFactories[_defaultGroup] = serviceFactory;

  void removeServiceForGroup(DiGroup<G> group) {
    if (group.value == null) return;
    groupedFactories[group]?.dispose();
    groupedFactories.remove(group);
  }
}
