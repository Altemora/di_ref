part of 'di.dart';

class _DiReferenceImplementation extends DiReference {
  _DiReferenceImplementation(this._diInstance, {this.defaultGroup, this.debugLabel});

  final _DiImplementation _diInstance;
  @override
  final String? debugLabel;
  @override
  final String? defaultGroup;
  @override
  final Set<DiGroup> groups = {};

  @override
  bool isDisposed = false;

  @override
  T get<T extends Object>({Type? type, Object? group}) {
    _throwIf(isDisposed, "Di: reference ${debugLabel == null ? '$this' : '$debugLabel : $this'} already disposed.");
    final currentGroup = group ?? defaultGroup;

    final result = _diInstance.get<T>(type: type, group: currentGroup, reference: this);

    return result;
  }

  @override
  T call<T extends Object>({Type? type, Object? group}) {
    return get<T>(type: type, group: group);
  }

  @override
  FutureOr dispose() {
    _diInstance._referenceManager.unregisterReference(this);
    groups.clear();
    isDisposed = true;
  }

  @override
  bool checkReferencedInstanceExists<T extends Object>([Object? group]) =>
      _diInstance.checkReferencedInstanceExists<T>(group);

  @override
  bool checkLazyInstanceExists<T extends Object>() => _diInstance.checkLazyInstanceExists<T>();

  @override
  FutureOr resetReferenced<T extends Object>({Object? group, FutureOr Function(T p1)? disposingFunction}) =>
      _diInstance.resetReferenced<T>(group: group, disposingFunction: disposingFunction);

  @override
  FutureOr resetLazy<T extends Object>({T? instance, FutureOr Function(T p1)? disposingFunction}) =>
      _diInstance.resetLazy<T>(instance: instance, disposingFunction: disposingFunction);

  void holdGroup(DiGroup group) => groups.add(group);

  @override
  DiReference createReference({String? defaultGroup, String? debugLabel}) =>
      _DiReferenceImplementation(_diInstance, defaultGroup: defaultGroup, debugLabel: debugLabel);

  @override
  List<Object> getAllLazyInstances() => _diInstance.getAllLazyInstances();

  @override
  List<Object> getAllReferencedInstances() => _diInstance.getAllReferencedInstances();
}
