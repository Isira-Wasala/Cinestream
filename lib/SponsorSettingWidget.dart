import 'package:flutter/material.dart';
import 'package:main/SponsorSetting.dart';

class SponsorSettingWidget extends StatelessWidget {
  const SponsorSettingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SponsorSettingsPage(isSponsorMode: true);
  }
}
