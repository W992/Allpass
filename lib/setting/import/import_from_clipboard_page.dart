import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:allpass/common/ui/allpass_ui.dart';
import 'package:allpass/util/screen_util.dart';
import 'package:allpass/util/toast_util.dart';
import 'package:allpass/encrypt/encrypt_util.dart';
import 'package:allpass/password/model/password_bean.dart';
import 'package:allpass/password/data/password_provider.dart';
import 'package:allpass/common/widget/loading_text_button.dart';
import 'package:allpass/common/widget/information_help_dialog.dart';
import 'package:allpass/common/widget/none_border_circular_textfield.dart';

/// 从剪贴板中导入
class ImportFromClipboardPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ImportFromClipboardPage();
  }
}

class _ImportFromClipboardPage extends State<ImportFromClipboardPage> {

  late TextEditingController _controller;

  int _groupValue = 1;

  bool importing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color mainColor = Theme.of(context).primaryColor;
    var fillColor = MaterialStateColor.resolveWith((states) {
      if (states.contains(MaterialState.selected)) return mainColor;
      return Colors.grey;
    });
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "从剪贴板导入",
            style: AllpassTextUI.titleBarStyle,
          ),
          centerTitle: true,
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.help_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => InformationHelpDialog(
                    content: <Widget>[
                      Text("此功能帮助您轻松地从之前在记事本中保存的密码导入到Allpass中；\n"),
                      Text("名称是密码的助记符，您可以随便起一个名称来让您知道此条记录是什么内容；\n"),
                      Text("账号是登录使用的账号名，有可能是手机、邮箱或者其他您设置的账号；\n"),
                      Text("网站地址可以帮助Allpass在正确的网站填充您的密码，大多数情况下是网站登录页的URL地址；\n"),
                      Text("两个字段之间请以“空格”作为分隔符，这样Allpass才能正确分辨哪个是用户名，哪个是密码；\n"),
                      Text("如果选择了最后一个导入格式，请在第一行输入统一的用户名；如果有多个用户名，可以分为几次导入；")
                    ],
                  )
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                alignment: Alignment.centerLeft,
                padding: AllpassEdgeInsets.forCardInset,
                child: Text(
                  "请选择密码格式（空格为分隔符）",
                  style: TextStyle(
                    fontSize: 16
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: AllpassEdgeInsets.dividerInset,
                child: Column(
                  children: <Widget>[
                    InkWell(
                      child: Row(
                        children: <Widget>[
                          Radio<int>(
                            fillColor: fillColor,
                            value: 1, // "名称 账号 密码 网站地址"
                            groupValue: _groupValue,
                            onChanged: (value) {
                              setState(() {
                                _groupValue = value!;
                              });
                            },
                          ),
                          Text("名称 账号 密码 网站地址", style: AllpassTextUI.firstTitleStyle,),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _groupValue = 1;
                        });
                      },
                    ),
                    InkWell(
                      child: Row(
                        children: <Widget>[
                          Radio<int>(
                            value: 2, // "名称 账号 密码",
                            fillColor: fillColor,
                            groupValue: _groupValue,
                            onChanged: (value) {
                              setState(() {
                                _groupValue = value!;
                              });
                            },
                          ),
                          Text("名称 账号 密码", style: AllpassTextUI.firstTitleStyle,),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _groupValue = 2;
                        });
                      },
                    ),
                    InkWell(
                      child: Row(
                        children: <Widget>[
                          Radio<int>(
                            value: 3, // "账号 密码 网站地址",
                            groupValue: _groupValue,
                            fillColor: fillColor,
                            onChanged: (value) {
                              setState(() {
                                _groupValue = value!;
                              });
                            },
                          ),
                          Text("账号 密码 网站地址", style: AllpassTextUI.firstTitleStyle,),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _groupValue = 3;
                        });
                      },
                    ),
                    InkWell(
                      child: Row(
                        children: <Widget>[
                          Radio<int>(
                            value: 4, // "账号 密码",
                            fillColor: fillColor,
                            groupValue: _groupValue,
                            onChanged: (value) {
                              setState(() {
                                _groupValue = value!;
                              });
                            },
                          ),
                          Text("账号 密码", style: AllpassTextUI.firstTitleStyle,),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _groupValue = 4;
                        });
                      },
                    ),
                    InkWell(
                      child: Row(
                        children: <Widget>[
                          Radio<int>(
                            value: 5, // "密码",
                            fillColor: fillColor,
                            groupValue: _groupValue,
                            onChanged: (value) {
                              setState(() {
                                _groupValue = value!;
                              });
                              ToastUtil.show(msg: "请在第一行输入默认账号");
                            },
                          ),
                          Text("名称 密码", style: AllpassTextUI.firstTitleStyle,),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _groupValue = 5;
                        });
                        ToastUtil.show(msg: "请在第一行输入默认账号");
                      },
                    ),
                  ],
                ),
              ),
              Container(
                padding: AllpassEdgeInsets.forViewCardInset,
                height: AllpassScreenUtil.setHeight(1000),
                child: NoneBorderCircularTextField(
                  editingController: _controller,
                  maxLines: 1000,
                  hintText: "在此粘贴您的数据",
                )
              ),
              Container(
                  padding: AllpassEdgeInsets.forViewCardInset,
                  child: LoadingTextButton(
                    title: "开始导入",
                    loadingTitle: "导入中请稍后",
                    loading: importing,
                    color: Theme.of(context).primaryColor,
                    onPressed: () async {
                      setState(() {
                        importing = true;
                      });
                      try {
                        List<PasswordBean> list = await parseText(_groupValue);
                        for (var bean in list) {
                          await context.read<PasswordProvider>().insertPassword(bean);
                        }
                        ToastUtil.show(msg: "导入了${list.length}条记录");
                      } catch (e) {
                        ToastUtil.show(msg: e.toString());
                      }
                      setState(() {
                        importing = false;
                      });
                    },
                  )
              ),
              Padding(
                padding: AllpassEdgeInsets.smallTBPadding,
              )
            ],
          ),
        ));
  }

  Future<List<PasswordBean>> parseText(int value) async {
    String text = _controller.text;
    if (text.isEmpty) return [];
    List<String> tempRows = text.split("\n");
    List<String> rows = [];
    for (String tr in tempRows) {
      if (tr.trim().length <= 1) continue;
      else rows.add(tr);
    }
    List<PasswordBean> temp = [];
    // 下面这种情况需要设置默认用户名
    if (value == 5) {
      String defaultUsername = rows[0];
      for (String row in rows.sublist(1)) {
        List<String> tempFields = row.split(" ");
        List<String> fields = [];
        // 确保不会出现空字段
        for (String field in tempFields) {
          if (field == "") continue;
          else fields.add(field);
        }
        if (fields.length < 2) throw Exception("某条记录格式不正确！");
        temp.add(PasswordBean(
          name: fields[0],
          username: defaultUsername,
          password: EncryptUtil.encrypt(fields[1]),
          url: ""
        ));
      }
      return temp;
    }
    // 不用单独设置默认用户名
    for (String row in rows) {
      if (row.length <= 3) continue;
      List<String> tempFields = row.split(" ");
      List<String> fields = [];
      for (String field in tempFields) {
        if (field == "") continue;
        else fields.add(field);
      }
      if (value == 1) {
        if (fields.length < 4) throw Exception("某条记录格式不正确！");
        temp.add(PasswordBean(
          name: fields[0],
          username: fields[1],
          password: EncryptUtil.encrypt(fields[2]),
          url: fields[3],
        ));
      } else if (value == 2) {
        if (fields.length < 3) throw Exception("某条记录格式不正确！");
        temp.add(PasswordBean(
          name: fields[0],
          username: fields[1],
          password: EncryptUtil.encrypt(fields[2]),
          url: "",
        ));
      } else if (value == 3) {
        if (fields.length < 3) throw Exception("某条记录格式不正确！");
        temp.add(PasswordBean(
          name: "",
          username: fields[0],
          password: EncryptUtil.encrypt(fields[1]),
          url: fields[2],
        ));
      } else if (value == 4) {
        if (fields.length < 2) throw Exception("某条记录格式不正确！");
        temp.add(PasswordBean(
          name: "",
          username: fields[0],
          password: EncryptUtil.encrypt(fields[1]),
          url: "",
        ));
      }
    }
    return temp;
  }
}
