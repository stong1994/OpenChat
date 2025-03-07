import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_chat/extensions/context_extension.dart';
import 'package:open_chat/models/api_client.dart';
import 'package:open_chat/models/chat.dart';
import 'package:open_chat/models/local_data.dart';
import 'package:open_chat/utils/app_bloc.dart';
import 'package:open_chat/widgets/chat_message_ui.dart';
import 'package:uuid/uuid.dart';

class SelectedChatActionField extends StatefulWidget {
  const SelectedChatActionField({super.key});

  @override
  State<SelectedChatActionField> createState() =>
      _SelectedChatActionFieldState();
}

class _SelectedChatActionFieldState extends State<SelectedChatActionField> {
  late final _textController = TextEditingController();
  late final _fieldFocusNode = FocusNode();
  late final _keyboardListenerFocusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _fieldFocusNode.dispose();
    _keyboardListenerFocusNode.dispose();
    super.dispose();
  }

  void _onSend(AppState currentState, AppStateNotifier appState,
      ApiService apiService) async {
    final trimmedText = _textController.text.trim();
    if (currentState.selectedChat == null ||
        currentState.isGenerating ||
        trimmedText.isEmpty) {
      return;
    }

    final message = ChatMessage(
      id: const Uuid().v4(),
      senderRole: MessageSenderRole.user,
      content: trimmedText,
    );
    appState.addToSelectedAndContext(message);

    _textController.clear();
    _fieldFocusNode.unfocus();
    appState.addMessageToSelectedChat(
      ChatMessage(
        id: const Uuid().v4(),
        uniqueKeyUI: GlobalKey<ChatMessageUIState>(),
        senderRole: MessageSenderRole.assistant,
        content: '',
        isLoadingResponse: true,
      ),
    );

    appState.setGenerating(true);
    final response = await apiService.sendMessages(currentState.selectedChat!);
    if (response != null) {
      appState.attachStreamToLastResponse(response);
      return;
    }

    appState.setGenerating(false);
    appState.setErrorToLastMessage();
  }

  void _generateImage(AppState currentState, AppStateNotifier appState,
      ApiService apiService) async {
    final trimmedText = _textController.text.trim();
    if (currentState.selectedChat == null ||
        currentState.isGenerating ||
        trimmedText.isEmpty) {
      return;
    }

    final message = ChatMessage(
      id: const Uuid().v4(),
      senderRole: MessageSenderRole.user,
      messageType: MessageType.image,
      content: trimmedText,
    );
    appState.addMessageToSelectedChat(message);

    LocalData.instance.saveChat(currentState.selectedChat!);

    _textController.clear();
    _fieldFocusNode.unfocus();

    appState.addMessageToSelectedChat(
      ChatMessage(
        id: const Uuid().v4(),
        uniqueKeyUI: GlobalKey<ChatMessageUIState>(),
        senderRole: MessageSenderRole.assistant,
        content: '',
        isLoadingResponse: true,
        messageType: MessageType.image,
      ),
    );

    appState.setGenerating(true);
    final response = await apiService.createImage(
        trimmedText, appState.value.settings.dallEImageSize);
    if (response != null) {
      appState.attachGeneratedImageToLastMessage(response);
      return;
    }

    appState.setGenerating(false);
    appState.setErrorToLastMessage();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final appLocals = context.appLocals;
    final apiService = context.apiService;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ValueListenableBuilder(
        valueListenable: appState,
        builder: (context, currentState, _) {
          return Column(
            children: [
              Row(
                children: [
                  Tooltip(
                    message: '生成插入的文本的图像',
                    child: MaterialButton(
                      color: Theme.of(context).colorScheme.onBackground,
                      textColor: Theme.of(context).colorScheme.background,
                      disabledTextColor: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.5),
                      disabledColor: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      onPressed: currentState.isGenerating ||
                              currentState.selectedChat == null
                          ? null
                          : () => _generateImage(
                                currentState,
                                appState,
                                apiService,
                              ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.lens_blur),
                            SizedBox(width: 4),
                            Text('生成图像'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              RawKeyboardListener(
                focusNode: _keyboardListenerFocusNode,
                onKey: (RawKeyEvent event) {
                  if (event.runtimeType == RawKeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.enter &&
                      event.isShiftPressed) {
                    // Prevent the default behavior of Enter key
                    return;
                  }
                  // if (event.runtimeType == RawKeyDownEvent &&
                  //     event.logicalKey == LogicalKeyboardKey.enter) {
                  //   _onSend(currentState, appState, apiService);
                  // }
                },
                child: TextField(
                  maxLines: null,
                  minLines: 1,
                  maxLength: 1000,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  controller: _textController,
                  focusNode: _fieldFocusNode,
                  enabled: currentState.selectedChat != null ||
                      currentState.isGenerating,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(gapPadding: 12),
                    hintText: appLocals.dasboardFieldInput,
                    suffix: Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: ElevatedButton(
                        onPressed: () =>
                            _onSend(currentState, appState, apiService),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(appLocals.send),
                            const SizedBox(width: 8),
                            const Icon(Icons.send, size: 15),
                          ],
                        ),
                      ),
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _onSend(currentState, appState, apiService);
                    }
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
