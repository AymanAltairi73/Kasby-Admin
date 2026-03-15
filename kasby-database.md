 ## عرض جميع الجداول (Tables):
| table_schema | table_name                 |
| ------------ | -------------------------- |
| auth         | audit_log_entries          |
| auth         | custom_oauth_providers     |
| auth         | flow_state                 |
| auth         | identities                 |
| auth         | instances                  |
| auth         | mfa_amr_claims             |
| auth         | mfa_challenges             |
| auth         | mfa_factors                |
| auth         | oauth_authorizations       |
| auth         | oauth_client_states        |
| auth         | oauth_clients              |
| auth         | oauth_consents             |
| auth         | one_time_tokens            |
| auth         | refresh_tokens             |
| auth         | saml_providers             |
| auth         | saml_relay_states          |
| auth         | schema_migrations          |
| auth         | sessions                   |
| auth         | sso_domains                |
| auth         | sso_providers              |
| auth         | users                      |
| public       | activity_logs              |
| public       | admin_profiles             |
| public       | admin_sessions             |
| public       | ads                        |
| public       | agents                     |
| public       | audit_logs                 |
| public       | chat_conversations         |
| public       | chat_messages              |
| public       | countries                  |
| public       | currencies                 |
| public       | daily_check_ins            |
| public       | enum_translations          |
| public       | faqs                       |
| public       | fees                       |
| public       | investment_plans           |
| public       | kyc_documents              |
| public       | loans                      |
| public       | notifications              |
| public       | otp_rate_limits            |
| public       | phone_otps                 |
| public       | point_history              |
| public       | point_rules                |
| public       | prizes                     |
| public       | profiles                   |
| public       | rewards                    |
| public       | spin_results               |
| public       | spin_wheel_rewards         |
| public       | subscription_plans         |
| public       | subscriptions              |
| public       | support_conversations      |
| public       | support_messages           |
| public       | system_settings            |
| public       | terms_sections             |
| public       | transaction_limits         |
| public       | transactions               |
| public       | user_activities            |
| public       | user_investments           |
| public       | user_points                |
| public       | wallets                    |
| realtime     | messages                   |
| realtime     | messages_2026_03_12        |
| realtime     | messages_2026_03_13        |
| realtime     | messages_2026_03_14        |
| realtime     | messages_2026_03_15        |
| realtime     | messages_2026_03_16        |
| realtime     | messages_2026_03_17        |
| realtime     | messages_2026_03_18        |
| realtime     | schema_migrations          |
| realtime     | subscription               |
| storage      | buckets                    |
| storage      | buckets_analytics          |
| storage      | buckets_vectors            |
| storage      | migrations                 |
| storage      | objects                    |
| storage      | s3_multipart_uploads       |
| storage      | s3_multipart_uploads_parts |
| storage      | vector_indexes             |
| vault        | secrets                    |

## Row Level Security:
| schemaname | tablename          | policyname                                |
| ---------- | ------------------ | ----------------------------------------- |
| storage    | objects            | Allow admins to view all kyc documents    |
| storage    | objects            | Allow authenticated uploads to KYC folder |
| storage    | objects            | Allow users to view their own documents   |
| storage    | objects            | Public Access                             |
| storage    | objects            | Public can view docs                      |
| storage    | objects            | Users can delete their own avatar         |
| storage    | objects            | Users can manage their own documents      |
| storage    | objects            | Users can update their own avatar         |
| storage    | objects            | Users can upload KYC docs                 |
| storage    | objects            | Users can upload their own avatar         |
| public     | profiles           | Admin full access                         |
| public     | profiles           | Anyone can view profiles of active agents |
| public     | profiles           | Users can update own profile              |
| public     | profiles           | Users can view own profile                |
| public     | profiles           | Users can view their own profile          |
| public     | profiles           | Users update own                          |
| public     | profiles           | Users view own                            |
| public     | profiles           | p_admin_profiles                          |
| public     | profiles           | p_user_select_profile                     |
| public     | profiles           | p_user_update_profile                     |
| public     | wallets            | Admin scan wallets                        |
| public     | wallets            | User view wallet                          |
| public     | wallets            | Users can view own wallet                 |
| public     | wallets            | Users can view their own wallet           |
| public     | wallets            | p_admin_wallets                           |
| public     | wallets            | p_user_select_wallet                      |
| public     | transactions       | Admin scan txns                           |
| public     | transactions       | Admins can manage all transactions        |
| public     | transactions       | User insert requests                      |
| public     | transactions       | User view txns                            |
| public     | transactions       | Users can view own transactions           |
| public     | transactions       | p_admin_txns_insert                       |
| public     | transactions       | p_admin_txns_select                       |
| public     | transactions       | p_user_insert_txn                         |
| public     | transactions       | p_user_select_txn                         |
| public     | notifications      | Admin scan notifs                         |
| public     | notifications      | User view notifs                          |
| public     | notifications      | Users can update own notifications        |
| public     | notifications      | Users can view own notifications          |
| public     | notifications      | p_admin_notif                             |
| public     | notifications      | p_user_select_notif                       |
| public     | currencies         | Anyone can view currencies                |
| public     | agents             | Admin scan agents                         |
| public     | agents             | Agent view self                           |
| public     | agents             | Agents can view their own metadata        |
| public     | agents             | Anyone can view active agents             |
| public     | investment_plans   | Anyone can view active plans              |
| public     | user_investments   | Admin scan investments                    |
| public     | user_investments   | User view investments                     |
| public     | user_investments   | Users can view own investments            |
| public     | user_investments   | p_admin_investments                       |
| public     | user_investments   | p_user_select_inv                         |
| public     | loans              | Admin scan loans                          |
| public     | loans              | User view loans                           |
| public     | loans              | Users can view own loans                  |
| public     | loans              | p_admin_loans                             |
| public     | loans              | p_user_select_loans                       |
| public     | daily_check_ins    | Admin scan checkins                       |
| public     | daily_check_ins    | Admins can manage all daily_check_ins     |
| public     | daily_check_ins    | Public check-ins are viewable by owner    |
| public     | daily_check_ins    | User insert checkin                       |
| public     | daily_check_ins    | User view checkins                        |
| public     | daily_check_ins    | Users can view own check-ins              |
| public     | user_points        | Admin scan points                         |
| public     | user_points        | User view points                          |
| public     | user_points        | Users can view own points                 |
| public     | user_points        | p_admin_points                            |
| public     | user_points        | p_user_select_points                      |
| public     | point_history      | Admin scan point_history                  |
| public     | point_history      | User view point_history                   |
| public     | point_history      | Users can view own point history          |
| public     | subscriptions      | Admin scan subs                           |
| public     | subscriptions      | User view subs                            |
| public     | subscriptions      | Users can view own subscriptions          |
| public     | subscriptions      | p_admin_sub                               |
| public     | subscriptions      | p_user_select_sub                         |
| public     | kyc_documents      | Admin scan kyc                            |
| public     | kyc_documents      | User upload kyc                           |
| public     | kyc_documents      | User view kyc                             |
| public     | kyc_documents      | Users can insert own KYC docs             |
| public     | kyc_documents      | Users can view own KYC docs               |
| public     | kyc_documents      | p_admin_kyc                               |
| public     | kyc_documents      | p_user_insert_kyc                         |
| public     | kyc_documents      | p_user_select_kyc                         |
| public     | fees               | Anyone can view fees                      |
| public     | system_settings    | Anyone can view system settings           |
| public     | chat_conversations | Admin scan chats                          |
| public     | chat_conversations | User view own chats                       |
| public     | chat_conversations | p_admin_convs                             |
| public     | chat_conversations | p_user_select_conv                        |
| public     | chat_messages      | Admin scan messages                       |
| public     | chat_messages      | User view chat messages                   |
| public     | chat_messages      | p_admin_msgs                              |
| public     | chat_messages      | p_user_insert_msg                         |
| public     | chat_messages      | p_user_select_msg                         |
| public     | spin_results       | Admin scan spins                          |
| public     | spin_results       | User view spins                           |
| public     | spin_results       | p_admin_spin                              |
| public     | spin_results       | p_user_select_spin                        |
| public     | activity_logs      | Admin scan activity                       |
-----------------------------------
## استعلام شامل لمعرفة كل القيود بالتفصيل:

