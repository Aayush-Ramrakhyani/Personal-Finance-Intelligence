import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'ai_models.dart';
import 'ai_repository.dart';

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

final _aiDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: 'http://localhost:8000/api/v1'));
});

final aiRepositoryProvider = Provider<AIRepository>((ref) {
  return AIRepository(ref.watch(_aiDioProvider));
});

// ---------------------------------------------------------------------------
// Conversations list
// ---------------------------------------------------------------------------

final conversationsProvider =
    FutureProvider<List<ConversationModel>>((ref) async {
  return ref.watch(aiRepositoryProvider).getConversations();
});

// ---------------------------------------------------------------------------
// Single conversation with messages
// ---------------------------------------------------------------------------

final conversationProvider =
    FutureProvider.family<ConversationModel, String>((ref, id) async {
  return ref.watch(aiRepositoryProvider).getConversation(id);
});

// ---------------------------------------------------------------------------
// Messages notifier
// ---------------------------------------------------------------------------

class MessagesNotifier
    extends FamilyAsyncNotifier<List<MessageModel>, String> {
  @override
  Future<List<MessageModel>> build(String conversationId) async {
    return ref
        .watch(aiRepositoryProvider)
        .getMessages(conversationId);
  }

  Future<void> sendMessage(String content) async {
    final conversationId = arg;
    final repo = ref.read(aiRepositoryProvider);

    // Optimistically add user message
    final tempUserMsg = MessageModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      role: MessageRole.user,
      content: content,
      createdAt: DateTime.now(),
    );

    // Add typing indicator
    final typingMsg = MessageModel(
      id: 'typing_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      role: MessageRole.assistant,
      content: '',
      createdAt: DateTime.now(),
      isStreaming: true,
    );

    state = AsyncData([
      ...state.valueOrNull ?? [],
      tempUserMsg,
      typingMsg,
    ]);

    try {
      final response = await repo.sendMessage(conversationId, content);
      // Replace typing indicator with real response
      final currentMessages = state.valueOrNull ?? [];
      final updated = currentMessages
          .where((m) => m.id != typingMsg.id)
          .toList();

      // Find and replace temp user message with real one if needed
      state = AsyncData([...updated, response]);

      // Refresh conversations to update last message
      ref.invalidate(conversationsProvider);
    } catch (e) {
      // Remove typing indicator and show error
      state = AsyncData(
        (state.valueOrNull ?? [])
            .where((m) => m.id != typingMsg.id)
            .toList(),
      );
      rethrow;
    }
  }
}

final messagesProvider = AsyncNotifierProviderFamily<MessagesNotifier,
    List<MessageModel>, String>(MessagesNotifier.new);

// ---------------------------------------------------------------------------
// Conversation creation notifier
// ---------------------------------------------------------------------------

class ConversationNotifier
    extends AsyncNotifier<List<ConversationModel>> {
  @override
  Future<List<ConversationModel>> build() async {
    return ref.watch(aiRepositoryProvider).getConversations();
  }

  Future<ConversationModel> createConversation(String? title) async {
    final repo = ref.read(aiRepositoryProvider);
    final conversation = await repo.createConversation(title);
    ref.invalidate(conversationsProvider);
    return conversation;
  }

  Future<void> deleteConversation(String id) async {
    await ref.read(aiRepositoryProvider).deleteConversation(id);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(aiRepositoryProvider).getConversations());
  }
}

final conversationNotifierProvider = AsyncNotifierProvider<
    ConversationNotifier,
    List<ConversationModel>>(ConversationNotifier.new);
