part of 'di.dart';

class _DiReferenceManager {
  _DiReferenceManager();

  final LinkedHashMap<DiGroup, Set<_DiReferenceImplementation>> _groupedReferences =
      LinkedHashMap<DiGroup, Set<_DiReferenceImplementation>>();

  void registerGroupForReference(DiGroup group, _DiReferenceImplementation reference) {
    if (_groupedReferences[group] == null) {
      _groupedReferences[group] = {};
    }

    _groupedReferences[group]!.add(reference);

    reference.holdGroup(group);
  }

  void unregisterGroupForAllReferences(DiGroup group) {
    final referencesSet = _groupedReferences[group];
    if (referencesSet == null) return;

    for (final reference in referencesSet) {
      reference.releaseGroup(group);
    }
    _groupedReferences.remove(group);
  }

  void unregisterReference(_DiReferenceImplementation reference) {
    for (final group in reference.groups) {
      _releaseReferenceForGroup(reference, group);
    }
  }

  void _releaseReferenceForGroup(_DiReferenceImplementation reference, DiGroup group) {
    final referencesSet = _groupedReferences[group];
    if (referencesSet == null) {
      Di._instance._resetReferencedByGroup(group);
    } else {
      referencesSet.remove(reference);
      if (referencesSet.isEmpty) {
        _groupedReferences.remove(group);
        Di._instance._resetReferencedByGroup(group);
      }
    }
  }
}
