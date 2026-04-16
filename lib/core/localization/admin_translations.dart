import 'package:get/get.dart';

class AdminTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      // ── Enum Translations ──
      // role_type
      'enum_role_user': 'User',
      'enum_role_admin': 'Admin',
      'enum_role_agent': 'Agent',
      // user_status
      'enum_user_status_active': 'Active',
      'enum_user_status_blocked': 'Blocked',
      'enum_user_status_suspended': 'Suspended',
      // account_tier
      'enum_tier_free': 'Free',
      'enum_tier_verified': 'Verified',
      'enum_tier_vip': 'VIP',
      // kyc_status
      'enum_kyc_unverified': 'Unverified',
      'enum_kyc_pending': 'Pending',
      'enum_kyc_verified': 'Verified',
      'enum_kyc_rejected': 'Rejected',
      // txn_type
      'enum_txn_deposit': 'Deposit',
      'enum_txn_withdrawal': 'Withdrawal',
      'enum_txn_transfer_in': 'Transfer In',
      'enum_txn_transfer_out': 'Transfer Out',
      'enum_txn_investment': 'Investment',
      'enum_txn_investment_return': 'Investment Return',
      'enum_txn_loan_disbursement': 'Loan Disbursement',
      'enum_txn_loan_repayment': 'Loan Repayment',
      'enum_txn_reward': 'Reward',
      'enum_txn_adjustment': 'Adjustment',
      'enum_txn_profit': 'Profit',
      'enum_txn_fee': 'Fee',
      'enum_txn_admin_credit': 'Admin Credit',
      'enum_txn_admin_debit': 'Admin Debit',
      // txn_status
      'enum_status_pending': 'Pending',
      'enum_status_processing': 'Processing',
      'enum_status_completed': 'Completed',
      'enum_status_approved': 'Approved',
      'enum_status_rejected': 'Rejected',
      'enum_status_cancelled': 'Cancelled',
      'enum_status_failed': 'Failed',
      // investment_status
      'enum_invest_active': 'Active',
      'enum_invest_completed': 'Completed',
      'message_deleted': 'This message has been deleted',
      'enum_invest_cancelled': 'Cancelled',
      'enum_invest_matured': 'Matured',
      // loan_status
      'enum_loan_pending': 'Pending',
      'enum_loan_current': 'Current',
      'enum_loan_paid': 'Paid',
      'enum_loan_delayed': 'Delayed',
      'enum_loan_defaulted': 'Defaulted',
      // agent_status
      'enum_agent_active': 'Active',
      'enum_agent_inactive': 'Inactive',
      'enum_agent_suspended': 'Suspended',
      // severity_type
      'enum_severity_info': 'Info',
      'enum_severity_warning': 'Warning',
      'enum_severity_critical': 'Critical',
      // kyc_doc_type
      'enum_doc_id_card_front': 'ID Card (Front)',
      'enum_doc_id_card_back': 'ID Card (Back)',
      'enum_doc_passport': 'Passport',
      'enum_doc_selfie': 'Selfie',
      'enum_doc_proof_of_address': 'Proof of Address',
      'enum_doc_other': 'Other',
      // audit_log_type
      'enum_audit_auth': 'Authentication',
      'enum_audit_user_management': 'User Management',
      'enum_audit_financial': 'Financial',
      'enum_audit_system': 'System',
      'enum_audit_security': 'Security',
      // audit_log_status
      'enum_audit_success': 'Success',
      'enum_audit_failed': 'Failed',
      'enum_audit_warning': 'Warning',
      // message_type
      'enum_msg_text': 'Text',
      'enum_msg_image': 'Image',
      'enum_msg_file': 'File',
      'enum_msg_system': 'System',
      // point_rule_type
      'enum_point_earn': 'Earn',
      'enum_point_spend': 'Spend',
      'enum_point_bonus': 'Bonus',
      // prize_type
      'enum_prize_points': 'Points',
      'enum_prize_cash': 'Cash',
      'enum_prize_voucher': 'Voucher',
      'enum_prize_nothing': 'Nothing',
      // limit_tier
      'enum_limit_free': 'Free',
      'enum_limit_verified': 'Verified',
      'enum_limit_vip': 'VIP',
      // fee_category
      'enum_fee_deposit': 'Deposit',
      'enum_fee_withdrawal': 'Withdrawal',
      'enum_fee_transfer': 'Transfer',
      'enum_fee_investment': 'Investment',
    },
    'ar_SA': {
      // ── ترجمات الأنواع (Enum Translations) ──
      // role_type (نوع الدور)
      'enum_role_user': 'مستخدم',
      'enum_role_admin': 'مدير',
      'enum_role_agent': 'وكيل',
      // user_status (حالة المستخدم)
      'enum_user_status_active': 'نشط',
      'enum_user_status_blocked': 'محظور',
      'enum_user_status_suspended': 'معلّق',
      // account_tier (مستوى الحساب)
      'enum_tier_free': 'مجاني',
      'enum_tier_verified': 'موثّق',
      'enum_tier_vip': 'مميز',
      // kyc_status (حالة التحقق)
      'enum_kyc_unverified': 'غير موثّق',
      'enum_kyc_pending': 'قيد المراجعة',
      'enum_kyc_verified': 'موثّق',
      'enum_kyc_rejected': 'مرفوض',
      // txn_type (نوع المعاملة)
      'enum_txn_deposit': 'إيداع',
      'enum_txn_withdrawal': 'سحب',
      'enum_txn_transfer_in': 'تحويل وارد',
      'enum_txn_transfer_out': 'تحويل صادر',
      'enum_txn_investment': 'استثمار',
      'enum_txn_investment_return': 'عائد استثمار',
      'enum_txn_loan_disbursement': 'صرف قرض',
      'enum_txn_loan_repayment': 'سداد قرض',
      'enum_txn_reward': 'مكافأة',
      'enum_txn_adjustment': 'تسوية',
      'enum_txn_profit': 'ربح',
      'enum_txn_fee': 'رسوم',
      'enum_txn_admin_credit': 'إضافة إدارية',
      'enum_txn_admin_debit': 'خصم إداري',
      // txn_status (حالة المعاملة)
      'enum_status_pending': 'قيد الانتظار',
      'enum_status_processing': 'قيد المعالجة',
      'enum_status_completed': 'مكتملة',
      'enum_status_approved': 'موافق عليها',
      'enum_status_rejected': 'مرفوضة',
      'enum_status_cancelled': 'ملغاة',
      'enum_status_failed': 'فشلت',
      // investment_status (حالة الاستثمار)
      'enum_invest_active': 'نشط',
      'enum_invest_completed': 'مكتمل',
      'enum_invest_cancelled': 'ملغي',
      'enum_invest_matured': 'مستحق',
      // loan_status (حالة القرض)
      'enum_loan_pending': 'قيد الانتظار',
      'enum_loan_current': 'جاري',
      'enum_loan_paid': 'مدفوع',
      'enum_loan_delayed': 'متأخر',
      'enum_loan_defaulted': 'متعثر',
      // agent_status (حالة الوكيل)
      'enum_agent_active': 'نشط',
      'enum_agent_inactive': 'غير نشط',
      'enum_agent_suspended': 'معلّق',
      // severity_type (مستوى الخطورة)
      'enum_severity_info': 'معلومات',
      'enum_severity_warning': 'تحذير',
      'enum_severity_critical': 'حرج',
      // kyc_doc_type (نوع وثيقة التحقق)
      'enum_doc_id_card_front': 'بطاقة هوية (أمامية)',
      'enum_doc_id_card_back': 'بطاقة هوية (خلفية)',
      'enum_doc_passport': 'جواز سفر',
      'message_deleted': 'تم حذف هذه الرسالة',
      'enum_doc_selfie': 'صورة شخصية',
      'enum_doc_proof_of_address': 'إثبات عنوان',
      'enum_doc_other': 'أخرى',
      // audit_log_type (نوع سجل المراجعة)
      'enum_audit_auth': 'مصادقة',
      'enum_audit_user_management': 'إدارة المستخدمين',
      'enum_audit_financial': 'مالي',
      'enum_audit_system': 'نظام',
      'enum_audit_security': 'أمني',
      // audit_log_status (حالة سجل المراجعة)
      'enum_audit_success': 'ناجح',
      'enum_audit_failed': 'فاشل',
      'enum_audit_warning': 'تحذير',
      // message_type (نوع الرسالة)
      'enum_msg_text': 'نص',
      'enum_msg_image': 'صورة',
      'enum_msg_file': 'ملف',
      'enum_msg_system': 'نظام',
      // point_rule_type (نوع قاعدة النقاط)
      'enum_point_earn': 'كسب',
      'enum_point_spend': 'إنفاق',
      'enum_point_bonus': 'مكافأة',
      // prize_type (نوع الجائزة)
      'enum_prize_points': 'نقاط',
      'enum_prize_cash': 'نقدي',
      'enum_prize_voucher': 'قسيمة',
      'enum_prize_nothing': 'لا شيء',
      // limit_tier (مستوى الحد)
      'enum_limit_free': 'مجاني',
      'enum_limit_verified': 'موثّق',
      'enum_limit_vip': 'مميز',
      // fee_category (فئة الرسوم)
      'enum_fee_deposit': 'إيداع',
      'enum_fee_withdrawal': 'سحب',
      'enum_fee_transfer': 'تحويل',
      'enum_fee_investment': 'استثمار',
    },
  };
}