| table_name             | constraint_name                                  | constraint_type |
| ---------------------- | ------------------------------------------------ | --------------- |
| activity_logs          | activity_logs_pkey                               | PRIMARY KEY     |
| activity_logs          | 2200_21784_1_not_null                            | CHECK           |
| activity_logs          | activity_logs_actor_id_fkey                      | FOREIGN KEY     |
| activity_logs          | activity_logs_severity_check                     | CHECK           |
| activity_logs          | 2200_21784_4_not_null                            | CHECK           |
| admin_profiles         | 2200_19617_1_not_null                            | CHECK           |
| admin_profiles         | admin_profiles_pkey                              | PRIMARY KEY     |
| admin_profiles         | admin_profiles_role_check                        | CHECK           |
| admin_profiles         | admin_profiles_id_fkey                           | FOREIGN KEY     |
| admin_sessions         | admin_sessions_pkey                              | PRIMARY KEY     |
| admin_sessions         | admin_sessions_admin_id_fkey                     | FOREIGN KEY     |
| admin_sessions         | 2200_22027_1_not_null                            | CHECK           |
| admin_sessions         | 2200_22027_3_not_null                            | CHECK           |
| admin_sessions         | 2200_22027_2_not_null                            | CHECK           |
| ads                    | ads_pkey                                         | PRIMARY KEY     |
| ads                    | 2200_27009_1_not_null                            | CHECK           |
| ads                    | 2200_27009_2_not_null                            | CHECK           |
| ads                    | 2200_27009_6_not_null                            | CHECK           |
| ads                    | ads_created_by_fkey                              | FOREIGN KEY     |
| agents                 | agents_user_id_fkey                              | FOREIGN KEY     |
| agents                 | 2200_17650_24_not_null                           | CHECK           |
| agents                 | 2200_17650_19_not_null                           | CHECK           |
| agents                 | 2200_17650_12_not_null                           | CHECK           |
| agents                 | agents_pkey                                      | PRIMARY KEY     |
| agents                 | 2200_17650_1_not_null                            | CHECK           |
| agents                 | agents_status_check                              | CHECK           |
| audit_log_entries      | 16494_16525_5_not_null                           | CHECK           |
| audit_log_entries      | 16494_16525_2_not_null                           | CHECK           |
| audit_log_entries      | audit_log_entries_pkey                           | PRIMARY KEY     |
| audit_logs             | audit_logs_pkey                                  | PRIMARY KEY     |
| audit_logs             | 2200_22043_1_not_null                            | CHECK           |
| audit_logs             | audit_logs_admin_id_fkey                         | FOREIGN KEY     |
| audit_logs             | 2200_22043_3_not_null                            | CHECK           |
| buckets                | buckets_pkey                                     | PRIMARY KEY     |
| buckets                | 16542_17130_2_not_null                           | CHECK           |
| buckets                | 16542_17130_11_not_null                          | CHECK           |
| buckets                | 16542_17130_1_not_null                           | CHECK           |
| buckets_analytics      | 16542_17250_5_not_null                           | CHECK           |
| buckets_analytics      | 16542_17250_4_not_null                           | CHECK           |
| buckets_analytics      | 16542_17250_6_not_null                           | CHECK           |
| buckets_analytics      | 16542_17250_2_not_null                           | CHECK           |
| buckets_analytics      | 16542_17250_3_not_null                           | CHECK           |
| buckets_analytics      | buckets_analytics_pkey                           | PRIMARY KEY     |
| buckets_analytics      | 16542_17250_1_not_null                           | CHECK           |
| chat_conversations     | chat_conversations_user_id_fkey                  | FOREIGN KEY     |
| chat_conversations     | chat_conversations_agent_id_fkey                 | FOREIGN KEY     |
| chat_conversations     | chat_conversations_assigned_admin_id_fkey        | FOREIGN KEY     |
| chat_conversations     | chat_conversations_unread_user_count_check       | CHECK           |
| chat_conversations     | chat_conversations_unread_admin_count_check      | CHECK           |
| chat_conversations     | 2200_19719_1_not_null                            | CHECK           |
| chat_conversations     | chat_conversations_pkey                          | PRIMARY KEY     |
| chat_conversations     | 2200_19719_2_not_null                            | CHECK           |
| chat_messages          | chat_messages_pkey                               | PRIMARY KEY     |
| chat_messages          | chat_messages_sender_type_check                  | CHECK           |
| chat_messages          | chat_messages_conversation_id_fkey               | FOREIGN KEY     |
| chat_messages          | 2200_19752_4_not_null                            | CHECK           |
| chat_messages          | 2200_19752_3_not_null                            | CHECK           |
| chat_messages          | 2200_19752_5_not_null                            | CHECK           |
| chat_messages          | 2200_19752_1_not_null                            | CHECK           |
| chat_messages          | 2200_19752_2_not_null                            | CHECK           |
| countries              | countries_pkey                                   | PRIMARY KEY     |
| countries              | 2200_19650_1_not_null                            | CHECK           |
| countries              | 2200_19650_2_not_null                            | CHECK           |
| countries              | 2200_19650_3_not_null                            | CHECK           |
| currencies             | 2200_17633_1_not_null                            | CHECK           |
| currencies             | 2200_17633_2_not_null                            | CHECK           |
| currencies             | 2200_17633_3_not_null                            | CHECK           |
| currencies             | 2200_17633_5_not_null                            | CHECK           |
| currencies             | currencies_code_key                              | UNIQUE          |
| currencies             | currencies_pkey                                  | PRIMARY KEY     |
| custom_oauth_providers | 16494_17078_7_not_null                           | CHECK           |
| custom_oauth_providers | 16494_17078_24_not_null                          | CHECK           |
| custom_oauth_providers | custom_oauth_providers_pkey                      | PRIMARY KEY     |
| custom_oauth_providers | custom_oauth_providers_client_id_length          | CHECK           |
| custom_oauth_providers | custom_oauth_providers_jwks_uri_length           | CHECK           |
| custom_oauth_providers | custom_oauth_providers_userinfo_url_length       | CHECK           |
| custom_oauth_providers | custom_oauth_providers_token_url_length          | CHECK           |
| custom_oauth_providers | 16494_17078_4_not_null                           | CHECK           |
| custom_oauth_providers | custom_oauth_providers_discovery_url_length      | CHECK           |
| custom_oauth_providers | custom_oauth_providers_issuer_length             | CHECK           |
| custom_oauth_providers | custom_oauth_providers_identifier_format         | CHECK           |
| custom_oauth_providers | custom_oauth_providers_jwks_uri_https            | CHECK           |
| custom_oauth_providers | custom_oauth_providers_userinfo_url_https        | CHECK           |
| custom_oauth_providers | custom_oauth_providers_token_url_https           | CHECK           |
| custom_oauth_providers | custom_oauth_providers_authorization_url_https   | CHECK           |
| custom_oauth_providers | 16494_17078_1_not_null                           | CHECK           |
| custom_oauth_providers | 16494_17078_2_not_null                           | CHECK           |
| custom_oauth_providers | custom_oauth_providers_oauth2_requires_endpoints | CHECK           |
| custom_oauth_providers | 16494_17078_3_not_null                           | CHECK           |
| custom_oauth_providers | custom_oauth_providers_name_length               | CHECK           |
| custom_oauth_providers | custom_oauth_providers_oidc_discovery_url_https  | CHECK           |
| custom_oauth_providers | custom_oauth_providers_oidc_issuer_https         | CHECK           |
| custom_oauth_providers | 16494_17078_5_not_null                           | CHECK           |
| custom_oauth_providers | custom_oauth_providers_authorization_url_length  | CHECK           |
| custom_oauth_providers | 16494_17078_16_not_null                          | CHECK           |
| custom_oauth_providers | custom_oauth_providers_oidc_requires_issuer      | CHECK           |
| custom_oauth_providers | custom_oauth_providers_provider_type_check       | CHECK           |
| custom_oauth_providers | 16494_17078_6_not_null                           | CHECK           |
| custom_oauth_providers | 16494_17078_11_not_null                          | CHECK           |
| custom_oauth_providers | custom_oauth_providers_identifier_key            | UNIQUE          |
## عرض جميع Functions:


