import 'package:di_ref/src/di/di.dart';
import 'package:flutter/cupertino.dart';

class DiReferenceProvider extends StatefulWidget {
  const DiReferenceProvider({super.key, this.instance, this.defaultGroup, this.debugLabel, required this.builder});

  final Di? instance;
  final Object? defaultGroup;
  final String? debugLabel;
  final Widget Function(BuildContext) builder;

  @override
  State<DiReferenceProvider> createState() => _DiReferenceProviderState();
}

class _DiReferenceProviderState extends State<DiReferenceProvider> {
  DiReference? _reference;

  @override
  void didChangeDependencies() {
    _reference = (widget.instance ?? Di.instance).createReference(
      defaultGroup: widget.defaultGroup,
      debugLabel: widget.debugLabel,
    );
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _reference?.dispose();
    _reference = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reference = _reference;
    if (reference == null) return widget.builder(context);

    return _DiReferenceInherited(reference: reference, child: _DiReferenceWidgetBuilder(widget.builder));
  }
}

class _DiReferenceWidgetBuilder extends StatelessWidget {
  const _DiReferenceWidgetBuilder(this.builder);

  final Widget Function(BuildContext) builder;

  @override
  Widget build(BuildContext context) => builder(context);
}

class _DiReferenceInherited extends InheritedWidget {
  const _DiReferenceInherited({required this.reference, required super.child});

  final DiReference? reference;

  @override
  bool updateShouldNotify(covariant _DiReferenceInherited oldWidget) => reference != oldWidget.reference;
}
