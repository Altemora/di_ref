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

  _ServiceFactory<T, G>? getFactory(DiGroup group) {
    final factory = groupedFactories[_defaultGroup];
    if (group.value == const NonGroup()) return factory;

    if (groupedFactories[group] == null && factory != null) {
      groupedFactories[group] = factory.copyWithGroup(group);
    }

    return groupedFactories[group];
  }

  void setFactory(_ServiceFactory<T, G> serviceFactory) => groupedFactories[_defaultGroup] = serviceFactory;

  void removeServiceForGroup(DiGroup group) {
    if (group.value == const NonGroup()) return;
    groupedFactories[group]?.dispose();
    groupedFactories.remove(group);
  }
}
