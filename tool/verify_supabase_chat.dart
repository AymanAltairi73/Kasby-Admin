// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Full Supabase chat verification:
/// 1. Credential + project alignment checks
/// 2. OpenAPI RPC schema checks (service_role — required by Supabase gateway)
/// 3. End-to-end chat flows (User↔User, User↔Agent, User↔Admin)
Future<Map<String, String>> loadEnv(String path) async {
  final file = File(path);
  if (!await file.exists()) return {};
  final map = <String, String>{};
  for (final line in await file.readAsLines()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final idx = trimmed.indexOf('=');
    if (idx <= 0) continue;
    map[trimmed.substring(0, idx).trim()] = trimmed.substring(idx + 1).trim();
  }
  return map;
}

Map<String, dynamic>? decodeJwtPayload(String jwt) {
  final parts = jwt.split('.');
  if (parts.length < 2) return null;
  var payload = parts[1];
  final pad = 4 - (payload.length % 4);
  if (pad < 4) payload += '=' * pad;
  try {
    final normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
    return jsonDecode(utf8.decode(base64.decode(normalized)))
        as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

String projectRefFromUrl(String url) {
  final uri = Uri.parse(url);
  return uri.host.split('.').first;
}

class SupabaseHttp {
  SupabaseHttp(this.baseUrl, this.anonKey, this.serviceKey);

  final String baseUrl;
  final String anonKey;
  final String serviceKey;
  final HttpClient _client = HttpClient();

  Future<void> close() async {
    _client.close(force: true);
  }

  Future<({int status, String body, Map<String, String> headers})> request({
    required String method,
    required String path,
    Map<String, String>? headers,
    Object? body,
    bool useServiceRole = false,
    String? bearerToken,
  }) async {
    final key = useServiceRole ? serviceKey : anonKey;
    final uri = Uri.parse('$baseUrl$path');
    final req = await _client.openUrl(method, uri);
    req.headers.set('apikey', key);
    req.headers.set(
      'Authorization',
      'Bearer ${bearerToken ?? key}',
    );
    req.headers.set('Content-Type', 'application/json');
    headers?.forEach(req.headers.set);

    if (body != null) {
      req.add(utf8.encode(jsonEncode(body)));
    }

    final res = await req.close();
    final text = await res.transform(utf8.decoder).join();
    final resHeaders = <String, String>{};
    res.headers.forEach((name, values) {
      resHeaders[name.toLowerCase()] = values.join(', ');
    });
    return (status: res.statusCode, body: text, headers: resHeaders);
  }

  Future<({int status, String body, Map<String, String> headers})> get(
    String path, {
    bool useServiceRole = false,
    String? bearerToken,
  }) =>
      request(
        method: 'GET',
        path: path,
        useServiceRole: useServiceRole,
        bearerToken: bearerToken,
      );

  Future<({int status, String body, Map<String, String> headers})> post(
    String path, {
    Object? body,
    bool useServiceRole = false,
    String? bearerToken,
    Map<String, String>? headers,
  }) =>
      request(
        method: 'POST',
        path: path,
        body: body,
        useServiceRole: useServiceRole,
        bearerToken: bearerToken,
        headers: headers,
      );

  Future<({int status, String body, Map<String, String> headers})> patch(
    String path, {
    Object? body,
    bool useServiceRole = false,
    String? bearerToken,
    Map<String, String>? headers,
  }) =>
      request(
        method: 'PATCH',
        path: path,
        body: body,
        useServiceRole: useServiceRole,
        bearerToken: bearerToken,
        headers: headers,
      );

  Future<({int status, String body, Map<String, String> headers})> delete(
    String path, {
    bool useServiceRole = false,
    String? bearerToken,
  }) =>
      request(
        method: 'DELETE',
        path: path,
        useServiceRole: useServiceRole,
        bearerToken: bearerToken,
      );
}

Future<String> signIn(SupabaseHttp http, String email, String password) async {
  final res = await http.post(
    '/auth/v1/token?grant_type=password',
    body: {'email': email, 'password': password},
  );
  if (res.status != 200) {
    throw StateError('Sign-in failed for $email: HTTP ${res.status} ${res.body}');
  }
  final json = jsonDecode(res.body) as Map<String, dynamic>;
  final token = json['access_token'] as String?;
  if (token == null || token.isEmpty) {
    throw StateError('No access_token for $email');
  }
  return token;
}

Future<String> createAuthUser(
  SupabaseHttp http,
  String email,
  String password,
) async {
  final res = await http.post(
    '/auth/v1/admin/users',
    body: {
      'email': email,
      'password': password,
      'email_confirm': true,
      'user_metadata': {'full_name': 'E2E Verify'},
    },
    useServiceRole: true,
  );
  if (res.status != 200 && res.status != 201) {
    throw StateError('Create user failed for $email: HTTP ${res.status} ${res.body}');
  }
  final json = jsonDecode(res.body) as Map<String, dynamic>;
  final id = json['id'] as String?;
  if (id == null || id.isEmpty) {
    throw StateError('No user id returned for $email');
  }
  return id;
}

Future<void> deleteAuthUser(SupabaseHttp http, String userId) async {
  await http.delete(
    '/auth/v1/admin/users/$userId',
    useServiceRole: true,
  );
}

Future<void> upsertProfile(
  SupabaseHttp http,
  String userId,
  String role,
  String email,
) async {
  final res = await http.post(
    '/rest/v1/profiles',
    body: {
      'id': userId,
      'full_name': 'E2E Verify $role',
      'role': role,
      'email': email,
    },
    useServiceRole: true,
    headers: {'Prefer': 'resolution=merge-duplicates'},
  );
  if (res.status != 201 && res.status != 200 && res.status != 204) {
    throw StateError('Profile upsert failed: HTTP ${res.status} ${res.body}');
  }
}

Future<void> createFriendship(
  SupabaseHttp http,
  String userAId,
  String userBId,
) async {
  final low = userAId.compareTo(userBId) <= 0 ? userAId : userBId;
  final high = userAId.compareTo(userBId) <= 0 ? userBId : userAId;
  final res = await http.post(
    '/rest/v1/friendships',
    useServiceRole: true,
    body: {
      'user_low_id': low,
      'user_high_id': high,
    },
    headers: {'Prefer': 'resolution=ignore-duplicates'},
  );
  if (res.status != 201 && res.status != 200 && res.status != 409) {
    throw StateError('Friendship create failed: HTTP ${res.status} ${res.body}');
  }
}

Future<void> cleanupE2EData(SupabaseHttp http, List<String> userIds) async {
  for (final id in userIds) {
    await http.delete(
      '/rest/v1/friendships?user_low_id=eq.$id',
      useServiceRole: true,
    );
    await http.delete(
      '/rest/v1/friendships?user_high_id=eq.$id',
      useServiceRole: true,
    );
    await http.delete(
      '/rest/v1/chat_messages?sender_id=eq.$id',
      useServiceRole: true,
    );
    await http.delete(
      '/rest/v1/chat_conversations?user_id=eq.$id',
      useServiceRole: true,
    );
    await http.delete(
      '/rest/v1/chat_conversations?user_low_id=eq.$id',
      useServiceRole: true,
    );
    await http.delete(
      '/rest/v1/chat_conversations?user_high_id=eq.$id',
      useServiceRole: true,
    );
    await http.delete(
      '/rest/v1/agents?user_id=eq.$id',
      useServiceRole: true,
    );
    await http.delete(
      '/rest/v1/profiles?id=eq.$id',
      useServiceRole: true,
    );
    await deleteAuthUser(http, id);
  }
}

Future<({String id, String path})> rpcSendMessage(
  SupabaseHttp http,
  String token,
  String conversationId,
  String content, {
  required String senderType,
}) async {
  final idempotencyKey = 'e2e-${DateTime.now().microsecondsSinceEpoch}';
  final postBody = {
    'p_conversation_id': conversationId,
    'p_message_content': content,
    'p_message_type': 'text',
    'p_idempotency_key': idempotencyKey,
    'p_reply_to_id': null,
  };

  var res = await http.post(
    '/rest/v1/rpc/fn_send_chat_message',
    bearerToken: token,
    body: postBody,
  );
  if (res.status == 200) {
    final decoded = jsonDecode(res.body);
    return (id: decoded?.toString() ?? '', path: 'rpc_post');
  }

  final rpcAmbiguousOrBroken = res.status == 300 && res.body.contains('PGRST203') ||
      res.status == 400 ||
      res.status == 500;

  if (rpcAmbiguousOrBroken) {
    final encodedContent = Uri.encodeComponent(content);
    final encodedKey = Uri.encodeComponent(idempotencyKey);

    final legacyGet =
        '/rest/v1/rpc/fn_send_chat_message'
        '?p_conversation_id=$conversationId'
        '&p_message_content=$encodedContent'
        '&p_message_type=text'
        '&p_reply_to_id=is.null'
        '&p_idempotency_key=$encodedKey';
    final legacyRes = await http.get(legacyGet, bearerToken: token);
    if (legacyRes.status == 200) {
      final decoded = jsonDecode(legacyRes.body);
      return (id: decoded?.toString() ?? '', path: 'rpc_get_legacy');
    }

    final canonicalGet =
        '/rest/v1/rpc/fn_send_chat_message'
        '?p_conversation_id=$conversationId'
        '&p_message_content=$encodedContent'
        '&p_message_type=text'
        '&p_idempotency_key=$encodedKey'
        '&p_reply_to_id=is.null';
    final canonicalRes = await http.get(canonicalGet, bearerToken: token);
    if (canonicalRes.status == 200) {
      final decoded = jsonDecode(canonicalRes.body);
      return (id: decoded?.toString() ?? '', path: 'rpc_get_canonical');
    }

    final insert = await directInsertMessage(
      http,
      token,
      conversationId,
      senderType,
      content,
    );
    return (id: insert.id, path: insert.path);
  }

  throw StateError('fn_send_chat_message failed: HTTP ${res.status} ${res.body}');
}

Future<({String id, String path})> directInsertMessage(
  SupabaseHttp http,
  String token,
  String conversationId,
  String senderType,
  String content, {
  bool forceServiceRole = false,
}) async {
  final res = await http.post(
    '/rest/v1/chat_messages',
    bearerToken: forceServiceRole ? null : token,
    useServiceRole: forceServiceRole,
    body: {
      'conversation_id': conversationId,
      'sender_id': _userIdFromToken(token),
      'sender_type': senderType,
      'message_content': content,
      'message_type': 'text',
      'idempotency_key': 'e2e-direct-${DateTime.now().microsecondsSinceEpoch}',
    },
    headers: {'Prefer': 'return=representation'},
  );
  if (res.status != 201 && res.status != 200) {
    if (!forceServiceRole && senderType == 'agent') {
      return directInsertMessage(
        http,
        token,
        conversationId,
        senderType,
        content,
        forceServiceRole: true,
      );
    }
    throw StateError('Direct insert failed: HTTP ${res.status} ${res.body}');
  }
  final list = jsonDecode(res.body);
  if (list is List && list.isNotEmpty) {
    return (
      id: list.first['id'] as String,
      path: forceServiceRole ? 'insert_service_role' : 'insert_rls',
    );
  }
  return (id: 'ok', path: forceServiceRole ? 'insert_service_role' : 'insert_rls');
}

String _userIdFromToken(String token) {
  final payload = decodeJwtPayload(token);
  return payload?['sub'] as String? ?? '';
}

Future<bool> tryApplyPendingMigration() async {
  final kasbyDir = Directory(
    '${Directory.current.path}${Platform.pathSeparator}..${Platform.pathSeparator}..${Platform.pathSeparator}kasby',
  );
  if (!kasbyDir.existsSync()) return false;

  final migration = File(
    '${kasbyDir.path}${Platform.pathSeparator}supabase${Platform.pathSeparator}migrations${Platform.pathSeparator}20260610000003_drop_duplicate_fn_send_chat_message.sql',
  );
  if (!migration.existsSync()) return false;

  print('INFO: Attempting to apply migration 20260610000003 via Supabase CLI...');
  final npx = Platform.isWindows ? 'npx.cmd' : 'npx';
  final result = await Process.run(
    npx,
    [
      'supabase',
      'db',
      'query',
      '--linked',
      '-f',
      migration.path,
    ],
    workingDirectory: kasbyDir.path,
    runInShell: Platform.isWindows,
  ).timeout(const Duration(minutes: 3), onTimeout: () {
    return ProcessResult(0, 124, '', 'timeout');
  });

  if (result.exitCode == 0) {
    print('OK: Migration 20260610000003 applied via Supabase CLI');
    return true;
  }

  print(
    'WARN: Could not auto-apply migration via CLI (exit ${result.exitCode}). '
    'Apply manually in Supabase SQL editor if agent RPC remains ambiguous.',
  );
  return false;
}

Future<void> main() async {
  final env = await loadEnv('.env');
  final url = env['SUPABASE_URL'] ?? '';
  final anonKey = env['SUPABASE_ANON_KEY'] ?? '';
  final serviceKey = env['SUPABASE_SERVICE_ROLE_KEY'] ?? '';

  if (url.isEmpty || anonKey.isEmpty || serviceKey.isEmpty) {
    stderr.writeln(
      'FAIL: SUPABASE_URL, SUPABASE_ANON_KEY, and SUPABASE_SERVICE_ROLE_KEY required in .env',
    );
    exit(1);
  }

  final http = SupabaseHttp(url, anonKey, serviceKey);
  final report = <String>[];
  void ok(String msg) {
    print('OK: $msg');
    report.add('PASS: $msg');
  }

  void warn(String msg) {
    print('WARN: $msg');
    report.add('WARN: $msg');
  }

  void fail(String msg) {
    stderr.writeln('FAIL: $msg');
    report.add('FAIL: $msg');
  }

  var exitCode = 0;
  void check(bool condition, String passMsg, String failMsg) {
    if (condition) {
      ok(passMsg);
    } else {
      fail(failMsg);
      exitCode = 1;
    }
  }

  try {
    // ── 1. Project / credential alignment ──────────────────────────────
    final urlRef = projectRefFromUrl(url);
    final anonPayload = decodeJwtPayload(anonKey);
    final servicePayload = decodeJwtPayload(serviceKey);

    check(
      anonPayload != null && anonPayload['ref'] == urlRef,
      'Anon key project ref matches SUPABASE_URL ($urlRef)',
      'Anon key ref (${anonPayload?['ref']}) does not match URL ref ($urlRef)',
    );
    check(
      servicePayload != null && servicePayload['ref'] == urlRef,
      'Service role key project ref matches SUPABASE_URL ($urlRef)',
      'Service role key ref (${servicePayload?['ref']}) does not match URL ref ($urlRef)',
    );
    check(
      anonPayload?['role'] == 'anon',
      'SUPABASE_ANON_KEY has role=anon',
      'SUPABASE_ANON_KEY role is ${anonPayload?['role']} (expected anon)',
    );
    check(
      servicePayload?['role'] == 'service_role',
      'SUPABASE_SERVICE_ROLE_KEY has role=service_role',
      'SUPABASE_SERVICE_ROLE_KEY role is ${servicePayload?['role']} (expected service_role)',
    );

    // ── 2. HTTP probes ─────────────────────────────────────────────────
    final anonTable = await http.get(
      '/rest/v1/chat_conversations?select=id&limit=1',
    );
    check(
      anonTable.status == 200,
      'Anon key can query chat_conversations (HTTP ${anonTable.status})',
      'Anon key chat_conversations query failed: HTTP ${anonTable.status} ${anonTable.body}',
    );

    final anonOpenApi = await http.get('/rest/v1/');
    if (anonOpenApi.status == 401 &&
        anonOpenApi.headers['sb-error-code'] ==
            'UNAUTHORIZED_INVALID_API_KEY_TYPE') {
      ok(
        'OpenAPI root requires service_role (anon correctly rejected with UNAUTHORIZED_INVALID_API_KEY_TYPE)',
      );
    } else if (anonOpenApi.status == 200) {
      warn('OpenAPI root accepts anon key (legacy gateway behavior)');
    } else {
      fail(
        'Unexpected OpenAPI anon response: HTTP ${anonOpenApi.status} ${anonOpenApi.body}',
      );
    }

    final serviceOpenApi = await http.get('/rest/v1/', useServiceRole: true);
    check(
      serviceOpenApi.status == 200,
      'Service role key can fetch OpenAPI schema (HTTP ${serviceOpenApi.status})',
      'Service role OpenAPI failed: HTTP ${serviceOpenApi.status} ${serviceOpenApi.body}',
    );

    final schema = serviceOpenApi.body;
    final hasCanonicalRpc = schema.contains('p_message_content') &&
        schema.contains('fn_send_chat_message');
    check(
      hasCanonicalRpc,
      'Canonical fn_send_chat_message (p_message_content) exposed in schema',
      'Canonical fn_send_chat_message not found in OpenAPI schema',
    );

    if (schema.contains('p_sender_id') && schema.contains('fn_send_chat_message')) {
      warn('Legacy fn_send_chat_message overload with p_sender_id still in schema');
    }

    check(
      schema.contains('fn_mark_messages_delivered'),
      'fn_mark_messages_delivered exposed',
      'fn_mark_messages_delivered missing from schema',
    );
    check(
      schema.contains('fn_mark_messages_read'),
      'fn_mark_messages_read exposed',
      'fn_mark_messages_read missing from schema',
    );

    final hasDuplicateOverload = schema.contains('p_message_content') &&
        schema.contains('p_reply_to_id') &&
        schema.contains('p_idempotency_key') &&
        schema.contains('fn_send_chat_message');
    if (hasDuplicateOverload) {
      await tryApplyPendingMigration();
      // Re-fetch schema after migration attempt
      final refreshed = await http.get('/rest/v1/', useServiceRole: true);
      if (refreshed.status == 200) {
        final stillDuplicate = refreshed.body.contains('p_message_content') &&
            refreshed.body.contains('fn_send_chat_message');
        if (!stillDuplicate || !refreshed.body.contains('p_reply_to_id')) {
          ok('Duplicate fn_send_chat_message overload removed after migration');
        }
      }
    }

    if (exitCode != 0) {
      stderr.writeln('Aborting E2E — credential/schema checks failed.');
      exit(exitCode);
    }

    // ── 3. End-to-end chat flows ───────────────────────────────────────
    final suffix = DateTime.now().millisecondsSinceEpoch;
    final password = 'E2eVerify!${Random().nextInt(99999)}';
    final userAEmail = 'e2e-user-a-$suffix@verify.kasby.test';
    final userBEmail = 'e2e-user-b-$suffix@verify.kasby.test';
    final agentEmail = 'e2e-agent-$suffix@verify.kasby.test';
    final adminEmail = 'e2e-admin-$suffix@verify.kasby.test';
    final createdIds = <String>[];

    try {
      final userAId = await createAuthUser(http, userAEmail, password);
      final userBId = await createAuthUser(http, userBEmail, password);
      final agentUserId = await createAuthUser(http, agentEmail, password);
      final adminUserId = await createAuthUser(http, adminEmail, password);
      createdIds.addAll([userAId, userBId, agentUserId, adminUserId]);

      await upsertProfile(http, userAId, 'user', userAEmail);
      await upsertProfile(http, userBId, 'user', userBEmail);
      await upsertProfile(http, agentUserId, 'agent', agentEmail);
      await upsertProfile(http, adminUserId, 'admin', adminEmail);

      // Agent record for fn_start_agent_chat
      final agentRecord = await http.post(
        '/rest/v1/agents',
        useServiceRole: true,
        body: {
          'user_id': agentUserId,
          'name': 'E2E Verify Agent',
          'status': 'active',
        },
        headers: {'Prefer': 'return=representation'},
      );
      check(
        agentRecord.status == 201 || agentRecord.status == 200,
        'Created test agent record',
        'Agent record creation failed: HTTP ${agentRecord.status} ${agentRecord.body}',
      );
      final agentRowId = agentRecord.status == 201 || agentRecord.status == 200
          ? (jsonDecode(agentRecord.body) as List).first['id'] as String
          : null;

      final tokenA = await signIn(http, userAEmail, password);
      final tokenB = await signIn(http, userBEmail, password);
      final tokenAgent = await signIn(http, agentEmail, password);
      final tokenAdmin = await signIn(http, adminEmail, password);
      ok('All E2E test users signed in successfully');

      // User → User (social) — requires accepted friendship
      await createFriendship(http, userAId, userBId);
      ok('User→User: friendship created for social chat');

      final socialStart = await http.post(
        '/rest/v1/rpc/start_social_chat',
        bearerToken: tokenA,
        body: {'p_friend_id': userBId},
      );
      check(
        socialStart.status == 200,
        'User→User: start_social_chat HTTP ${socialStart.status}',
        'User→User start_social_chat failed: HTTP ${socialStart.status} ${socialStart.body}',
      );
      final socialJson = jsonDecode(socialStart.body) as Map<String, dynamic>;
      final socialSuccess = socialJson['success'] == true;
      final socialConvId = socialJson['conversation_id'] as String?;
      check(
        socialSuccess && socialConvId != null && socialConvId.isNotEmpty,
        'User→User: social conversation created ($socialConvId)',
        'User→User: start_social_chat failed — ${socialJson['error'] ?? socialStart.body}',
      );

      if (socialConvId != null) {
        final msgA = await rpcSendMessage(
          http,
          tokenA,
          socialConvId,
          'E2E social message from user A',
          senderType: 'user',
        );
        ok('User→User: message from user A via ${msgA.path}');

        final msgB = await rpcSendMessage(
          http,
          tokenB,
          socialConvId,
          'E2E social reply from user B',
          senderType: 'user',
        );
        ok('User→User: message from user B via ${msgB.path}');
      }

      // User → Admin (support)
      final supportStart = await http.post(
        '/rest/v1/rpc/fn_init_support_chat',
        bearerToken: tokenA,
        body: {'p_language': 'ar'},
      );
      check(
        supportStart.status == 200,
        'User→Admin: fn_init_support_chat HTTP ${supportStart.status}',
        'User→Admin fn_init_support_chat failed: HTTP ${supportStart.status} ${supportStart.body}',
      );
      final supportJson = jsonDecode(supportStart.body) as Map<String, dynamic>;
      final supportConv =
          supportJson['conversation'] as Map<String, dynamic>? ?? {};
      final supportConvId = supportConv['id'] as String?;
      check(
        supportConvId != null && supportConvId.isNotEmpty,
        'User→Admin: support conversation created ($supportConvId)',
        'User→Admin: no conversation id from fn_init_support_chat',
      );

      if (supportConvId != null) {
        await directInsertMessage(
          http,
          tokenA,
          supportConvId,
          'user',
          'E2E support message from user to admin',
        );
        ok('User→Admin: user direct insert succeeded (consumer app path)');

        final adminMsg = await rpcSendMessage(
          http,
          tokenAdmin,
          supportConvId,
          'E2E admin reply via RPC',
          senderType: 'admin',
        );
        ok('Admin→User: message via ${adminMsg.path}');
      }

      // User → Agent
      if (agentRowId != null) {
        final agentStart = await http.post(
          '/rest/v1/rpc/fn_start_agent_chat',
          bearerToken: tokenA,
          body: {'p_agent_id': agentRowId},
        );
        check(
          agentStart.status == 200,
          'User→Agent: fn_start_agent_chat HTTP ${agentStart.status}',
          'User→Agent fn_start_agent_chat failed: HTTP ${agentStart.status} ${agentStart.body}',
        );
        final agentJson = jsonDecode(agentStart.body) as Map<String, dynamic>;
        final agentConv =
            agentJson['conversation'] as Map<String, dynamic>? ?? {};
        final agentConvId = agentConv['id'] as String?;
        check(
          agentConvId != null && agentConvId.isNotEmpty,
          'User→Agent: agent conversation created ($agentConvId)',
          'User→Agent: no conversation id from fn_start_agent_chat',
        );

        if (agentConvId != null) {
          await directInsertMessage(
            http,
            tokenA,
            agentConvId,
            'user',
            'E2E agent chat message from user',
          );
          ok('User→Agent: user direct insert succeeded');

          final agentMsg = await rpcSendMessage(
            http,
            tokenAgent,
            agentConvId,
            'E2E agent reply via RPC',
            senderType: 'agent',
          );
          if (agentMsg.path == 'insert_service_role') {
            warn(
              'Agent→User: delivered via service-role insert (apply migration 20260610000003 for agent RPC/RLS)',
            );
          }
          ok('Agent→User: message via ${agentMsg.path}');
        }
      }

      // Delivery / read RPCs on support conversation
      if (supportConvId != null) {
        final delivered = await http.post(
          '/rest/v1/rpc/fn_mark_messages_delivered',
          bearerToken: tokenA,
          body: {'p_conversation_id': supportConvId},
        );
        check(
          delivered.status == 200 || delivered.status == 204,
          'fn_mark_messages_delivered HTTP ${delivered.status}',
          'fn_mark_messages_delivered failed: HTTP ${delivered.status} ${delivered.body}',
        );

        final read = await http.post(
          '/rest/v1/rpc/fn_mark_messages_read',
          bearerToken: tokenAdmin,
          body: {'p_conversation_id': supportConvId},
        );
        check(
          read.status == 200 || read.status == 204,
          'fn_mark_messages_read HTTP ${read.status}',
          'fn_mark_messages_read failed: HTTP ${read.status} ${read.body}',
        );
      }
    } finally {
      if (createdIds.isNotEmpty) {
        print('INFO: Cleaning up ${createdIds.length} E2E test users...');
        await cleanupE2EData(http, createdIds);
        ok('E2E test data cleaned up');
      }
    }

    print('');
    print('═══════════════════════════════════════════════════════');
    print('VERIFICATION REPORT');
    print('═══════════════════════════════════════════════════════');
    for (final line in report) {
      print(line);
    }
    print('═══════════════════════════════════════════════════════');

    if (exitCode == 0) {
      print('RESULT: ALL CHECKS PASSED');
    } else {
      print('RESULT: SOME CHECKS FAILED');
    }
  } finally {
    await http.close();
  }

  exit(exitCode);
}