| routine_schema | routine_name                          | data_type                |
| -------------- | ------------------------------------- | ------------------------ |
| vault          | _crypto_aead_det_decrypt              | bytea                    |
| graphql        | _internal_resolve                     | jsonb                    |
| realtime       | apply_rls                             | USER-DEFINED             |
| extensions     | armor                                 | text                     |
| extensions     | armor                                 | text                     |
| realtime       | broadcast_changes                     | void                     |
| realtime       | build_prepared_statement_sql          | text                     |
| public         | buy_subscription                      | jsonb                    |
| storage        | can_insert_object                     | void                     |
| realtime       | cast                                  | jsonb                    |
| realtime       | check_equality_op                     | boolean                  |
| public         | check_otp_rate_limit                  | boolean                  |
| public         | claim_spin_reward                     | jsonb                    |
| public         | cleanup_expired_otps                  | void                     |
| graphql        | comment_directive                     | jsonb                    |
| public         | create_investment                     | jsonb                    |
| public         | create_loan                           | jsonb                    |
| vault          | create_secret                         | uuid                     |
| public         | create_transfer                       | jsonb                    |
| public         | create_withdrawal                     | jsonb                    |
| extensions     | crypt                                 | text                     |
| public         | daily_check_in                        | json                     |
| extensions     | dearmor                               | bytea                    |
| extensions     | decrypt                               | bytea                    |
| extensions     | decrypt_iv                            | bytea                    |
| extensions     | digest                                | bytea                    |
| extensions     | digest                                | bytea                    |
| auth           | email                                 | text                     |
| extensions     | encrypt                               | bytea                    |
| extensions     | encrypt_iv                            | bytea                    |
| storage        | enforce_bucket_name_length            | trigger                  |
| graphql        | exception                             | text                     |
| storage        | extension                             | text                     |
| storage        | filename                              | text                     |
| public         | fn_admin_dashboard                    | record                   |
| public         | fn_create_investment                  | uuid                     |
| public         | fn_credit_profit                      | void                     |
| public         | fn_prevent_audit_mutation             | trigger                  |
| public         | fn_prevent_txn_mutation               | trigger                  |
| public         | fn_process_deposit                    | void                     |
| public         | fn_process_deposit_v4                 | void                     |
| public         | fn_process_withdrawal                 | void                     |
| public         | fn_reject_transaction                 | void                     |
| public         | fn_transfer                           | uuid                     |
| public         | fn_translate_enum                     | text                     |
| public         | fn_update_timestamp                   | trigger                  |
| storage        | foldername                            | ARRAY                    |
| extensions     | gen_random_bytes                      | bytea                    |
| extensions     | gen_random_uuid                       | uuid                     |
| extensions     | gen_salt                              | text                     |
| extensions     | gen_salt                              | text                     |
| public         | generate_referral_code                | text                     |
| storage        | get_common_prefix                     | text                     |
| public         | get_my_role                           | USER-DEFINED             |
| graphql        | get_schema_version                    | integer                  |
| storage        | get_size_by_bucket                    | record                   |
| extensions     | grant_pg_cron_access                  | event_trigger            |
| extensions     | grant_pg_graphql_access               | event_trigger            |
| extensions     | grant_pg_net_access                   | event_trigger            |
| graphql_public | graphql                               | jsonb                    |
| public         | handle_new_profile_master             | trigger                  |
| public         | handle_new_user                       | trigger                  |
| public         | handle_updated_at                     | trigger                  |
| extensions     | hmac                                  | bytea                    |
| extensions     | hmac                                  | bytea                    |
| graphql        | increment_schema_version              | event_trigger            |
| public         | is_admin                              | boolean                  |
| public         | is_agent                              | boolean                  |
| realtime       | is_visible_through_filters            | boolean                  |
| auth           | jwt                                   | jsonb                    |
| realtime       | list_changes                          | USER-DEFINED             |
| storage        | list_multipart_uploads_with_delimiter | record                   |
| storage        | list_objects_with_delimiter           | record                   |
| storage        | operation                             | text                     |
| extensions     | pg_stat_statements                    | record                   |
| extensions     | pg_stat_statements_info               | record                   |
| extensions     | pg_stat_statements_reset              | timestamp with time zone |
| extensions     | pgp_armor_headers                     | record                   |
| extensions     | pgp_key_id                            | text                     |
| extensions     | pgp_pub_decrypt                       | text                     |
| extensions     | pgp_pub_decrypt                       | text                     |
| extensions     | pgp_pub_decrypt                       | text                     |
| extensions     | pgp_pub_decrypt_bytea                 | bytea                    |
| extensions     | pgp_pub_decrypt_bytea                 | bytea                    |
| extensions     | pgp_pub_decrypt_bytea                 | bytea                    |
| extensions     | pgp_pub_encrypt                       | bytea                    |
| extensions     | pgp_pub_encrypt                       | bytea                    |
| extensions     | pgp_pub_encrypt_bytea                 | bytea                    |
| extensions     | pgp_pub_encrypt_bytea                 | bytea                    |
| extensions     | pgp_sym_decrypt                       | text                     |
| extensions     | pgp_sym_decrypt                       | text                     |
| extensions     | pgp_sym_decrypt_bytea                 | bytea                    |
| extensions     | pgp_sym_decrypt_bytea                 | bytea                    |
| extensions     | pgp_sym_encrypt                       | bytea                    |
| extensions     | pgp_sym_encrypt                       | bytea                    |
| extensions     | pgp_sym_encrypt_bytea                 | bytea                    |
| extensions     | pgp_sym_encrypt_bytea                 | bytea                    |
| extensions     | pgrst_ddl_watch                       | event_trigger            |
| extensions     | pgrst_drop_watch                      | event_trigger            |
| storage        | protect_delete                        | trigger                  |

