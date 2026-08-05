/// 跨层（widgets / settings / tests）可引用的工具标识，避免依赖具体 Tool 实现类。
abstract final class AgentToolIds {
  static const currentTime = 'get_current_time';
  static const currentLocation = 'get_current_location';
  static const showLocationMap = 'show_location_map';
  static const reverseGeocode = 'reverse_geocode';
  static const showWeather = 'show_weather';
  static const generateImage = 'generate_image';

  /// 高德 Key 在各工具 `params` 中的字段名。
  static const amapKey = 'amapKey';

  /// 图像模型实体 id 在 `generate_image` 工具 `params` 中的字段名。
  static const imageModelId = 'imageModelId';
}
