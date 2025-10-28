import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:room_booker/ui/widgets/heading.dart';

class AppInfoWidget extends StatelessWidget {
  const AppInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container();
          }
          if (snapshot.hasError) {
            return ErrorWidget(Exception(snapshot.error));
          }
          var packageInfo = snapshot.data!;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Heading("App Info"),
              Text("App Name: ${packageInfo.appName}"),
              Text("App Version: ${packageInfo.version}"),
              Text("Build Number: ${packageInfo.buildNumber}"),
            ],
          );
        });
  }
}
