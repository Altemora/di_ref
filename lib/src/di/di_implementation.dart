part of 'di.dart';

void _throwIf(bool condition, Object error) {
  if (condition) throw error;
}

void _throwIfNot(bool condition, Object error) {
  if (!condition) throw error;
}

class _DiImplementation implements Di {
  _DiImplementation({this.debugLabel});

  @override
  final String? debugLabel;

  final _referenceManager = _DiReferenceManager();
  final LinkedHashMap<Type, _TypeRegistration> _typeRegistrations = LinkedHashMap<Type, _TypeRegistration>();

  _ServiceFactory<T, G>? _findFirstFactoryByGroupOrNull<T extends Object, G extends Object>(DiGroup group) {
    final _TypeRegistration? typeRegistration = _typeRegistrations[group.type];

    final foundFactory = typeRegistration?.getFactory(group);
    assert(
      foundFactory is _ServiceFactory<T, G>?,
      'It looks like you have passed your lookup type via the `type` but '
      'but the receiving variable is not a compatible type.',
    );

    return foundFactory as _ServiceFactory<T, G>?;
  }

  _ServiceFactory _findFactoryByGroup<T extends Object>(DiGroup group) {
    final instanceFactory = _findFirstFactoryByGroupOrNull<T, Object>(group);

    _throwIfNot(
      instanceFactory != null,
      StateError(
        'Di: Object/factory with '
        'type $T is not registered inside Di. '
        '\nDid you forget to register it?)',
      ),
    );

    return instanceFactory!;
  }

  @override
  T get<T extends Object>({Type? type, Object? group, _DiReferenceImplementation? reference}) {
    final instanceFactory = _findFactoryByGroup<T>(DiGroup(type ?? T, group ?? const NonGroup()));

    final Object instance;
    instance = instanceFactory.getObject(reference);

    return instance as T;
  }

  @override
  T call<T extends Object>({Type? type}) {
    return get<T>(type: type);
  }

  @override
  void registerAsFactory<T extends Object>(FactoryFunc<T> factoryFunc) {
    _register<T, Object>(type: _ServiceFactoryType.factory, factoryFunc: factoryFunc);
  }

  @override
  void registerAsLazySingle<T extends Object>(FactoryFunc<T> factoryFunc, {DisposingFunc<T>? dispose}) {
    _register<T, Object>(type: _ServiceFactoryType.lazy, factoryFunc: factoryFunc, disposeFunc: dispose);
  }

  @override
  void registerAsReferencedSingle<T extends Object, G extends Object>({
    ReferenceFactoryFunc<T>? create,
    ReferenceGroupFactoryFunc<T, G>? createWithGroup,
    DisposingFunc<T>? dispose,
  }) {
    _throwIfNot(
      create != null || createWithGroup != null,
      'Di: you should provide at least one `create` or `createWithGroup` factory for `registerAsReferencedSingle`',
    );
    _register<T, G>(
      type: _ServiceFactoryType.referenced,
      referencedFactoryFunc: create,
      referencedGroupFactoryFunc: createWithGroup,
      disposeFunc: dispose,
    );
  }

  @override
  T registerAsSingle<T extends Object>(T instance, {DisposingFunc<T>? dispose}) {
    _register<T, Object>(type: _ServiceFactoryType.constant, instance: instance, disposeFunc: dispose);
    return instance;
  }

  @override
  bool isRegistered<T extends Object>({Object? instance, Object? group}) {
    if (instance != null) {
      return _findFirstFactoryByInstanceOrNull(instance) != null;
    } else {
      return _findFirstFactoryByGroupOrNull<T, Object>(DiGroup(T, group ?? const NonGroup())) != null;
    }
  }

  @override
  FutureOr unregister<T extends Object>({Object? instance, FutureOr Function(T)? disposing}) async {
    final factoryToRemove = instance != null ? _findFactoryByInstance(instance) : _findFactoryByGroup<T>(DiGroup(T));
    final typeRegistration = factoryToRemove.registeredIn;

    typeRegistration.dispose();

    if (typeRegistration.isEmpty) {
      _typeRegistrations.remove(T);
    }

    if (factoryToRemove.instance != null) {
      final dispose = disposing == null ? factoryToRemove.dispose() : disposing.call(factoryToRemove.instance! as T);
      if (dispose is Future) await dispose;
    }
  }

  @override
  FutureOr resetReferenced<T extends Object>({Object? group, FutureOr Function(T p1)? disposingFunction}) async {
    final diGroup = DiGroup(T, group ?? const NonGroup());
    final result = _resetReferencedByGroup(diGroup);
    _referenceManager.unregisterGroupForAllReferences(diGroup);
    return result;
  }

