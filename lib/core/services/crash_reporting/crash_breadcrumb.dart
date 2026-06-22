/// Named breadcrumb events for Admin Crashlytics timeline reconstruction.
abstract final class CrashBreadcrumb {
  // Authentication
  static const loginStarted = 'Admin login started';
  static const loginCompleted = 'Admin login completed';
  static const loginFailed = 'Admin login failed';
  static const logout = 'Admin logout';

  // User management
  static const userBlocked = 'User blocked';
  static const userActivated = 'User activated';
  static const userDeleted = 'User deleted';

  // Financial approvals
  static const investmentApproved = 'Investment approved';
  static const withdrawalApproved = 'Withdrawal approved';
  static const loanApproved = 'Loan approved';

  // KYC
  static const kycReviewStarted = 'KYC review started';
  static const kycApproved = 'KYC approved';
  static const kycRejected = 'KYC rejected';

  // Navigation
  static const screenOpened = 'Admin screen opened';
  static const moduleOpened = 'Admin module opened';
}

abstract final class CrashCustomKey {
  static const errorCategory = 'error_category';
  static const adminId = 'admin_id';
  static const adminRole = 'admin_role';
  static const adminPrivilege = 'admin_privilege';
  static const currentModule = 'current_module';
  static const currentOperation = 'current_operation';
  static const screenName = 'screen_name';
  static const currentRoute = 'current_route';
  static const appVersion = 'app_version';
  static const buildNumber = 'build_number';
  static const supabaseErrorType = 'supabase_error_type';
  static const rpcName = 'rpc_name';
  static const tableName = 'table_name';
  static const httpStatus = 'http_status';
  static const postgrestCode = 'postgrest_code';
  static const connectionQuality = 'connection_quality';
  static const isConnected = 'is_connected';
}

/// Admin dashboard modules for diagnostic context.
abstract final class AdminModule {
  static const userManagement = 'user_management';
  static const walletManagement = 'wallet_management';
  static const marketplace = 'marketplace';
  static const investments = 'investments';
  static const kyc = 'kyc';
  static const reports = 'reports';
  static const notifications = 'notifications';
  static const loans = 'loans';
  static const chat = 'chat';
  static const settings = 'settings';
  static const approvals = 'approvals';
  static const systemHealth = 'system_health';
}
