import 'package:di_ref/di_ref.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class IdContainer {
  const IdContainer(this.id);

  final String id;

  @override
  String toString() => '$runtimeType($id)';
}

class IdContainerA extends IdContainer {
  const IdContainerA(super.id);
}

class IdContainerB extends IdContainer {
  const IdContainerB(super.id);
}

class IdContainerC extends IdContainer {
  const IdContainerC(super.id);
}

class IdContainerD extends IdContainer {
  const IdContainerD(super.id);
}

class IdContainerE extends IdContainer {
  const IdContainerE(super.id);
}

class IdContainerF extends IdContainer {
  const IdContainerF(super.id, this.other, this.lazySingleton);

  final IdContainerE other;
  final IdContainerB lazySingleton;
}

void main() {
  final diRegister = Di.register;
  final diProvider = Di.provider;
  final diReference1 = diProvider.createReference(debugLabel: 'diReference1');
  final diReference2 = diProvider.createReference(debugLabel: 'diReference2');

  diRegister
    ..registerAsSingle(IdContainerA('IdA'))
    ..registerAsLazySingle(() => IdContainerB('IdB'))
    ..registerAsFactory(() => IdContainerC('IdC'))
    ..registerAsFactory(() => IdContainerD('IdD'))
    ..registerAsReferencedSingle(
      create: (ref) => IdContainerE('IdE'),
      createWithGroup: (ref, group) => IdContainerE(group.toString()),
    )
    ..registerAsReferencedSingle<IdContainerF, String>(
      create: (ref) => IdContainerF('IdF', ref.get(), ref.get()),
      createWithGroup: (ref, group) => IdContainerF(group.toString(), ref.get(group: group), diProvider.get()),
    );

  /// WARNING: There is a test what calculate instances after this scope of tests.
  /// So add other instances usage only after `MARKER_A` comment
  test('Is lazy exist before first call', () {
    expect(diProvider.checkLazyInstanceExists<IdContainerB>(), false);
    expect(diProvider.checkReferencedInstanceExists<IdContainerE>(), false);
    expect(diProvider.checkReferencedInstanceExists<IdContainerF>(), false);
  });

  test('Get instances from DI', () {
    expect(diProvider.get<IdContainerA>().id, 'IdA');
    expect(diProvider.get<IdContainerB>().id, 'IdB');
    expect(diProvider.get<IdContainerC>().id, 'IdC');
    expect(diProvider.get<IdContainerD>().id, 'IdD');
    expect(diReference1.get<IdContainerE>().id, 'IdE');
    expect(diReference2.get<IdContainerF>().id, 'IdF');
  });

  test('Is lazy exist after call', () {
    expect(diProvider.checkLazyInstanceExists<IdContainerB>(), true);
    expect(diProvider.checkReferencedInstanceExists<IdContainerE>(), true);
    expect(diReference1.checkReferencedInstanceExists<IdContainerF>(), true);
  });

  test('Di singletons instances equals', () {
    expect(diProvider.get<IdContainerA>() == diProvider.get<IdContainerA>(), true);
    expect(diProvider.get<IdContainerB>() == diProvider.get<IdContainerB>(), true);
  });

  test('Di non group instances called from provider throw exception', () {
    expect(diReference1.get<IdContainerE>(), isA<IdContainerE>());
    expect(() => diProvider.get<IdContainerE>(), throwsA(isA<String>()));
    expect(() => diProvider.get<IdContainerF>(), throwsA(isA<String>()));
  });

  test('Di non group referenced instances is equals', () {
    expect(diReference1.get<IdContainerE>() == diReference1.get<IdContainerE>(), true);
    expect(diReference1.get<IdContainerF>() == diReference2.get<IdContainerF>(), true);
  });

  test('Di factories instances not equals', () {
    expect(diProvider.get<IdContainerC>() == diProvider.get<IdContainerC>(), false);
    expect(diProvider.get<IdContainerD>() == diProvider.get<IdContainerD>(), false);
  });

  test('DiReference get function work the same as diProvider get function', () {
    expect(diReference1.get<IdContainerA>() == diProvider.get<IdContainerA>(), true);
    expect(diReference2.get<IdContainerC>() == diProvider.get<IdContainerC>(), false);
    expect(diReference1.get<IdContainerA>() == diReference2.get<IdContainerA>(), true);
  });

  test('DiReference get function work with groups', () {
    expect(diReference1.get<IdContainerE>().id, 'IdE');
    expect(diReference1.get<IdContainerE>(group: 'groupA').id, 'groupA');
    expect(diReference1.get<IdContainerE>(group: 'groupB').id, 'groupB');
    expect(diReference1.get<IdContainerE>(group: 'groupA') == diReference1.get<IdContainerE>(), false);
    expect(diReference1.get<IdContainerE>(group: 'groupA') == diReference1.get<IdContainerE>(group: 'groupA'), true);
    expect(diReference1.get<IdContainerE>(group: 'groupA') == diReference1.get<IdContainerE>(group: 'groupB'), false);
    expect(diReference1.get<IdContainerE>(group: 'groupA') == diReference2.get<IdContainerE>(group: 'groupA'), true);
    expect(diReference1.get<IdContainerE>(group: 'groupA') == diReference2.get<IdContainerE>(group: 'groupB'), false);
  });

  test('DiReference cascade grouping works', () {
    final containerF = diReference1.get<IdContainerF>();
    final containerE = diReference1.get<IdContainerE>();
    final containerFGroupA = diReference1.get<IdContainerF>(group: 'groupA');
    final containerEGroupA = diReference1.get<IdContainerE>(group: 'groupA');
    final containerFGroupB = diReference1.get<IdContainerF>(group: 'groupB');
    final containerEGroupB = diReference1.get<IdContainerE>(group: 'groupB');

    expect(containerF.other == containerE, true);
    expect(diReference1.get<IdContainerF>().other == diReference1.get<IdContainerE>(), true);
    expect(diReference1.get<IdContainerF>().lazySingleton == diReference2.get<IdContainerB>(), true);
    expect(diReference1.get<IdContainerE>() == diReference1.get<IdContainerE>(), true);
    expect(containerE == diReference1.get<IdContainerE>(), true);
    expect(containerE == diReference2.get<IdContainerE>(), true);
    expect(containerF == diReference2.get<IdContainerF>(), true);
    expect(containerF.other == diReference2.get<IdContainerF>().other, true);
    expect(containerFGroupA.other == containerEGroupA, true);
    expect(containerFGroupB.other == containerEGroupB, true);
    expect(containerFGroupA.other == containerFGroupB.other, false);
    expect(containerF == containerFGroupA, false);
  });

  test('Di check actual instances', () {
    expect(diReference1.groups, [
      DiGroup(IdContainerE),
      DiGroup(IdContainerF),
      DiGroup(IdContainerE, 'groupA'),
      DiGroup(IdContainerE, 'groupB'),
      DiGroup(IdContainerF, 'groupA'),
      DiGroup(IdContainerF, 'groupB'),
    ]);
    expect(diReference2.groups, [
      DiGroup(IdContainerE),
      DiGroup(IdContainerF),
      DiGroup(IdContainerE, 'groupA'),
      DiGroup(IdContainerE, 'groupB'),
    ]);
    expect(diProvider.getAllReferencedInstances().length == 6, true);
  });

  /// MARKER_A: Add new instances only after previous test
  test('Di check resetReferenced release the instance', () {
    final diReferenceWillStay = diProvider.createReference();
    final diReferenceWillStay2 = diProvider.createReference();

    expect(diProvider.checkReferencedInstanceExists<IdContainerF>('diReferenceWillStayGroup'), false);
    expect(diProvider.checkReferencedInstanceExists<IdContainerE>('diReferenceWillStayGroup'), false);
    expect(diReferenceWillStay.groups.isEmpty, true);
    diReferenceWillStay.get<IdContainerF>(group: 'diReferenceWillStayGroup');
    diReferenceWillStay2.get<IdContainerF>(group: 'diReferenceWillStayGroup');
    expect(diReferenceWillStay.isDisposed, false);
    expect(diProvider.checkReferencedInstanceExists<IdContainerF>('diReferenceWillStayGroup'), true);
    expect(diProvider.checkReferencedInstanceExists<IdContainerE>('diReferenceWillStayGroup'), true);
    expect(diReferenceWillStay.groups.isEmpty, false);
    diReferenceWillStay.resetReferenced<IdContainerF>(group: 'diReferenceWillStayGroup');
    diReferenceWillStay.resetReferenced<IdContainerE>(group: 'diReferenceWillStayGroup');
    expect(diReferenceWillStay.groups.isEmpty, true);
    expect(diProvider.checkReferencedInstanceExists<IdContainerF>('diReferenceWillStayGroup'), false);
    expect(diProvider.checkReferencedInstanceExists<IdContainerE>('diReferenceWillStayGroup'), false);
    diReferenceWillStay.get<IdContainerF>(group: 'diReferenceWillStayGroup');
    diReferenceWillStay2.get<IdContainerF>(group: 'diReferenceWillStayGroup');
    expect(diProvider.checkReferencedInstanceExists<IdContainerF>('diReferenceWillStayGroup'), true);
    expect(diProvider.checkReferencedInstanceExists<IdContainerE>('diReferenceWillStayGroup'), true);
    diReferenceWillStay.dispose();
    diReferenceWillStay2.dispose();
    expect(diProvider.checkReferencedInstanceExists<IdContainerF>('diReferenceWillStayGroup'), false);
    expect(diProvider.checkReferencedInstanceExists<IdContainerE>('diReferenceWillStayGroup'), false);
  });

  testWidgets('DiReferenceProvider injects DiReference into context and disposes properly', (tester) async {
    DiReference? receivedRef;
    await tester.pumpWidget(
      DiReferenceProvider(
        builder: (context) {
          receivedRef = context.ref;
          return const Placeholder();
        },
      ),
    );

    expect(receivedRef != null, true);
    expect(receivedRef!.isDisposed, false);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(receivedRef!.isDisposed, true);
  });

  testWidgets('DiReferenceProvider injects DiReference and reference dispose instance correctly', (tester) async {
    DiReference? receivedRef;
    await tester.pumpWidget(
      DiReferenceProvider(
        builder: (context) {
          receivedRef = context.ref;
          return const Placeholder();
        },
      ),
    );
    expect(diProvider.checkReferencedInstanceExists<IdContainerE>('fromWidgetProvider'), false);
    expect(diProvider.checkReferencedInstanceExists<IdContainerE>('fromWidgetProvider'), false);

    IdContainerE containerE = receivedRef!.get<IdContainerE>(group: 'fromWidgetProvider');
    expect(diProvider.checkReferencedInstanceExists<IdContainerE>('fromWidgetProvider'), true);
    expect(containerE == receivedRef!.get<IdContainerE>(group: 'fromWidgetProvider'), true);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(diProvider.checkReferencedInstanceExists<IdContainerE>('fromWidgetProvider'), false);
    expect(() => containerE == receivedRef!.get<IdContainerE>(group: 'fromWidgetProvider'), throwsA(isA<String>()));
    expect(containerE == diReference2.get<IdContainerE>(group: 'fromWidgetProvider'), false);
    diReference2.resetReferenced<IdContainerE>(group: 'fromWidgetProvider');
    expect(receivedRef!.isDisposed, true);
  });

  testWidgets('DiReferenceProvider disposes only when last holder disappears', (tester) async {
    Key? outerKey = Key('outerKey');
    Key? innerKey = Key('innerKey');
    DiReference? outerRef;
    DiReference? innerRef;

    expect(diProvider.checkReferencedInstanceExists<IdContainerE>('fromWidgetProvider'), false);
    expect(diProvider.checkReferencedInstanceExists<IdContainerE>('fromInnerWidgetProvider'), false);
    await tester.pumpWidget(
      DiReferenceProvider(
        key: outerKey,
        debugLabel: 'outerProvider',
        builder: (outerContext) {
          outerRef = outerContext.ref;
          outerRef!.get<IdContainerE>(group: 'fromWidgetProvider');

          return DiReferenceProvider(
            key: innerKey,
            debugLabel: 'innerProvider',
            builder: (innerContext) {
              innerRef = innerContext.ref;
              innerRef!.get<IdContainerE>(group: 'fromWidgetProvider');
              innerRef!.get<IdContainerE>(group: 'fromInnerWidgetProvider');
              return const Placeholder();
            },
          );
        },
      ),
    );
    expect(diProvider.checkReferencedInstanceExists<IdContainerE>('fromWidgetProvider'), true);
    expect(diProvider.checkReferencedInstanceExists<IdContainerE>('fromInnerWidgetProvider'), true);
    expect(innerRef!.isDisposed, false);
    expect(outerRef!.isDisposed, false);

    final instanceOuter = outerRef!.get<IdContainerE>(group: 'fromWidgetProvider');
    final instanceInner = innerRef!.get<IdContainerE>(group: 'fromWidgetProvider');
    final instanceInnerOnly = innerRef!.get<IdContainerE>(group: 'fromInnerWidgetProvider');

    expect(instanceOuter == instanceInner, true);
    expect(instanceInner == instanceInnerOnly, false);

    await tester.pumpWidget(
      DiReferenceProvider(
        key: outerKey,
        builder: (context) {
          expect(diProvider.checkReferencedInstanceExists<IdContainerE>('fromWidgetProvider'), true);
          return const Placeholder();
        },
      ),
    );

    expect(innerRef!.isDisposed, true);
    expect(outerRef!.isDisposed, false);
    expect(diProvider.checkReferencedInstanceExists<IdContainerE>('fromWidgetProvider'), true);
    expect(diProvider.checkReferencedInstanceExists<IdContainerE>('fromInnerWidgetProvider'), false);

    await tester.pumpWidget(const SizedBox.shrink());

    expect(innerRef!.isDisposed, true);
    expect(outerRef!.isDisposed, true);
    expect(diProvider.checkReferencedInstanceExists<IdContainerE>('fromWidgetProvider'), false);
    expect(diProvider.checkReferencedInstanceExists<IdContainerE>('fromInnerWidgetProvider'), false);
  });

  /// WARNING: this tests will reset lazy and referenced object so should be complete latest.
  test('Is resetting lazy singleton works', () {
    final instanceA = diProvider.get<IdContainerB>();
    final instanceB = diProvider.get<IdContainerB>();
    diProvider.resetLazy<IdContainerB>();
    final instanceC = diProvider.get<IdContainerB>();
    expect(instanceA == instanceB, true);
    expect(instanceA == instanceC, false);
    expect(instanceB == instanceC, false);
  });

  test('Is resetting references works', () {
    final instanceA = diReference1.get<IdContainerE>();
    final instanceB = diReference1.get<IdContainerE>();
    diProvider.resetReferenced<IdContainerE>();
    final instanceC = diReference1.get<IdContainerE>();
    expect(instanceA == instanceB, true);
    expect(instanceA == instanceC, false);
    expect(instanceB == instanceC, false);
  });

  test('Is resetting grouped references works', () {
    final instanceA = diReference1.get<IdContainerE>(group: 'groupA');
    final instanceB = diReference1.get<IdContainerE>(group: 'groupA');
    diProvider.resetReferenced<IdContainerE>(group: 'groupA');
    final instanceC = diReference1.get<IdContainerE>(group: 'groupA');
    expect(instanceA == instanceB, true);
    expect(instanceA == instanceC, false);
    expect(instanceB == instanceC, false);
  });

  test('Is disposing reference works', () {
    diReference1.dispose();
    diReference2.dispose();
    expect(diReference1.groups, []);
    expect(diReference2.groups, []);
    expect(diProvider.getAllReferencedInstances().isEmpty, true);
  });
}