## عرض جميع Foreign Keys:


| table_name         | column_name         | foreign_table         | foreign_column | constraint_name                           |
| ------------------ | ------------------- | --------------------- | -------------- | ----------------------------------------- |
| profiles           | referred_by_id      | profiles              | id             | profiles_referred_by_id_fkey              |
| admin_sessions     | admin_id            | admin_profiles        | id             | admin_sessions_admin_id_fkey              |
| audit_logs         | admin_id            | admin_profiles        | id             | audit_logs_admin_id_fkey                  |
| profiles           | country_code        | countries             | code           | fk_profiles_country                       |
| chat_conversations | user_id             | profiles              | id             | chat_conversations_user_id_fkey           |
| chat_conversations | agent_id            | agents                | id             | chat_conversations_agent_id_fkey          |
| chat_conversations | assigned_admin_id   | admin_profiles        | id             | chat_conversations_assigned_admin_id_fkey |
| chat_messages      | conversation_id     | chat_conversations    | id             | chat_messages_conversation_id_fkey        |
| profiles           | referred_by         | profiles              | id             | profiles_referred_by_fkey                 |
| wallets            | user_id             | profiles              | id             | wallets_user_id_fkey                      |
| wallets            | frozen_by           | profiles              | id             | wallets_frozen_by_fkey                    |
| transactions       | user_id             | profiles              | id             | transactions_user_id_fkey                 |
| transactions       | wallet_id           | wallets               | id             | transactions_wallet_id_fkey               |
| transactions       | counterpart_user_id | profiles              | id             | transactions_counterpart_user_id_fkey     |
| transactions       | processed_by        | profiles              | id             | transactions_processed_by_fkey            |
| notifications      | user_id             | profiles              | id             | notifications_user_id_fkey                |
| notifications      | target_user_id      | profiles              | id             | notifications_target_user_id_fkey         |
| notifications      | sent_by             | profiles              | id             | notifications_sent_by_fkey                |
| agents             | user_id             | profiles              | id             | agents_user_id_fkey                       |
| investment_plans   | created_by          | profiles              | id             | investment_plans_created_by_fkey          |
| user_investments   | user_id             | profiles              | id             | user_investments_user_id_fkey             |
| user_investments   | plan_id             | investment_plans      | id             | user_investments_plan_id_fkey             |
| user_investments   | transaction_id      | transactions          | id             | user_investments_transaction_id_fkey      |
| user_investments   | approved_by         | profiles              | id             | user_investments_approved_by_fkey         |
| loans              | user_id             | profiles              | id             | loans_user_id_fkey                        |
| loans              | approved_by         | profiles              | id             | loans_approved_by_fkey                    |
| daily_check_ins    | user_id             | profiles              | id             | daily_check_ins_user_id_fkey              |
| user_points        | user_id             | profiles              | id             | user_points_user_id_fkey                  |
| point_history      | user_id             | profiles              | id             | point_history_user_id_fkey                |
| subscriptions      | user_id             | profiles              | id             | subscriptions_user_id_fkey                |
| kyc_documents      | user_id             | profiles              | id             | kyc_documents_user_id_fkey                |
| kyc_documents      | reviewed_by         | profiles              | id             | kyc_documents_reviewed_by_fkey            |
| system_settings    | updated_by          | profiles              | id             | system_settings_updated_by_fkey           |
| spin_results       | user_id             | profiles              | id             | spin_results_user_id_fkey                 |
| user_activities    | user_id             | profiles              | id             | user_activities_user_id_fkey              |
| support_messages   | conversation_id     | support_conversations | id             | support_messages_conversation_id_fkey     |

