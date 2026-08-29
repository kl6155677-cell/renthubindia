import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/support_ticket_model.dart';
import 'package:dio/dio.dart';

class SupportRepository {
  final Dio _dio = ApiService.dio;

  Future<List<SupportTicketModel>> getMyTickets() async {
    final response = await _dio.get(ApiConstants.tickets);
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((json) => SupportTicketModel.fromJson(json)).toList();
  }

  Future<SupportTicketModel> createTicket(String subject, String message) async {
    final response = await _dio.post(ApiConstants.tickets, data: {
      'subject': subject,
      'message': message,
    });
    return SupportTicketModel.fromJson(response.data['data']);
  }
}