  FutureOr _resetReferencedByGroup<T>(DiGroup group, {FutureOr Function(T p1)? disposingFunction}) async {
    final _ServiceFactory instanceFactory = _findFactoryByGroup(group);

    _throwIfNot(
      instanceFactory.factoryType == _ServiceFactoryType.referenced,
      StateError('There is no type $T registered as Referenced in Di'),
    );

    FutureOr? disposeReturn;
    if (instanceFactory.instance != null) {
      disposeReturn = (disposingFunction == null
          ? instanceFactory.dispose()
          : disposingFunction.call(instanceFactory.instance! as T));
    }

    instanceFactory.resetInstance();
    instanceFactory.registeredIn.removeServiceForGroup(group);

    if (disposeReturn is Future) await disposeReturn;
  }

  @override
  FutureOr resetLazy<T extends Object>({T? instance, FutureOr Function(T)? disposingFunction}) async {
    final _ServiceFactory instanceFactory = instance == null
        ? _findFactoryByGroup<T>(DiGroup(T))
        : _findFactoryByInstance(instance);

    _throwIfNot(
      instanceFactory.factoryType == _ServiceFactoryType.lazy,
      StateError('There is no type ${instance.runtimeType} registered as LazySingle in Di'),
    );

    FutureOr? disposeReturn;
    if (instanceFactory.instance != null) {
      disposeReturn = (disposingFunction == null
          ? instanceFactory.dispose()
          : disposingFunction.call(instanceFactory.instance! as T));
    }

    instanceFactory.resetInstance();
    if (disposeReturn is Future) await disposeReturn;
  }

  @override
  bool checkReferencedInstanceExists<T extends Object>([Object? group]) {
    final instanceFactory = _findFactoryByGroup<T>(DiGroup(T, group ?? const NonGroup()));
    _throwIfNot(
      instanceFactory.factoryType == _ServiceFactoryType.referenced,
      StateError('There is no type $T registered as Referenced in Di'),
    );

    return instanceFactory.instance != null;
  }

  @override
  bool checkLazyInstanceExists<T extends Object>() {
    final instanceFactory = _findFactoryByGroup<T>(DiGroup(T));
    _throwIfNot(
      instanceFactory.factoryType == _ServiceFactoryType.lazy,
      StateError('There is no type $T registered as Lazy in Di'),
    );

    return instanceFactory.instance != null;
  }

  List<_ServiceFactory> get _allFactories =>
      _typeRegistrations.values.fold<List<_ServiceFactory>>([], (sum, x) => sum..addAll(x.groupedFactories.values));

  _ServiceFactory? _findFirstFactoryByInstanceOrNull(Object instance) {
    return _allFactories.firstWhereOrNull((x) => identical(x.instance, instance));
  }

  _ServiceFactory _findFactoryByInstance(Object instance) {
    final registeredFactory = _findFirstFactoryByInstanceOrNull(instance);

    _throwIf(
      registeredFactory == null,
      StateError(
        'This instance of the type ${instance.runtimeType} is not available in Di '
        'If you have registered it as LazySingle, are you sure you have used '
        'it at least once?',
      ),
    );

    return registeredFactory!;
  }

  @override
  Future<void> reset({bool dispose = true}) async {
    if (dispose) {
      for (final factory in _allFactories.reversed) {
        await factory.dispose();
      }
      _typeRegistrations.clear();
    }
  }

  void _register<T extends Object, G extends Object>({
    required _ServiceFactoryType type,
    FactoryFunc<T>? factoryFunc,
    ReferenceFactoryFunc<T>? referencedFactoryFunc,
    ReferenceGroupFactoryFunc<T, G>? referencedGroupFactoryFunc,
    T? instance,
    DisposingFunc<T>? disposeFunc,
  }) {
    _throwIfNot(const Object() is! T, 'Di: You have to provide type.`');
    _throwIf(_typeRegistrations[T] != null, ArgumentError('Type $T is already registered inside Di. '));

    final _TypeRegistration typeRegistration = _typeRegistrations.putIfAbsent(T, () => _TypeRegistration<T, G>());

    typeRegistration.setFactory(
      _ServiceFactory<T, G>(
        this,
        type,
        DiGroup(T),
        registeredIn: typeRegistration,
        creationFunction: factoryFunc,
        creationReferencedFunction: referencedFactoryFunc,
        creationReferencedGroupFunction: referencedGroupFactoryFunc,
        instance: instance,
        disposeFunction: disposeFunc,
      ),
    );
  }

  @override
  DiReference createReference({Object? defaultGroup, String? debugLabel}) =>
      _DiReferenceImplementation(this, defaultGroup: defaultGroup, debugLabel: debugLabel);

  @override
  List<Object> getAllLazyInstances() {
    return _allFactories
        .where((it) => it.factoryType == _ServiceFactoryType.lazy && it.instance != null)
        .map((it) => it.instance!)
        .toList();
  }

  @override
  List<Object> getAllReferencedInstances({DiReference? reference}) {
    return _allFactories
        .where(
          (it) =>
              it.factoryType == _ServiceFactoryType.referenced &&
              it.instance != null &&
              (reference?.groups.contains(it.group) ?? true),
        )
        .map((it) => it.instance!)
        .toList();
  }
}

extension IterableX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