##  عرض جميع الـ Indexes:
| schemaname | tablename              | indexname                                            | indexdef                                                                                                                                                                                   |
| ---------- | ---------------------- | ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| public     | activity_logs          | idx_activity_logs_created                            | CREATE INDEX idx_activity_logs_created ON public.activity_logs USING btree (created_at DESC)                                                                                               |
| public     | activity_logs          | idx_activity_logs_actor                              | CREATE INDEX idx_activity_logs_actor ON public.activity_logs USING btree (actor_id)                                                                                                        |
| public     | activity_logs          | idx_activity_logs_entity                             | CREATE INDEX idx_activity_logs_entity ON public.activity_logs USING btree (entity_type, entity_id)                                                                                         |
| public     | activity_logs          | activity_logs_pkey                                   | CREATE UNIQUE INDEX activity_logs_pkey ON public.activity_logs USING btree (id)                                                                                                            |
| public     | admin_profiles         | admin_profiles_pkey                                  | CREATE UNIQUE INDEX admin_profiles_pkey ON public.admin_profiles USING btree (id)                                                                                                          |
| public     | admin_sessions         | admin_sessions_pkey                                  | CREATE UNIQUE INDEX admin_sessions_pkey ON public.admin_sessions USING btree (id)                                                                                                          |
| public     | admin_sessions         | idx_admin_sessions_admin                             | CREATE INDEX idx_admin_sessions_admin ON public.admin_sessions USING btree (admin_id)                                                                                                      |
| public     | ads                    | idx_ads_active_priority                              | CREATE INDEX idx_ads_active_priority ON public.ads USING btree (is_active, priority DESC)                                                                                                  |
| public     | ads                    | ads_pkey                                             | CREATE UNIQUE INDEX ads_pkey ON public.ads USING btree (id)                                                                                                                                |
| public     | agents                 | idx_agents_status                                    | CREATE INDEX idx_agents_status ON public.agents USING btree (status)                                                                                                                       |
| public     | agents                 | agents_pkey                                          | CREATE UNIQUE INDEX agents_pkey ON public.agents USING btree (id)                                                                                                                          |
| auth       | audit_log_entries      | audit_logs_instance_id_idx                           | CREATE INDEX audit_logs_instance_id_idx ON auth.audit_log_entries USING btree (instance_id)                                                                                                |
| auth       | audit_log_entries      | audit_log_entries_pkey                               | CREATE UNIQUE INDEX audit_log_entries_pkey ON auth.audit_log_entries USING btree (id)                                                                                                      |
| public     | audit_logs             | audit_logs_pkey                                      | CREATE UNIQUE INDEX audit_logs_pkey ON public.audit_logs USING btree (id)                                                                                                                  |
| public     | audit_logs             | idx_audit_created                                    | CREATE INDEX idx_audit_created ON public.audit_logs USING btree (created_at DESC)                                                                                                          |
| public     | audit_logs             | idx_audit_type                                       | CREATE INDEX idx_audit_type ON public.audit_logs USING btree (type)                                                                                                                        |
| public     | audit_logs             | idx_audit_admin                                      | CREATE INDEX idx_audit_admin ON public.audit_logs USING btree (admin_id)                                                                                                                   |
| storage    | buckets                | buckets_pkey                                         | CREATE UNIQUE INDEX buckets_pkey ON storage.buckets USING btree (id)                                                                                                                       |
| storage    | buckets                | bname                                                | CREATE UNIQUE INDEX bname ON storage.buckets USING btree (name)                                                                                                                            |
| storage    | buckets_analytics      | buckets_analytics_unique_name_idx                    | CREATE UNIQUE INDEX buckets_analytics_unique_name_idx ON storage.buckets_analytics USING btree (name) WHERE (deleted_at IS NULL)                                                           |
| storage    | buckets_analytics      | buckets_analytics_pkey                               | CREATE UNIQUE INDEX buckets_analytics_pkey ON storage.buckets_analytics USING btree (id)                                                                                                   |
| storage    | buckets_vectors        | buckets_vectors_pkey                                 | CREATE UNIQUE INDEX buckets_vectors_pkey ON storage.buckets_vectors USING btree (id)                                                                                                       |
| public     | chat_conversations     | chat_conversations_pkey                              | CREATE UNIQUE INDEX chat_conversations_pkey ON public.chat_conversations USING btree (id)                                                                                                  |
| public     | chat_conversations     | idx_conv_user                                        | CREATE INDEX idx_conv_user ON public.chat_conversations USING btree (user_id)                                                                                                              |
| public     | chat_messages          | chat_messages_pkey                                   | CREATE UNIQUE INDEX chat_messages_pkey ON public.chat_messages USING btree (id)                                                                                                            |
| public     | chat_messages          | idx_msg_created                                      | CREATE INDEX idx_msg_created ON public.chat_messages USING btree (created_at DESC)                                                                                                         |
| public     | chat_messages          | idx_msg_conv                                         | CREATE INDEX idx_msg_conv ON public.chat_messages USING btree (conversation_id)                                                                                                            |
| public     | countries              | countries_pkey                                       | CREATE UNIQUE INDEX countries_pkey ON public.countries USING btree (code)                                                                                                                  |
| public     | currencies             | currencies_pkey                                      | CREATE UNIQUE INDEX currencies_pkey ON public.currencies USING btree (id)                                                                                                                  |
| public     | currencies             | idx_currencies_base                                  | CREATE UNIQUE INDEX idx_currencies_base ON public.currencies USING btree (is_base) WHERE (is_base = true)                                                                                  |
| public     | currencies             | currencies_code_key                                  | CREATE UNIQUE INDEX currencies_code_key ON public.currencies USING btree (code)                                                                                                            |
| auth       | custom_oauth_providers | custom_oauth_providers_created_at_idx                | CREATE INDEX custom_oauth_providers_created_at_idx ON auth.custom_oauth_providers USING btree (created_at)                                                                                 |
| auth       | custom_oauth_providers | custom_oauth_providers_provider_type_idx             | CREATE INDEX custom_oauth_providers_provider_type_idx ON auth.custom_oauth_providers USING btree (provider_type)                                                                           |
| auth       | custom_oauth_providers | custom_oauth_providers_enabled_idx                   | CREATE INDEX custom_oauth_providers_enabled_idx ON auth.custom_oauth_providers USING btree (enabled)                                                                                       |
| auth       | custom_oauth_providers | custom_oauth_providers_identifier_idx                | CREATE INDEX custom_oauth_providers_identifier_idx ON auth.custom_oauth_providers USING btree (identifier)                                                                                 |
| auth       | custom_oauth_providers | custom_oauth_providers_pkey                          | CREATE UNIQUE INDEX custom_oauth_providers_pkey ON auth.custom_oauth_providers USING btree (id)                                                                                            |
| auth       | custom_oauth_providers | custom_oauth_providers_identifier_key                | CREATE UNIQUE INDEX custom_oauth_providers_identifier_key ON auth.custom_oauth_providers USING btree (identifier)                                                                          |
| public     | daily_check_ins        | idx_checkin_user_date                                | CREATE INDEX idx_checkin_user_date ON public.daily_check_ins USING btree (user_id, created_at DESC)                                                                                        |
| public     | daily_check_ins        | idx_daily_check_ins_user_id                          | CREATE INDEX idx_daily_check_ins_user_id ON public.daily_check_ins USING btree (user_id)                                                                                                   |
| public     | daily_check_ins        | daily_check_ins_pkey                                 | CREATE UNIQUE INDEX daily_check_ins_pkey ON public.daily_check_ins USING btree (id)                                                                                                        |
| public     | enum_translations      | enum_translations_enum_type_enum_value_key           | CREATE UNIQUE INDEX enum_translations_enum_type_enum_value_key ON public.enum_translations USING btree (enum_type, enum_value)                                                             |
| public     | enum_translations      | enum_translations_pkey                               | CREATE UNIQUE INDEX enum_translations_pkey ON public.enum_translations USING btree (id)                                                                                                    |
| public     | faqs                   | faqs_pkey                                            | CREATE UNIQUE INDEX faqs_pkey ON public.faqs USING btree (id)                                                                                                                              |
| public     | fees                   | fees_pkey                                            | CREATE UNIQUE INDEX fees_pkey ON public.fees USING btree (id)                                                                                                                              |
| auth       | flow_state             | idx_user_id_auth_method                              | CREATE INDEX idx_user_id_auth_method ON auth.flow_state USING btree (user_id, authentication_method)                                                                                       |
| auth       | flow_state             | flow_state_created_at_idx                            | CREATE INDEX flow_state_created_at_idx ON auth.flow_state USING btree (created_at DESC)                                                                                                    |
| auth       | flow_state             | idx_auth_code                                        | CREATE INDEX idx_auth_code ON auth.flow_state USING btree (auth_code)                                                                                                                      |
| auth       | flow_state             | flow_state_pkey                                      | CREATE UNIQUE INDEX flow_state_pkey ON auth.flow_state USING btree (id)                                                                                                                    |
| auth       | identities             | identities_user_id_idx                               | CREATE INDEX identities_user_id_idx ON auth.identities USING btree (user_id)                                                                                                               |
| auth       | identities             | identities_provider_id_provider_unique               | CREATE UNIQUE INDEX identities_provider_id_provider_unique ON auth.identities USING btree (provider_id, provider)                                                                          |
| auth       | identities             | identities_pkey                                      | CREATE UNIQUE INDEX identities_pkey ON auth.identities USING btree (id)                                                                                                                    |
| auth       | identities             | identities_email_idx                                 | CREATE INDEX identities_email_idx ON auth.identities USING btree (email text_pattern_ops)                                                                                                  |
| auth       | instances              | instances_pkey                                       | CREATE UNIQUE INDEX instances_pkey ON auth.instances USING btree (id)                                                                                                                      |
| public     | investment_plans       | investment_plans_pkey                                | CREATE UNIQUE INDEX investment_plans_pkey ON public.investment_plans USING btree (id)                                                                                                      |
| public     | kyc_documents          | idx_kyc_user                                         | CREATE INDEX idx_kyc_user ON public.kyc_documents USING btree (user_id)                                                                                                                    |
| public     | kyc_documents          | idx_kyc_documents_user_id                            | CREATE INDEX idx_kyc_documents_user_id ON public.kyc_documents USING btree (user_id)                                                                                                       |
| public     | kyc_documents          | kyc_documents_pkey                                   | CREATE UNIQUE INDEX kyc_documents_pkey ON public.kyc_documents USING btree (id)                                                                                                            |
| public     | kyc_documents          | idx_kyc_status                                       | CREATE INDEX idx_kyc_status ON public.kyc_documents USING btree (status)                                                                                                                   |
| public     | loans                  | idx_loans_user_id                                    | CREATE INDEX idx_loans_user_id ON public.loans USING btree (user_id)                                                                                                                       |
| public     | loans                  | idx_loans_repay                                      | CREATE INDEX idx_loans_repay ON public.loans USING btree (repayment_date) WHERE (status = ANY (ARRAY['current'::text, 'delayed'::text]))                                                   |
| public     | loans                  | idx_loans_user                                       | CREATE INDEX idx_loans_user ON public.loans USING btree (user_id)                                                                                                                          |
| public     | loans                  | idx_loans_status                                     | CREATE INDEX idx_loans_status ON public.loans USING btree (status)                                                                                                                         |
| public     | loans                  | loans_pkey                                           | CREATE UNIQUE INDEX loans_pkey ON public.loans USING btree (id)                                                                                                                            |
| realtime   | messages               | messages_pkey                                        | CREATE UNIQUE INDEX messages_pkey ON ONLY realtime.messages USING btree (id, inserted_at)                                                                                                  |
| realtime   | messages               | messages_inserted_at_topic_index                     | CREATE INDEX messages_inserted_at_topic_index ON ONLY realtime.messages USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE))                |
| realtime   | messages_2026_03_12    | messages_2026_03_12_pkey                             | CREATE UNIQUE INDEX messages_2026_03_12_pkey ON realtime.messages_2026_03_12 USING btree (id, inserted_at)                                                                                 |
| realtime   | messages_2026_03_12    | messages_2026_03_12_inserted_at_topic_idx            | CREATE INDEX messages_2026_03_12_inserted_at_topic_idx ON realtime.messages_2026_03_12 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE)) |
| realtime   | messages_2026_03_13    | messages_2026_03_13_pkey                             | CREATE UNIQUE INDEX messages_2026_03_13_pkey ON realtime.messages_2026_03_13 USING btree (id, inserted_at)                                                                                 |
| realtime   | messages_2026_03_13    | messages_2026_03_13_inserted_at_topic_idx            | CREATE INDEX messages_2026_03_13_inserted_at_topic_idx ON realtime.messages_2026_03_13 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE)) |
| realtime   | messages_2026_03_14    | messages_2026_03_14_pkey                             | CREATE UNIQUE INDEX messages_2026_03_14_pkey ON realtime.messages_2026_03_14 USING btree (id, inserted_at)                                                                                 |
| realtime   | messages_2026_03_14    | messages_2026_03_14_inserted_at_topic_idx            | CREATE INDEX messages_2026_03_14_inserted_at_topic_idx ON realtime.messages_2026_03_14 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE)) |
| realtime   | messages_2026_03_15    | messages_2026_03_15_pkey                             | CREATE UNIQUE INDEX messages_2026_03_15_pkey ON realtime.messages_2026_03_15 USING btree (id, inserted_at)                                                                                 |
| realtime   | messages_2026_03_15    | messages_2026_03_15_inserted_at_topic_idx            | CREATE INDEX messages_2026_03_15_inserted_at_topic_idx ON realtime.messages_2026_03_15 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE)) |
| realtime   | messages_2026_03_16    | messages_2026_03_16_pkey                             | CREATE UNIQUE INDEX messages_2026_03_16_pkey ON realtime.messages_2026_03_16 USING btree (id, inserted_at)                                                                                 |
| realtime   | messages_2026_03_16    | messages_2026_03_16_inserted_at_topic_idx            | CREATE INDEX messages_2026_03_16_inserted_at_topic_idx ON realtime.messages_2026_03_16 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE)) |
| realtime   | messages_2026_03_17    | messages_2026_03_17_pkey                             | CREATE UNIQUE INDEX messages_2026_03_17_pkey ON realtime.messages_2026_03_17 USING btree (id, inserted_at)                                                                                 |
| realtime   | messages_2026_03_17    | messages_2026_03_17_inserted_at_topic_idx            | CREATE INDEX messages_2026_03_17_inserted_at_topic_idx ON realtime.messages_2026_03_17 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE)) |
| realtime   | messages_2026_03_18    | messages_2026_03_18_inserted_at_topic_idx            | CREATE INDEX messages_2026_03_18_inserted_at_topic_idx ON realtime.messages_2026_03_18 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE)) |
| realtime   | messages_2026_03_18    | messages_2026_03_18_pkey                             | CREATE UNIQUE INDEX messages_2026_03_18_pkey ON realtime.messages_2026_03_18 USING btree (id, inserted_at)                                                                                 |
| auth       | mfa_amr_claims         | amr_id_pk                                            | CREATE UNIQUE INDEX amr_id_pk ON auth.mfa_amr_claims USING btree (id)                                                                                                                      |
| auth       | mfa_amr_claims         | mfa_amr_claims_session_id_authentication_method_pkey | CREATE UNIQUE INDEX mfa_amr_claims_session_id_authentication_method_pkey ON auth.mfa_amr_claims USING btree (session_id, authentication_method)                                            |
| auth       | mfa_challenges         | mfa_challenge_created_at_idx                         | CREATE INDEX mfa_challenge_created_at_idx ON auth.mfa_challenges USING btree (created_at DESC)                                                                                             |
| auth       | mfa_challenges         | mfa_challenges_pkey                                  | CREATE UNIQUE INDEX mfa_challenges_pkey ON auth.mfa_challenges USING btree (id)                                                                                                            |
| auth       | mfa_factors            | mfa_factors_last_challenged_at_key                   | CREATE UNIQUE INDEX mfa_factors_last_challenged_at_key ON auth.mfa_factors USING btree (last_challenged_at)                                                                                |
| auth       | mfa_factors            | unique_phone_factor_per_user                         | CREATE UNIQUE INDEX unique_phone_factor_per_user ON auth.mfa_factors USING btree (user_id, phone)                                                                                          |
| auth       | mfa_factors            | factor_id_created_at_idx                             | CREATE INDEX factor_id_created_at_idx ON auth.mfa_factors USING btree (user_id, created_at)                                                                                                |
| auth       | mfa_factors            | mfa_factors_user_id_idx                              | CREATE INDEX mfa_factors_user_id_idx ON auth.mfa_factors USING btree (user_id)                                                                                                             |
| auth       | mfa_factors            | mfa_factors_user_friendly_name_unique                | CREATE UNIQUE INDEX mfa_factors_user_friendly_name_unique ON auth.mfa_factors USING btree (friendly_name, user_id) WHERE (TRIM(BOTH FROM friendly_name) <> ''::text)                       |
| auth       | mfa_factors            | mfa_factors_pkey                                     | CREATE UNIQUE INDEX mfa_factors_pkey ON auth.mfa_factors USING btree (id)                                                                                                                  |
| storage    | migrations             | migrations_name_key                                  | CREATE UNIQUE INDEX migrations_name_key ON storage.migrations USING btree (name)                                                                                                           |
| storage    | migrations             | migrations_pkey                                      | CREATE UNIQUE INDEX migrations_pkey ON storage.migrations USING btree (id)                                                                                                                 |
| public     | notifications          | idx_notifications_user_id                            | CREATE INDEX idx_notifications_user_id ON public.notifications USING btree (user_id)                                                                                                       |
| public     | notifications          | notifications_pkey                                   | CREATE UNIQUE INDEX notifications_pkey ON public.notifications USING btree (id)                                                                                                            |
| public     | notifications          | idx_notif_target                                     | CREATE INDEX idx_notif_target ON public.notifications USING btree (target_user_id) WHERE (target_user_id IS NOT NULL)                                                                      |
| public     | notifications          | idx_notif_status                                     | CREATE INDEX idx_notif_status ON public.notifications USING btree (status)                                                                                                                 |
| auth       | oauth_authorizations   | oauth_auth_pending_exp_idx                           | CREATE INDEX oauth_auth_pending_exp_idx ON auth.oauth_authorizations USING btree (expires_at) WHERE (status = 'pending'::auth.oauth_authorization_status)                                  |
| auth       | oauth_authorizations   | oauth_authorizations_authorization_code_key          | CREATE UNIQUE INDEX oauth_authorizations_authorization_code_key ON auth.oauth_authorizations USING btree (authorization_code)                                                              |
| auth       | oauth_authorizations   | oauth_authorizations_authorization_id_key            | CREATE UNIQUE INDEX oauth_authorizations_authorization_id_key ON auth.oauth_authorizations USING btree (authorization_id)                                                                  |
| auth       | oauth_authorizations   | oauth_authorizations_pkey                            | CREATE UNIQUE INDEX oauth_authorizations_pkey ON auth.oauth_authorizations USING btree (id)                                                                                                |
| auth       | oauth_client_states    | idx_oauth_client_states_created_at                   | CREATE INDEX idx_oauth_client_states_created_at ON auth.oauth_client_states USING btree (created_at)                                                                                       |

