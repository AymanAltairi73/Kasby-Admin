import 'package:flutter_test/flutter_test.dart';
import 'package:kasby_admin/core/services/crash_reporting/crash_error_category.dart';
import 'package:kasby_admin/core/services/crash_reporting/crash_breadcrumb.dart';
import 'package:kasby_admin/core/services/crash_reporting_service.dart';

void main() {
  group('Admin CrashReportingService', () {
    test('isCollectionEnabled is false in debug/test mode', () {
      expect(CrashReportingService.isCollectionEnabled, isFalse);
    });

    test('AdminModule constants are defined', () {
      expect(AdminModule.userManagement, isNotEmpty);
      expect(AdminModule.walletManagement, isNotEmpty);
      expect(AdminModule.investments, isNotEmpty);
    });

    test('categoryFromFeature maps admin features', () {
      expect(
        CrashReportingService.categoryFromFeature('transactions'),
        CrashErrorCategory.wallet,
      );
      expect(
        CrashReportingService.categoryFromFeature('dashboard'),
        CrashErrorCategory.admin,
      );
    });

    test('recordError completes without initialized Firebase', () async {
      await expectLater(
        CrashReportingService.recordError(
          Exception('admin test'),
          StackTrace.current,
          reason: 'unit_test',
        ),
        completes,
      );
    });

    test('setAdminContext and log complete safely in debug', () async {
      await expectLater(
        CrashReportingService.setAdminContext(
          module: AdminModule.approvals,
          operation: 'approve_withdrawal',
        ),
        completes,
      );
      await expectLater(
        CrashReportingService.log(CrashBreadcrumb.withdrawalApproved),
        completes,
      );
    });
  });
}
