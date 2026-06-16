/// KycDocument Model
import '../../../core/services/app_logger_service.dart';

class KycDocument {
  final String id;
  final String userId;
  final String documentType; // selfie, id_card_front, id_card_back
  final String documentUrl;
  final String status; // pending, approved, rejected
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final DateTime uploadedAt;
  final String? userName; // From profiles JOIN
  final String? userPhone;
  final String? userEmail;

  KycDocument({
    required this.id,
    required this.userId,
    required this.documentType,
    required this.documentUrl,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
    required this.uploadedAt,
    this.userName,
    this.userPhone,
    this.userEmail,
  });

  factory KycDocument.fromJson(Map<String, dynamic> json) {
    try {
    return KycDocument(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      documentType: json['document_type'] ?? '',
      documentUrl: json['document_url'] ?? '',
      status: json['status'] ?? 'pending',
      reviewedBy: json['reviewed_by'],
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'])
          : null,
      rejectionReason: json['rejection_reason'],
      uploadedAt: DateTime.tryParse(json['uploaded_at'] ?? '') ?? DateTime.now(),
      userName: json['profiles'] != null 
          ? json['profiles']['full_name'] 
          : (json['profiles!kyc_documents_user_id_fkey'] != null 
              ? json['profiles!kyc_documents_user_id_fkey']['full_name'] 
              : null),
      userPhone: json['profiles'] != null 
          ? json['profiles']['phone'] 
          : (json['profiles!kyc_documents_user_id_fkey'] != null 
              ? json['profiles!kyc_documents_user_id_fkey']['phone'] 
              : null),
      userEmail: json['profiles'] != null 
          ? json['profiles']['email'] 
          : (json['profiles!kyc_documents_user_id_fkey'] != null 
              ? json['profiles!kyc_documents_user_id_fkey']['email'] 
              : null),
    );
    } catch (e, stack) {
      AppLoggerService.debugTrace(
        className: 'KycDocument',
        method: 'fromJson',
        feature: 'KYC',
        status: 'FAILED',
        params: {'id': json['id']?.toString()},
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
    };
  }
}