## عرض جميع Triggers:
| trigger_name                       | event_manipulation | event_object_table | action_timing | action_statement                                       |
| ---------------------------------- | ------------------ | ------------------ | ------------- | ------------------------------------------------------ |
| trg_admins_ts                      | UPDATE             | admin_profiles     | BEFORE        | EXECUTE FUNCTION fn_update_timestamp()                 |
| trg_agents_ts                      | UPDATE             | agents             | BEFORE        | EXECUTE FUNCTION fn_update_timestamp()                 |
| trg_agents_updated                 | UPDATE             | agents             | BEFORE        | EXECUTE FUNCTION handle_updated_at()                   |
| trg_audit_immutable                | DELETE             | audit_logs         | BEFORE        | EXECUTE FUNCTION fn_prevent_audit_mutation()           |
| trg_audit_immutable                | UPDATE             | audit_logs         | BEFORE        | EXECUTE FUNCTION fn_prevent_audit_mutation()           |
| enforce_bucket_name_length_trigger | UPDATE             | buckets            | BEFORE        | EXECUTE FUNCTION storage.enforce_bucket_name_length()  |
| protect_buckets_delete             | DELETE             | buckets            | BEFORE        | EXECUTE FUNCTION storage.protect_delete()              |
| enforce_bucket_name_length_trigger | INSERT             | buckets            | BEFORE        | EXECUTE FUNCTION storage.enforce_bucket_name_length()  |
| trg_currencies_ts                  | UPDATE             | currencies         | BEFORE        | EXECUTE FUNCTION fn_update_timestamp()                 |
| trg_inv_plans_ts                   | UPDATE             | investment_plans   | BEFORE        | EXECUTE FUNCTION fn_update_timestamp()                 |
| update_objects_updated_at          | UPDATE             | objects            | BEFORE        | EXECUTE FUNCTION storage.update_updated_at_column()    |
| protect_objects_delete             | DELETE             | objects            | BEFORE        | EXECUTE FUNCTION storage.protect_delete()              |
| trg_p_updated                      | UPDATE             | profiles           | BEFORE        | EXECUTE FUNCTION handle_updated_at()                   |
| trg_profiles_ts                    | UPDATE             | profiles           | BEFORE        | EXECUTE FUNCTION fn_update_timestamp()                 |
| trg_profiles_updated               | UPDATE             | profiles           | BEFORE        | EXECUTE FUNCTION handle_updated_at()                   |
| tr_check_filters                   | UPDATE             | subscription       | BEFORE        | EXECUTE FUNCTION realtime.subscription_check_filters() |
| tr_check_filters                   | INSERT             | subscription       | BEFORE        | EXECUTE FUNCTION realtime.subscription_check_filters() |
| trg_settings_ts                    | UPDATE             | system_settings    | BEFORE        | EXECUTE FUNCTION fn_update_timestamp()                 |
| trg_terms_ts                       | UPDATE             | terms_sections     | BEFORE        | EXECUTE FUNCTION fn_update_timestamp()                 |
| trg_t_updated                      | UPDATE             | transactions       | BEFORE        | EXECUTE FUNCTION handle_updated_at()                   |
| trg_txn_immutable                  | DELETE             | transactions       | BEFORE        | EXECUTE FUNCTION fn_prevent_txn_mutation()             |
| trg_txn_immutable                  | UPDATE             | transactions       | BEFORE        | EXECUTE FUNCTION fn_prevent_txn_mutation()             |
| trg_points_ts                      | UPDATE             | user_points        | BEFORE        | EXECUTE FUNCTION fn_update_timestamp()                 |
| on_auth_user_created               | INSERT             | users              | AFTER         | EXECUTE FUNCTION handle_new_user()                     |
| trg_wallets_updated                | UPDATE             | wallets            | BEFORE        | EXECUTE FUNCTION handle_updated_at()                   |
| trg_w_updated                      | UPDATE             | wallets            | BEFORE        | EXECUTE FUNCTION handle_updated_at()                   |
| trg_wallets_ts                     | UPDATE             | wallets            | BEFORE        | EXECUTE FUNCTION fn_update_timestamp()                 |


