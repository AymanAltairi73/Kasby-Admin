import 'package:flutter/material.dart';

/// Wraps the app without showing a persistent offline banner.
class ConnectivityBanner extends StatelessWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
