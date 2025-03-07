import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_chat/extensions/context_extension.dart';
import 'package:open_chat/models/chat.dart';
import 'package:open_chat/models/local_data.dart';
import 'package:open_chat/utils/app_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SidebarChatItem extends StatelessWidget {
  const SidebarChatItem({
    super.key,
    required this.chat,
    required this.isSelected,
  });

  final Chat chat;
  final bool isSelected;

  void _editChannel(BuildContext widgetContext, AppStateNotifier appState,
      AppLocalizations appLocals) {
    showDialog(
      context: widgetContext,
      builder: (context) {
        final titleController = TextEditingController(
          text: chat.title,
        );
        final systemPromptController = TextEditingController(
          text: chat.systemPrompt,
        );
        final maxContextLengthController = TextEditingController(
          text: chat.maxContextLength.toString(),
        );
        return AlertDialog(
          title: Text(appLocals.modifyChatTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: appLocals.newTitle,
                ),
              ),
              TextField(
                controller: systemPromptController,
                autofocus: false,
                decoration: InputDecoration(
                  labelText: appLocals.newSystemPrompt,
                ),
              ),
              TextField(
                controller: maxContextLengthController,
                autofocus: false,
                decoration: const InputDecoration(
                  labelText: 'Max Context Length',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.pop();
              },
              child: Text(
                appLocals.cancel,
                style: TextStyle(
                  color: Colors.red[300],
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                chat.title = titleController.text;
                chat.systemPrompt = systemPromptController.text;
                chat.maxContextLength =
                    int.tryParse(maxContextLengthController.text) ?? 0;
                appState.refresh();
                LocalData.instance.saveChat(chat);
                context.pop();
              },
              child: Text(appLocals.save),
            ),
          ],
        );
      },
    );
  }

  void _deleteChannel(BuildContext widgetContext, AppStateNotifier appState,
      AppLocalizations appLocals) {
    showDialog(
      context: widgetContext,
      builder: (context) {
        return AlertDialog(
          title: Text(appLocals.deleteChatTitle),
          content: Text(appLocals.deleteChatQuestion),
          actions: [
            TextButton(
              onPressed: () {
                context.pop();
              },
              child: Text(appLocals.back),
            ),
            TextButton(
              onPressed: () {
                appState.deleteChat(chat);
                context.pop();
              },
              child: Text(
                appLocals.delete,
                style: TextStyle(
                  color: Colors.red[300],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _selectChat(AppStateNotifier appState) {
    appState.selectChat(chat);
  }

  @override
  Widget build(BuildContext context) {
    final appLocals = context.appLocals;
    final appState = context.appState;

    return ValueListenableBuilder(
        valueListenable: appState,
        builder: (context, state, _) {
          return ListTile(
            mouseCursor: SystemMouseCursors.click,
            selected: isSelected,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.edit),
                  onPressed: state.isGenerating
                      ? null
                      : () => _editChannel(context, appState, appLocals),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  icon: Icon(Icons.delete,
                      color: isSelected ? Colors.red[300] : null),
                  onPressed: state.isGenerating
                      ? null
                      : () => _deleteChannel(context, appState, appLocals),
                ),
              ],
            ),
            title: Text(
              chat.title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : null,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            onTap: state.isGenerating ? null : () => _selectChat(appState),
          );
        });
  }
}