## عرض جميع Constraints:
| constraint_name                                      | constraint_type | table_name             |
| ---------------------------------------------------- | --------------- | ---------------------- |
| activity_logs_severity_check                         | c               | activity_logs          |
| activity_logs_actor_id_fkey                          | f               | activity_logs          |
| activity_logs_pkey                                   | p               | activity_logs          |
| admin_profiles_id_fkey                               | f               | admin_profiles         |
| admin_profiles_pkey                                  | p               | admin_profiles         |
| admin_profiles_role_check                            | c               | admin_profiles         |
| admin_sessions_pkey                                  | p               | admin_sessions         |
| admin_sessions_admin_id_fkey                         | f               | admin_sessions         |
| ads_pkey                                             | p               | ads                    |
| ads_created_by_fkey                                  | f               | ads                    |
| agents_user_id_fkey                                  | f               | agents                 |
| agents_status_check                                  | c               | agents                 |
| agents_pkey                                          | p               | agents                 |
| audit_log_entries_pkey                               | p               | audit_log_entries      |
| audit_logs_admin_id_fkey                             | f               | audit_logs             |
| audit_logs_pkey                                      | p               | audit_logs             |
| buckets_pkey                                         | p               | buckets                |
| buckets_analytics_pkey                               | p               | buckets_analytics      |
| buckets_vectors_pkey                                 | p               | buckets_vectors        |
| chat_conversations_user_id_fkey                      | f               | chat_conversations     |
| chat_conversations_agent_id_fkey                     | f               | chat_conversations     |
| chat_conversations_unread_admin_count_check          | c               | chat_conversations     |
| chat_conversations_assigned_admin_id_fkey            | f               | chat_conversations     |
| chat_conversations_unread_user_count_check           | c               | chat_conversations     |
| chat_conversations_pkey                              | p               | chat_conversations     |
| chat_messages_sender_type_check                      | c               | chat_messages          |
| chat_messages_conversation_id_fkey                   | f               | chat_messages          |
| chat_messages_pkey                                   | p               | chat_messages          |
| countries_pkey                                       | p               | countries              |
| currencies_code_key                                  | u               | currencies             |
| currencies_pkey                                      | p               | currencies             |
| custom_oauth_providers_provider_type_check           | c               | custom_oauth_providers |
| custom_oauth_providers_oidc_requires_issuer          | c               | custom_oauth_providers |
| custom_oauth_providers_token_url_length              | c               | custom_oauth_providers |
| custom_oauth_providers_oidc_discovery_url_https      | c               | custom_oauth_providers |
| custom_oauth_providers_oauth2_requires_endpoints     | c               | custom_oauth_providers |
| custom_oauth_providers_pkey                          | p               | custom_oauth_providers |
| custom_oauth_providers_client_id_length              | c               | custom_oauth_providers |
| custom_oauth_providers_issuer_length                 | c               | custom_oauth_providers |
| custom_oauth_providers_identifier_key                | u               | custom_oauth_providers |
| custom_oauth_providers_jwks_uri_length               | c               | custom_oauth_providers |
| custom_oauth_providers_userinfo_url_length           | c               | custom_oauth_providers |
| custom_oauth_providers_authorization_url_length      | c               | custom_oauth_providers |
| custom_oauth_providers_discovery_url_length          | c               | custom_oauth_providers |
| custom_oauth_providers_authorization_url_https       | c               | custom_oauth_providers |
| custom_oauth_providers_name_length                   | c               | custom_oauth_providers |
| custom_oauth_providers_token_url_https               | c               | custom_oauth_providers |
| custom_oauth_providers_userinfo_url_https            | c               | custom_oauth_providers |
| custom_oauth_providers_oidc_issuer_https             | c               | custom_oauth_providers |
| custom_oauth_providers_identifier_format             | c               | custom_oauth_providers |
| custom_oauth_providers_jwks_uri_https                | c               | custom_oauth_providers |
| daily_check_ins_pkey                                 | p               | daily_check_ins        |
| daily_check_ins_user_id_fkey                         | f               | daily_check_ins        |
| enum_translations_enum_type_enum_value_key           | u               | enum_translations      |
| enum_translations_pkey                               | p               | enum_translations      |
| faqs_pkey                                            | p               | faqs                   |
| fees_pkey                                            | p               | fees                   |
| fees_category_check                                  | c               | fees                   |
| flow_state_pkey                                      | p               | flow_state             |
| identities_user_id_fkey                              | f               | identities             |
| identities_provider_id_provider_unique               | u               | identities             |
| identities_pkey                                      | p               | identities             |
| instances_pkey                                       | p               | instances              |
| investment_plans_created_by_fkey                     | f               | investment_plans       |
| investment_plans_risk_level_check                    | c               | investment_plans       |
| investment_plans_pkey                                | p               | investment_plans       |
| kyc_documents_reviewed_by_fkey                       | f               | kyc_documents          |
| kyc_documents_user_id_fkey                           | f               | kyc_documents          |
| kyc_documents_document_type_check                    | c               | kyc_documents          |
| kyc_documents_status_check                           | c               | kyc_documents          |
| kyc_documents_pkey                                   | p               | kyc_documents          |
| loans_approved_by_fkey                               | f               | loans                  |
| loans_status_check                                   | c               | loans                  |
| loans_pkey                                           | p               | loans                  |
| loans_user_id_fkey                                   | f               | loans                  |
| messages_pkey                                        | p               | messages               |
| messages_2026_03_12_pkey                             | p               | messages_2026_03_12    |
| messages_2026_03_13_pkey                             | p               | messages_2026_03_13    |
| messages_2026_03_14_pkey                             | p               | messages_2026_03_14    |
| messages_2026_03_15_pkey                             | p               | messages_2026_03_15    |
| messages_2026_03_16_pkey                             | p               | messages_2026_03_16    |
| messages_2026_03_17_pkey                             | p               | messages_2026_03_17    |
| messages_2026_03_18_pkey                             | p               | messages_2026_03_18    |
| mfa_amr_claims_session_id_authentication_method_pkey | u               | mfa_amr_claims         |
| amr_id_pk                                            | p               | mfa_amr_claims         |
| mfa_amr_claims_session_id_fkey                       | f               | mfa_amr_claims         |
| mfa_challenges_auth_factor_id_fkey                   | f               | mfa_challenges         |
| mfa_challenges_pkey                                  | p               | mfa_challenges         |
| mfa_factors_user_id_fkey                             | f               | mfa_factors            |
| mfa_factors_last_challenged_at_key                   | u               | mfa_factors            |
| mfa_factors_pkey                                     | p               | mfa_factors            |
| migrations_pkey                                      | p               | migrations             |
| migrations_name_key                                  | u               | migrations             |
| notifications_status_check                           | c               | notifications          |
| notifications_target_user_id_fkey                    | f               | notifications          |
| notifications_pkey                                   | p               | notifications          |
| notifications_sent_by_fkey                           | f               | notifications          |
| notifications_user_id_fkey                           | f               | notifications          |
| notifications_target_check                           | c               | notifications          |
| oauth_authorizations_client_id_fkey                  | f               | oauth_authorizations   |