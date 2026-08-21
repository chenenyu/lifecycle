/*
 * 集中声明 example 使用的命名路由。
 *
 * 常量表避免页面、测试和 Navigator 查询各自硬编码字符串，防止重命名时出现只修改
 * 一部分调用点的情况；abstract final 阻止无意义实例化。
 */

/// 示例页面共享的命名路由常量。
abstract final class DemoRoutes {
  static const details = '/details';
  static const pages = '/pages';
  static const reorderablePages = '/reorderable-pages';
  static const tabs = '/tabs';
  static const viewport = '/viewport';
  static const nestedNavigator = '/nested-navigator';
  static const declarativeNavigator = '/declarative-navigator';
  static const controllerLab = '/controller-lab';
}
