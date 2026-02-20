Security Architecture & User Permission Matrix: Kasby User App
This document outlines the strict security permissions and architectural constraints for the Kasby User App to ensure financial integrity and data privacy.

Proposed Security Principles
Zero Direct Mutation: Users CANNOT directly modify sensitive financial fields (balances, statuses, interest rates).
RPC-Only State Changes: All financial state transitions (investing, withdrawing, loan requests) must occur via secure PostgreSQL RPC functions.
RLS (Row Level Security): Strict user_id = auth.uid() checks for all data access.
Admin Pre-Approval: High-risk actions (Withdrawals, KYC, Loans) require manual administrator verification.
User Permission Matrix (UPM) - Detailed Description
1. Authentication & Onboarding
Users have the authority to read and create their accounts during the Login and Signup processes. However, they are strictly prohibited from modifying core authentication logic or deleting their account records without intervention. KYC Upload allows users to read, create, and update their documents; however, any changes are subject to manual Admin Approval before the user's status transitions to 'verified'.

2. Dashboard & System Visibility
The Dashboard is a read-only interface. Users can view their financial summaries but cannot create or modify any dashboard components. Similarly, Notifications allow users to read their alerts and update their 'read' status or delete local notifications, but they cannot create system-wide broadcasts.

3. Financial Management (Wallet & Deposits)
The Wallet is strictly read-only for the user. Any balance updates are forbidden. For Deposits, users can create a deposit request and upload payment proof. This process is subject to Admin Approval where the administrator verifies the proof before the balance is updated via a system process. KYC Verification is a prerequisite for accessing advanced wallet features.

4. Transactions & Withdrawals
Users can read their transaction history but are blocked from any create, update, or delete operations on historical data. Withdrawals require the execution of a secure RPC Function to validate funds and create a 'pending' request, which then necessitates Admin Approval before final disbursement.

5. Investments & Loans
In the Invest Market, users can read available plans. Creating a new investment requires a secure RPC Function to ensure atomic balance deduction. Once an investment is "Active", users have no permission to modify it. Loans follow a similar protocol: users can create a request via RPC, which remains 'pending' until Admin Approval is granted.

6. Subscriptions, Rewards & Support
Subscriptions are managed via RPC Functions to handle tier transitions and payments. Points & Rewards are read-only, with a 'Claim' action requiring an RPC to prevent double-spending. For Support, users can read and create tickets/messages but cannot modify or delete them once sent. Settings allow for basic profile updates (like bio or avatar) but exclude core financial identifiers.

Admin Permission Matrix (APM) - Detailed Description
1. Operational Oversight
Admins have full Read access to all system modules, including dashboards, user profiles, and financial logs. They are authorized to Create and Update agents, investment plans, and system settings to ensure continuous operation and platform health.

2. Financial Governance
Admins act as the primary validators for all high-risk financial flows. They have the authority to Approve or Reject deposit requests, withdrawals, and loan applications. While they can trigger balance adjustments via audited RPC functions, they are strictly prohibited from deleting any finalized transaction records to preserve the integrity of the ledger.

3. User & KYC Management
Admins manage the user lifecycle by verifying or rejecting KYC documentation. They possess the authority to Block or Activate user accounts based on compliance reviews. They can also manually verify user accounts to grant access to premium tiers.

4. System & Security Control
Admins manage platform-wide configurations, including interest rates, subscription tiers, and reward rules. In case of emergencies, they have the authority to trigger 'System Freezes' or pause specific financial flows (e.g., pausing withdrawals during maintenance). Every administrative action is automatically logged in the Audit Logs for accountability.

Admin Forbidden Actions
- Direct Database Manipulation: Admins must NOT manually edit the `wallets` table; all changes must go through audited RPCs.
- Transaction Deletion: Historical financial data is append-only and cannot be removed.
- Unauthorized Data Access: Admins are restricted by internal policies from accessing user-specific private communication unless necessary for support.

Forbidden Actions (Hard Constraints)
CAUTION

Financial Integrity Violations The following actions are strictly prohibited and must be blocked at the database level:

Balance Modification: Users cannot update available_balance or profit_balance.
Transaction Forgery: Users cannot update status or amount after creation.
Active Investment Tampering: Users cannot change terms or interest rates of active investments.
Loan Status Override: Users cannot mark loans as paid or current.
Privacy Violations: Users cannot query profiles or wallets belonging to other user_ids.
Verification Plan
Automated Tests
RLS Policy Verification:
SELECT * FROM wallets as User A should return 0 rows for User B's wallet.
Field Immunity Test:
Attempt UPDATE wallets SET available_balance = 999999 as a user; verify it fails with PERMISSION_DENIED.
RPC Boundary Test:
Verify create_investment RPC only succeeds if balance >= investment amount.
Manual Verification
KYC Workflow: Verify that a user cannot see "Wallet" features until KYC is uploaded and approved (UI state check).
Withdrawal Flow: Verify a withdrawal transaction stays in pending until an admin manually approves it in the Admin Dashboard.