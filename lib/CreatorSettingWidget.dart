import 'package:flutter/material.dart';
import 'package:main/CreatorSetting.dart';

class CreatorSettingWidget extends StatelessWidget {
  const CreatorSettingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const CreatorSettingsPage(isCreatorMode: true);
  }
}
