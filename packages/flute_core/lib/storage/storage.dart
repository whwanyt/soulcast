import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 基于SharedPreferences的缓存存储类
/// 提供常用的数据存储和读取功能
class Storage {
  static SharedPreferences? _prefs;

  /// 初始化SharedPreferences实例
  /// 在应用启动时调用
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 获取SharedPreferences实例
  /// 如果未初始化则自动初始化
  static Future<SharedPreferences> get _instance async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// 存储字符串值
  /// [key] 存储键
  /// [value] 存储值
  static Future<bool> setString(String key, String value) async {
    final prefs = await _instance;
    return await prefs.setString(key, value);
  }

  /// 获取字符串值
  /// [key] 存储键
  /// [defaultValue] 默认值，当键不存在时返回
  static Future<String?> getString(String key, {String? defaultValue}) async {
    final prefs = await _instance;
    return prefs.getString(key) ?? defaultValue;
  }

  /// 存储整数值
  /// [key] 存储键
  /// [value] 存储值
  static Future<bool> setInt(String key, int value) async {
    final prefs = await _instance;
    return await prefs.setInt(key, value);
  }

  /// 获取整数值
  /// [key] 存储键
  /// [defaultValue] 默认值，当键不存在时返回
  static Future<int?> getInt(String key, {int? defaultValue}) async {
    final prefs = await _instance;
    return prefs.getInt(key) ?? defaultValue;
  }

  /// 存储双精度浮点数值
  /// [key] 存储键
  /// [value] 存储值
  static Future<bool> setDouble(String key, double value) async {
    final prefs = await _instance;
    return await prefs.setDouble(key, value);
  }

  /// 获取双精度浮点数值
  /// [key] 存储键
  /// [defaultValue] 默认值，当键不存在时返回
  static Future<double?> getDouble(String key, {double? defaultValue}) async {
    final prefs = await _instance;
    return prefs.getDouble(key) ?? defaultValue;
  }

  /// 存储布尔值
  /// [key] 存储键
  /// [value] 存储值
  static Future<bool> setBool(String key, bool value) async {
    final prefs = await _instance;
    return await prefs.setBool(key, value);
  }

  /// 获取布尔值
  /// [key] 存储键
  /// [defaultValue] 默认值，当键不存在时返回
  static Future<bool?> getBool(String key, {bool? defaultValue}) async {
    final prefs = await _instance;
    return prefs.getBool(key) ?? defaultValue;
  }

  /// 存储字符串列表
  /// [key] 存储键
  /// [value] 存储值
  static Future<bool> setStringList(String key, List<String> value) async {
    final prefs = await _instance;
    return await prefs.setStringList(key, value);
  }

  /// 获取字符串列表
  /// [key] 存储键
  /// [defaultValue] 默认值，当键不存在时返回
  static Future<List<String>?> getStringList(
    String key, {
    List<String>? defaultValue,
  }) async {
    final prefs = await _instance;
    return prefs.getStringList(key) ?? defaultValue;
  }

  /// 存储JSON对象
  /// [key] 存储键
  /// [value] 要序列化的对象
  static Future<bool> setJson(String key, Map<String, dynamic> value) async {
    final jsonString = jsonEncode(value);
    return await setString(key, jsonString);
  }

  /// 获取JSON对象
  /// [key] 存储键
  /// [defaultValue] 默认值，当键不存在或解析失败时返回
  static Future<Map<String, dynamic>?> getJson(
    String key, {
    Map<String, dynamic>? defaultValue,
  }) async {
    try {
      final jsonString = await getString(key);
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
    } catch (e) {
      // JSON解析失败时返回默认值
    }
    return defaultValue;
  }

  /// 检查键是否存在
  /// [key] 要检查的键
  static Future<bool> containsKey(String key) async {
    final prefs = await _instance;
    return prefs.containsKey(key);
  }

  /// 删除指定键的值
  /// [key] 要删除的键
  static Future<bool> remove(String key) async {
    final prefs = await _instance;
    return await prefs.remove(key);
  }

  /// 清空所有存储的数据
  static Future<bool> clear() async {
    final prefs = await _instance;
    return await prefs.clear();
  }

  /// 获取所有存储的键
  static Future<Set<String>> getKeys() async {
    final prefs = await _instance;
    return prefs.getKeys();
  }

  /// 重新加载SharedPreferences
  /// 用于同步其他进程的更改
  static Future<void> reload() async {
    final prefs = await _instance;
    await prefs.reload();
  }
}
