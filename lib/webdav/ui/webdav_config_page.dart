import 'package:allpass/common/ui/allpass_ui.dart';
import 'package:allpass/common/widget/information_help_dialog.dart';
import 'package:allpass/common/widget/loading_text_button.dart';
import 'package:allpass/common/widget/none_border_circular_textfield.dart';
import 'package:allpass/core/di/di.dart';
import 'package:allpass/core/param/config.dart';
import 'package:allpass/ui/after_post_frame.dart';
import 'package:allpass/util/toast_util.dart';
import 'package:allpass/webdav/service/webdav_sync_service.dart';
import 'package:allpass/webdav/ui/webdav_sync_page.dart';
import 'package:allpass/webdav/ui/webdav_sync_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class WebDavConfigPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _WebDavConfigPage();
  }
}

class _WebDavConfigPage extends State<StatefulWidget> with AfterFirstFrameMixin {
  late TextEditingController _urlController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _portController;
  late WebDavSyncService _syncService;

  bool _pressNext = false;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _portController = TextEditingController();
    _syncService = inject();
  }

  @override
  void dispose() {
    super.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _portController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color mainColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "账号配置",
          style: AllpassTextUI.titleBarStyle,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              String example = "https://dav.jianguoyun.com/dav/";
              showDialog(
                context: context,
                builder: (context) => InformationHelpDialog(
                  content: [
                    Text("此功能可以将您的数据备份到 WebDAV 服务器中或者进行数据恢复.\n"),
                    Text("WebDAV 服务器地址请以 http:// 或 https:// 开头，如坚果云(点击复制)：\n"),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: example));
                        ToastUtil.show(msg: "复制成功");
                      },
                      child: Text(example)),
                    Text("\n"),
                    Text("端口号代表服务所在端口，如果您不清楚，请不要编辑.")
                  ],
                )
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(left: 30, right: 30, bottom: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              NoneBorderCircularTextField(
                editingController: _urlController,
                labelText: "WebDAV服务器地址",
                hintText: "请以 http:// 或 https:// 开头",
                onChanged: _setPortAutomatically,
                trailing: InkWell(
                  child: Icon(
                    Icons.cancel,
                    size: 20,
                  ),
                  onTap: () => afterFirstFrame(() {
                    _urlController.clear();
                  }),
                ),
              ),
              NoneBorderCircularTextField(
                editingController: _portController,
                labelText: "端口号",
                trailing: InkWell(
                  child: Icon(
                    Icons.cancel,
                    size: 20,
                  ),
                  onTap: () => afterFirstFrame(() {
                    _portController.clear();
                  }),
                ),
              ),
              NoneBorderCircularTextField(
                editingController: _usernameController,
                labelText: "账号",
                trailing: InkWell(
                  child: Icon(
                    Icons.cancel,
                    size: 20,
                  ),
                  onTap: () => afterFirstFrame(() {
                    _usernameController.clear();
                  }),
                ),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: NoneBorderCircularTextField(
                      editingController: _passwordController,
                      labelText: "密码",
                      obscureText: !_passwordVisible,
                      trailing: InkWell(
                        child: Icon(
                          Icons.cancel,
                          size: 20,
                        ),
                        onTap: () => afterFirstFrame(() {
                          _passwordController.clear();
                        }),
                      ),
                    ),
                  ),
                  Padding(
                    padding: AllpassEdgeInsets.smallLPadding,
                    child: InkWell(
                      child: _passwordVisible == true
                          ? Icon(Icons.visibility)
                          : Icon(Icons.visibility_off),
                      onTap: showPassword,
                    ),
                  )
                ],
              ),
              Padding(
                padding: AllpassEdgeInsets.smallTBPadding,
                child: LoadingTextButton(
                  color: mainColor,
                  title: "下一步",
                  loadingTitle: "配置中",
                  loading: _pressNext,
                  onPressed: () async => await _nextStep(),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<Null> _nextStep() async {
    var url = _urlController.text;
    if (!url.startsWith("http://") && !url.startsWith("https://")) {
      ToastUtil.showError(msg: "服务器地址需以http://或https://开头");
      return;
    }

    setState(() {
      _pressNext = !_pressNext;
    });
    if (_pressNext) {
      try {
        _syncService.updateConfig(
          urlPath: url,
          username: _usernameController.text,
          password: _passwordController.text,
          port: int.parse(_portController.text),
        );
      } on FormatException catch (_) {
        ToastUtil.showError(msg: "端口号必须为数字！");
        setState(() {
          _pressNext = false;
        });
        return;
      }
      bool auth = await _syncService.authCheck();
      if (auth) {
        _syncService.configPersistence();
        Config.setWebDavAuthSuccess(true);
        ToastUtil.show(msg: "账号验证成功");
        Navigator.pushReplacement(
            context,
            CupertinoPageRoute(
                builder: (context) => ChangeNotifierProvider(
                      create: (context) => WebDavSyncProvider(),
                      child: WebDavSyncPage(),
                    )));
      } else {
        Config.setWebDavAuthSuccess(false);
        ToastUtil.show(msg: "验证失败，请重试");
      }
      setState(() {
        _pressNext = false;
      });
    } else {
      _syncService.cancelAuthCheck();
    }
  }

  void _setPortAutomatically(String urlText) {
    if (_portController.text.isNotEmpty) {
      return;
    }

    var uri = Uri.parse(urlText);
    if (uri.hasPort) {
      _portController.text = uri.port.toString();
    } else if (uri.scheme == "https") {
      _portController.text = "443";
    } else if (uri.scheme == "http") {
      _portController.text = "80";
    }
  }

  void showPassword() {
    setState(() {
      _passwordVisible = !_passwordVisible;
    });
  }
}
