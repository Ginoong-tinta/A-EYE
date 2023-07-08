import 'package:capstone/dimensions.dart';
import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget tabletBody;

  ResponsiveLayout({@required this.mobileBody, @required this.tabletBody});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints){
          if (constraints.maxWidth < mobileWidth){
            return mobileBody;
          } else {
            return tabletBody;
          }
        },
    );
  }
}
