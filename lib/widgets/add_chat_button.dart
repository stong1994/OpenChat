import 'package:flutter/material.dart';
import 'package:open_gpt_client/extensions/context_extension.dart';
import 'package:open_gpt_client/models/chat.dart';
import 'package:open_gpt_client/models/local_data.dart';
import 'package:uuid/uuid.dart';

class AddChatButton extends StatelessWidget {
  const AddChatButton({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final appLocals = context.appLocals;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: () async {
          final chat = Chat(
            id: const Uuid().v4(),
            title: appLocals.noChatTitle,
            messages: [],
            contextMessages: [],
          );
          appState.addAndSelectChat(chat);
          await LocalData.instance.saveChat(chat);
          await LocalData.instance.saveAppSettings(appState.value.settings);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add),
            const SizedBox(width: 8),
            Text(appLocals.addChat),
          ],
        ),
      ),
    );
  }
}
