import 'package:dio/dio.dart';
import 'ai_models.dart';

class AIRepository {
  final Dio _dio;

  AIRepository(this._dio);

  Future<List<ConversationModel>> getConversations() async {
    final response = await _dio.get('/ai/conversations');
    final data = response.data as List<dynamic>;
    return data
        .map((e) =>
            ConversationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ConversationModel> createConversation(String? title) async {
    final response = await _dio.post(
      '/ai/conversations',
      data: {'title': title ?? 'New Conversation'},
    );
    return ConversationModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<ConversationModel> getConversation(String id) async {
    final response = await _dio.get('/ai/conversations/$id');
    return ConversationModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    final response =
        await _dio.get('/ai/conversations/$conversationId/messages');
    final data = response.data as List<dynamic>;
    return data
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MessageModel> sendMessage(
      String conversationId, String message) async {
    final response = await _dio.post(
      '/ai/conversations/$conversationId/messages',
      data: {'content': message, 'role': 'user'},
    );
    return MessageModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteConversation(String id) async {
    await _dio.delete('/ai/conversations/$id');
  }
}
