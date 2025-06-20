part of 'di.dart';

class _DiReferenceManager {
  _DiReferenceManager();

  final LinkedHashMap<DiGroup, Set<_DiReferenceImplementation>> _groupedReferences =
      LinkedHashMap<DiGroup, Set<_DiReferenceImplementation>>();

  void registerGroupWithReference(DiGroup group, _DiReferenceImplementation reference) {
    if (_groupedReferences[group] == null) {
      _groupedReferences[group] = {};
    }

    _groupedReferences[group]!.add(reference);

    reference.holdGroup(group);
  }

  void unregisterReference(_DiReferenceImplementation reference) {
    for (final group in reference.groups) {
      _releaseReferenceFroGroup(reference, group);
    }
  }

  void _releaseReferenceFroGroup(_DiReferenceImplementation reference, DiGroup group) {
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
