# di_ref

A lightweight, group-based dependency injection (DI) package for Dart and Flutter.

## Installation

Add `di_ref` to your `pubspec.yaml`:

Then import it:

```dart
import 'package:di_ref/di_ref.dart';
```

## Core Concepts

- `Di.register` - singleton registry for declaring dependencies.
- `Di.provider` - singleton provider to retrieve instances.
- `DiReference` - provider created via `Di.provider.createReference()`, tracks referenced singletons by type and *group* (any `Object`) and cleans up when no live references remain.
- `DiReferenceProvider` - Flutter widget that injects a `DiReference` into `BuildContext`, managing its lifecycle automatically.

> **Note on groups**: A *group* can be any `Object`, not only `String`, so you able to use part of group like another group to create a tree.

## Registering Dependencies

Configure registrations before using `Di.provider` or any `DiReference`:

```dart
Di.register
  ..registerAsSingle<IdContainerA>(IdContainerA('A1'))
  ..registerAsLazySingle(() => IdContainerB('B1'))
  ..registerAsFactory(() => IdContainerC('C1'))
  ..registerAsReferencedSingle<IdContainerE, Object>(
    create: (ref) => IdContainerE('E1'),
    createWithGroup: (ref, group) => IdContainerE(group),
  );
```

- `registerAsSingle<T>(instance)` - always returns the same instance.
- `registerAsLazySingle<T>(factory)` - defers creation until first access.
- `registerAsFactory<T>(factory)` - returns a new instance every time.
- `registerAsReferencedSingle<T, G>` - returns one instance per *group*, tracked by reference for cleanup.

## Retrieving Instances

### Global Provider & Manual References

Factories, singles, and lazy singles can be fetched from the global provider or any `DiReference`. Referenced singles **require** a `DiReference`:

```dart
final diProvider = Di.provider;

var a = diProvider.get<IdContainerA>(); // Return instance
var b = diProvider.get<IdContainerB>(); // Return lazy instance
var c = diProvider.get<IdContainerC>(); // Create instance

final customRef = diProvider.createReference();
var eDefault = customRef.get<IdContainerE>();                             // Return default instance
var ePageRelated   = customRef.get<IdContainerE>(group: pageIdObject);    // Return another instance for pageIdObject
var e = diProvider.get<IdContainerE>();                                   // ERROR: must use reference
```

### Using `DiReferenceProvider` in Flutter

Wrap your widget subtree to inject `DiReference` into `BuildContext` and be able to read it using `context.ref`:

```dart
DiReferenceProvider(
  builder: (context) {
    final ref = context.ref;

    // Receiving groupless instances
    final a = ref.get<IdContainerA>();
    final c = ref.get<IdContainerC>();

    // Referenced single instance for group object
    final eConfig = ref.get<IdContainerE>(group: configObject);

    return HomePage();
  },
);
```

## Cleanup & Disposal

### Reference Tracking

- For any given combination of referenced type and group, only one instance per combination will created.
- A referenced instance can be read by multiple references.
- When the last live reference for a given type and group combination is disposed, that instance is automatically cleaned up.

```dart
final ref1 = diProvider.createReference();
final ref2 = diProvider.createReference();

ref1.get<IdContainerE>(group: pageId);
ref1.get<IdContainerF>(group: pageId);
ref2.get<IdContainerF>(group: pageId);

ref1.dispose(); // Instance IdContainerE was clean up, but IdContainerF still exists because ref2 holds it
ref2.dispose(); // No references remain, instance is cleaned up automatically
```

### Manual reset

- You able to manually cleanup some combination using `resetReferenced` method.
- You able to manually cleanup lazy instances using `resetLazy` method.

```dart
diProvider.resetLazy<IdContainerB>();
diProvider.resetReferenced<IdContainerE>();
diProvider.resetReferenced<IdContainerE>(group: yourGroupObject);
```