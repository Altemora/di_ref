part of 'di.dart';

enum _ServiceFactoryType { factory, constant, lazy, referenced }

class _ServiceFactory<T extends Object, G extends Object> {
  final _DiImplementation _diInstance;

  final _ServiceFactoryType factoryType;
  final _TypeRegistration registeredIn;
  final FactoryFunc<T>? creationFunction;
  final ReferenceFactoryFunc<T>? creationReferencedFunction;
  final ReferenceGroupFactoryFunc<T, G>? creationReferencedGroupFunction;
  final DisposingFunc<T>? disposeFunction;
  final DiGroup group;

  T? _instance;

  T? get instance => _instance;

  void resetInstance() => _instance = null;

  late final Type registrationType;

  String get debugName => '$registrationType:$group';

  _ServiceFactory(
    this._diInstance,
    this.factoryType,
    this.group, {
    this.creationFunction,
    this.creationReferencedFunction,
    this.creationReferencedGroupFunction,
    T? instance,
    required this.registeredIn,
    this.disposeFunction,
  }) : _instance = instance,
       assert(
         !(disposeFunction != null && instance != null && instance is DiDisposable),
         ' You are trying to register type ${instance.runtimeType} '
         'that implements "Disposable" but you also provide a disposing function',
       ) {
    registrationType = T;
  }

  FutureOr dispose() {
    if (instance is DiDisposable) {
      return (instance! as DiDisposable).dispose();
    } else if (instance != null) {
      return disposeFunction?.call(instance!);
    }
  }

  T getObject([_DiReferenceImplementation? reference]) {
    try {
      switch (factoryType) {
        case _ServiceFactoryType.factory:
          return creationFunction!();
        case _ServiceFactoryType.constant:
          return instance!;
        case _ServiceFactoryType.referenced:
          _throwIf(
            reference == null,
            'Di: You not able to get referenced object $T without DiReference. Use DiReference to get this type of objects.',
          );

          if (instance == null) {
            final groupValue = group.value;
            _throwIf(
              groupValue == const NonGroup() && creationReferencedFunction == null,
              'Di: There is not group less Referenced factory for type `$T`',
            );
            _throwIf(
              groupValue != const NonGroup() && creationReferencedGroupFunction == null,
              'Di: There is not group Referenced factory for type `$T`',
            );
            _throwIf(
              groupValue != const NonGroup() && groupValue is! G,
              'Di: Group value type `$G` specified for `$T` referenced factory. '
              'You provide `${groupValue.runtimeType}` with value `$groupValue` instead.',
            );

            _instance = groupValue == const NonGroup()
                ? creationReferencedFunction!(reference!)
                : creationReferencedGroupFunction!(reference!, groupValue as G);
          }

          _diInstance._referenceManager.registerGroupForReference(group, reference!);

          return instance!;
        case _ServiceFactoryType.lazy:
          if (instance == null) {
            _instance = creationFunction!();
          }
          return instance!;
      }
    } catch (e) {
      rethrow;
    }
  }

  _ServiceFactory<T, G> copyWithGroup(DiGroup group) => _ServiceFactory(
    _diInstance,
    factoryType,
    group,
    creationFunction: creationFunction,
    creationReferencedFunction: creationReferencedFunction,
    creationReferencedGroupFunction: creationReferencedGroupFunction,
    registeredIn: registeredIn,
    disposeFunction: disposeFunction,
  );
}
