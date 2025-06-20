import 'dart:async';
import 'dart:collection';

part 'di_implementation.dart';
part 'di_reference.dart';
part 'di_reference_manager.dart';
part 'di_service_factory.dart';part 'di_type_registration.dart';

typedef FactoryFunc<T> = T Function();
typedef ReferenceFactoryFunc<T> = T Function(DiReference ref);
typedef ReferenceGroupFactoryFunc<T, G> = T Function(DiReference ref, G group);
typedef DisposingFunc<T> = FutureOr Function(T param);
typedef ScopeDisposeFunc = FutureOr Function();

class DiGroup<G extends Object> {
  const DiGroup(this.type, [this.value])
    : assert(
        type != Object,
        'Di: The compiler could not infer the type. You have to provide a type '
        'and optionally a name.',
      );

  final Type type;
  final G? value;

  @override
  bool operator ==(Object other) {
    if (other is! DiGroup) return false;
    return type == other.type && value == other.value;
  }

  @override
  int get hashCode => Object.hash(runtimeType, type, value);

  @override
  String toString() => 'DiGroup($type, $value)';
}

abstract mixin class DiDisposable {
  FutureOr dispose();
}

abstract interface class DiProvider {
  String? get debugLabel;

  T get<T extends Object>({Type? type});

  T call<T extends Object>({Type? type});

  FutureOr resetLazy<T extends Object>({T? instance, FutureOr Function(T)? disposingFunction});

  bool checkLazyInstanceExists<T extends Object>();

  FutureOr resetReferenced<T extends Object>({Object? group, FutureOr Function(T)? disposingFunction});

  bool checkReferencedInstanceExists<T extends Object>([Object? group]);

  DiReference createReference({String? defaultGroup, String? debugLabel});

  List<Object> getAllLazyInstances();

  List<Object> getAllReferencedInstances();
}

abstract interface class DiRegister {
  String? get debugLabel;

  T registerAsSingle<T extends Object>(T instance, {DisposingFunc<T>? dispose});

  void registerAsLazySingle<T extends Object>(FactoryFunc<T> factoryFunc, {DisposingFunc<T>? dispose});

  void registerAsReferencedSingle<T extends Object, G extends Object>({
    ReferenceFactoryFunc<T>? create,
    ReferenceGroupFactoryFunc<T, G> createWithGroup,
    DisposingFunc<T>? dispose,
  });

  void registerAsFactory<T extends Object>(FactoryFunc<T> factoryFunc);

  bool isRegistered<T extends Object>({Object? instance});

  Future<void> reset({bool dispose = true});

  FutureOr unregister<T extends Object>({Object? instance, FutureOr Function(T)? disposing});
}

abstract class DiReference implements DiProvider, DiDisposable {
  const DiReference();

  Object? get defaultGroup;

  @override
  String? get debugLabel;

  Iterable<DiGroup> get groups;

  bool get isDisposed;

  @override
  T get<T extends Object>({Type? type, Object? group});

  @override
  T call<T extends Object>({Type? type, Object? group});
}

sealed class Di implements DiRegister, DiProvider {
  static const _debugLabel = 'general';
  static final _instance = _DiImplementation(debugLabel: _debugLabel);

  static DiRegister get register => _instance;

  static DiProvider get provider => _instance;

  static _DiReferenceImplementation? _ref;

  static DiReference get reference {
    _ref ??= _DiReferenceImplementation(_instance, debugLabel: _debugLabel);
    return _ref!;
  }

  static void disposeReference() {
    _ref?.dispose();
    _ref = null;
  }

  static Di createOtherInstance({String? debugLabel}) => _DiImplementation(debugLabel: debugLabel);
}
