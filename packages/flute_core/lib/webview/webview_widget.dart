import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'webview_config.dart';
import 'webview_controller.dart';

/// WebView组件
/// 提供完整的WebView UI组件，集成了控制器和配置管理
class WebviewWidget extends StatefulWidget {
  /// WebView配置
  final WebviewConfig config;

  /// WebView控制器
  final WebviewController? controller;

  /// 是否显示进度条
  final bool showProgressBar;

  /// 进度条颜色
  final Color? progressBarColor;

  /// 错误页面构建器
  final Widget Function(String error)? errorPageBuilder;

  /// 加载页面构建器
  final Widget Function()? loadingPageBuilder;

  /// 页面加载完成回调
  final VoidCallback? onPageFinished;

  /// 页面开始加载回调
  final VoidCallback? onPageStarted;

  /// 页面加载错误回调
  final Function(String error)? onPageError;

  /// 进度变化回调
  final Function(double progress)? onProgressChanged;

  /// 标题变化回调
  final Function(String? title)? onTitleChanged;

  /// URL变化回调
  final Function(String? url)? onUrlChanged;

  /// URL拦截回调
  /// 返回 NavigationActionPolicy.CANCEL 拦截跳转
  /// 返回 NavigationActionPolicy.ALLOW 允许跳转
  final Future<NavigationActionPolicy> Function(
    NavigationAction navigationAction,
  )?
  onShouldOverrideUrlLoading;

  /// 构造函数
  const WebviewWidget({
    super.key,
    required this.config,
    this.controller,
    this.showProgressBar = true,
    this.progressBarColor,
    this.errorPageBuilder,
    this.loadingPageBuilder,
    this.onPageFinished,
    this.onPageStarted,
    this.onPageError,
    this.onProgressChanged,
    this.onTitleChanged,
    this.onUrlChanged,
    this.onShouldOverrideUrlLoading, // 新增参数
  });

  @override
  State<WebviewWidget> createState() => _WebviewWidgetState();
}

class _WebviewWidgetState extends State<WebviewWidget> {
  /// WebView控制器实例
  late final WebviewController _controller;

  /// 错误信息
  String? _errorMessage;

  /// 是否显示错误页面
  bool _showErrorPage = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  /// 初始化控制器
  void _initializeController() {
    _controller = widget.controller ?? WebviewController(config: widget.config);

    // 设置回调
    _controller.onPageFinished = () {
      widget.onPageFinished?.call();
      if (mounted) {
        setState(() {
          _showErrorPage = false;
          _errorMessage = null;
        });
      }
    };

    _controller.onPageStarted = () {
      widget.onPageStarted?.call();
      if (mounted) {
        setState(() {
          _showErrorPage = false;
          _errorMessage = null;
        });
      }
    };

    _controller.onPageError = (error) {
      widget.onPageError?.call(error);
      if (mounted) {
        setState(() {
          _showErrorPage = true;
          _errorMessage = error;
        });
      }
    };

    _controller.onProgressChanged = widget.onProgressChanged;
    _controller.onTitleChanged = widget.onTitleChanged;
    _controller.onUrlChanged = widget.onUrlChanged;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 进度条
        if (widget.showProgressBar) _buildProgressBar(),

        // WebView内容区域
        Expanded(child: _buildWebViewContent()),
      ],
    );
  }

  /// 构建进度条
  Widget _buildProgressBar() {
    return StreamBuilder<WebviewState>(
      stream: _controller.stateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final isLoading = state?.isLoading ?? false;
        final progress = state?.loadingProgress ?? 0.0;

        if (!isLoading || progress >= 1.0) {
          return const SizedBox.shrink();
        }

        return LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.progressBarColor ?? Theme.of(context).primaryColor,
          ),
        );
      },
    );
  }

  /// 构建WebView内容
  Widget _buildWebViewContent() {
    // 显示错误页面
    if (_showErrorPage && _errorMessage != null) {
      return widget.errorPageBuilder?.call(_errorMessage!) ??
          _buildDefaultErrorPage();
    }

    // 显示WebView
    return InAppWebView(
      initialUrlRequest: widget.config.initialUrl != null
          ? URLRequest(url: WebUri(widget.config.initialUrl!))
          : null,
      initialSettings: widget.config.toInAppWebViewSettings(),
      shouldOverrideUrlLoading: _onShouldOverrideUrlLoading,
      onWebViewCreated: _onWebViewCreated,
      onLoadStart: _onLoadStart,
      onLoadStop: _onLoadStop,
      onReceivedError: _onReceivedError,
      onProgressChanged: _onProgressChanged,
      onTitleChanged: _onTitleChanged,
      onUpdateVisitedHistory: _onUpdateVisitedHistory,
    );
  }

  /// 构建默认错误页面
  Widget _buildDefaultErrorPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              '页面加载失败',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '未知错误',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _retryLoad, child: const Text('重试')),
          ],
        ),
      ),
    );
  }

  /// WebView创建回调
  void _onWebViewCreated(InAppWebViewController controller) {
    _controller.setWebViewController(controller);
  }

  /// 页面开始加载回调
  void _onLoadStart(InAppWebViewController controller, WebUri? url) {
    _controller.onPageStartedHandler(controller, url);
  }

  /// 页面加载完成回调
  void _onLoadStop(InAppWebViewController controller, WebUri? url) {
    _controller.onPageFinishedHandler(controller, url);
  }

  /// 页面加载错误回调
  void _onReceivedError(
    InAppWebViewController controller,
    WebResourceRequest request,
    WebResourceError error,
  ) {
    // 判断是否为主文档请求
    final isMainFrame = request.isForMainFrame ?? true;

    _controller.onPageErrorHandler(
      controller,
      request.url,
      error.type.toNativeValue() ?? 0,
      error.description,
      isForMainFrame: isMainFrame,
    );
  }

  /// 页面URL拦截回调
  Future<NavigationActionPolicy> _onShouldOverrideUrlLoading(
    InAppWebViewController controller,
    NavigationAction navigationAction,
  ) async {
    if (widget.onShouldOverrideUrlLoading != null) {
      final policy = await widget.onShouldOverrideUrlLoading!(navigationAction);
      return policy;
    }
    return NavigationActionPolicy.ALLOW;
  }

  /// 进度变化回调
  void _onProgressChanged(InAppWebViewController controller, int progress) {
    _controller.onProgressChangedHandler(controller, progress);
  }

  /// 标题变化回调
  void _onTitleChanged(InAppWebViewController controller, String? title) {
    _controller.onTitleChangedHandler(controller, title);
  }

  /// 访问历史更新回调
  void _onUpdateVisitedHistory(
    InAppWebViewController controller,
    WebUri? url,
    bool? androidIsReload,
  ) {
    _controller.updateWebViewUrl(url?.toString());
  }

  /// 重试加载
  void _retryLoad() {
    if (widget.config.initialUrl != null) {
      _controller.loadUrl(widget.config.initialUrl!);
    } else {
      _controller.reload();
    }
  }

  @override
  void dispose() {
    // 只有当控制器是内部创建的时候才释放
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }
}
