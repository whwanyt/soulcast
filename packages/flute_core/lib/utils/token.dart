import '../storage/storage.dart';

/// Token管理工具类
/// 提供访问令牌和刷新令牌的存储、获取、验证等功能
class TokenManager {
  /// 访问令牌存储键
  static const String _accessTokenKey = 'access_token';

  /// 刷新令牌存储键
  static const String _refreshTokenKey = 'refresh_token';

  /// 令牌过期时间存储键
  static const String _tokenExpiryKey = 'token_expiry';

  /// 用户ID存储键
  static const String _userIdKey = 'user_id';

  /// 存储访问令牌
  /// [token] 访问令牌
  /// [expiryTime] 过期时间（可选）
  static Future<bool> saveAccessToken(
    String token, {
    DateTime? expiryTime,
  }) async {
    final success = await Storage.setString(_accessTokenKey, token);
    if (success && expiryTime != null) {
      await Storage.setInt(_tokenExpiryKey, expiryTime.millisecondsSinceEpoch);
    }
    return success;
  }

  /// 获取访问令牌
  /// 返回存储的访问令牌，如果不存在则返回null
  static Future<String?> getAccessToken() async {
    return await Storage.getString(_accessTokenKey);
  }

  /// 存储刷新令牌
  /// [token] 刷新令牌
  static Future<bool> saveRefreshToken(String token) async {
    return await Storage.setString(_refreshTokenKey, token);
  }

  /// 获取刷新令牌
  /// 返回存储的刷新令牌，如果不存在则返回null
  static Future<String?> getRefreshToken() async {
    return await Storage.getString(_refreshTokenKey);
  }

  /// 存储用户ID
  /// [userId] 用户唯一标识
  static Future<bool> saveUserId(String userId) async {
    return await Storage.setString(_userIdKey, userId);
  }

  /// 获取用户ID
  /// 返回存储的用户ID，如果不存在则返回null
  static Future<String?> getUserId() async {
    return await Storage.getString(_userIdKey);
  }

  /// 批量保存令牌信息
  /// [accessToken] 访问令牌
  /// [refreshToken] 刷新令牌
  /// [userId] 用户ID（可选）
  /// [expiryTime] 过期时间（可选）
  static Future<bool> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? userId,
    DateTime? expiryTime,
  }) async {
    final results = await Future.wait([
      saveAccessToken(accessToken, expiryTime: expiryTime),
      saveRefreshToken(refreshToken),
      if (userId != null) saveUserId(userId) else Future.value(true),
    ]);

    return results.every((result) => result);
  }

  /// 检查访问令牌是否存在
  /// 返回true表示令牌存在，false表示不存在
  static Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// 检查刷新令牌是否存在
  /// 返回true表示令牌存在，false表示不存在
  static Future<bool> hasRefreshToken() async {
    final token = await getRefreshToken();
    return token != null && token.isNotEmpty;
  }

  /// 检查用户是否已登录
  /// 基于访问令牌和刷新令牌的存在性判断
  static Future<bool> isLoggedIn() async {
    return await hasAccessToken() && await hasRefreshToken();
  }

  /// 检查访问令牌是否过期
  /// 返回true表示已过期，false表示未过期或无过期时间设置
  static Future<bool> isAccessTokenExpired() async {
    final expiryTimestamp = await Storage.getInt(_tokenExpiryKey);
    if (expiryTimestamp == null) {
      return false; // 没有设置过期时间，认为未过期
    }

    final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
    return DateTime.now().isAfter(expiryTime);
  }

  /// 获取令牌过期时间
  /// 返回令牌过期时间，如果未设置则返回null
  static Future<DateTime?> getTokenExpiryTime() async {
    final expiryTimestamp = await Storage.getInt(_tokenExpiryKey);
    if (expiryTimestamp == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
  }

  /// 清除访问令牌
  /// 删除存储的访问令牌和过期时间
  static Future<bool> clearAccessToken() async {
    final results = await Future.wait([
      Storage.remove(_accessTokenKey),
      Storage.remove(_tokenExpiryKey),
    ]);
    return results.every((result) => result);
  }

  /// 清除刷新令牌
  /// 删除存储的刷新令牌
  static Future<bool> clearRefreshToken() async {
    return await Storage.remove(_refreshTokenKey);
  }

  /// 清除用户ID
  /// 删除存储的用户ID
  static Future<bool> clearUserId() async {
    return await Storage.remove(_userIdKey);
  }

  /// 清除所有令牌信息
  /// 删除访问令牌、刷新令牌、用户ID和过期时间
  static Future<bool> clearAllTokens() async {
    final results = await Future.wait([
      clearAccessToken(),
      clearRefreshToken(),
      clearUserId(),
    ]);
    return results.every((result) => result);
  }

  /// 获取令牌信息摘要
  /// 返回包含令牌状态的Map，用于调试和状态检查
  static Future<Map<String, dynamic>> getTokenSummary() async {
    return {
      'hasAccessToken': await hasAccessToken(),
      'hasRefreshToken': await hasRefreshToken(),
      'isLoggedIn': await isLoggedIn(),
      'isAccessTokenExpired': await isAccessTokenExpired(),
      'tokenExpiryTime': (await getTokenExpiryTime())?.toIso8601String(),
      'userId': await getUserId(),
    };
  }
}
