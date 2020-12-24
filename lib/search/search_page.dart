import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:allpass/core/param/config.dart';
import 'package:allpass/core/param/allpass_type.dart';
import 'package:allpass/core/model/data/base_model.dart';
import 'package:allpass/core/param/constants.dart';
import 'package:allpass/password/widget/password_widget_item.dart';
import 'package:allpass/password/model/password_bean.dart';
import 'package:allpass/card/model/card_bean.dart';
import 'package:allpass/card/widget/card_widget_item.dart';
import 'package:allpass/common/ui/allpass_ui.dart';
import 'package:allpass/common/widget/confirm_dialog.dart';
import 'package:allpass/util/encrypt_util.dart';
import 'package:allpass/util/string_util.dart';
import 'package:allpass/card/data/card_provider.dart';
import 'package:allpass/password/data/password_provider.dart';
import 'package:allpass/card/page/view_card_page.dart';
import 'package:allpass/card/page/edit_card_page.dart';
import 'package:allpass/password/page/edit_password_page.dart';
import 'package:allpass/password/page/view_password_page.dart';

class SearchPage extends StatefulWidget {
  final AllpassType type;

  SearchPage(this.type);

  @override
  State<SearchPage> createState() => _SearchPage(type);
}

class _SearchPage extends State<SearchPage> {
  final AllpassType _type;

  String _searchText = "";
  TextEditingController _searchController;
  List<Widget> _result = List();

  _SearchPage(this._type) {
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: searchWidget(),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder(
        future: getSearchResult(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.active:
              return Center(
                child: CircularProgressIndicator(),
              );
            case ConnectionState.waiting:
              return Center(
                child: CircularProgressIndicator(),
              );
            case ConnectionState.done:
              return _result.length == 0
                  ? Center(
                      child: Text("无结果"),
                    )
                  : ListView.builder(
                      itemBuilder: (_, index) => _result[index],
                      itemCount: _result.length,
                    );
            default:
              return Center(child: Text("未知状态，请联系开发者：sys6511@126.com"));
          }
        },
      ),
    );
  }

  Future<Null> getSearchResult() async {
    _result.clear();
    _searchText = _searchController.text.toLowerCase();
    if (_type == AllpassType.Password) {
      PasswordProvider provider = Provider.of<PasswordProvider>(context);
      for (int index = 0; index < provider.count; index++) {
        var item = provider.passwordList[index];
        if (containsKeyword(item)) {
          _result.add(PasswordWidgetItem(
            data: item,
            onPasswordClicked: () {
              showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return createPassBottomSheet(context, index, item);
                  });
            },
          ));
        }
      }
    } else {
      CardProvider provider = Provider.of<CardProvider>(context);
      for (int index = 0; index < provider.count; index++) {
        var item = provider.cardList[index];
        if (containsKeyword(item)) {
          _result.add(SimpleCardWidgetItem(
            data: provider.cardList[index],
            onCardClicked: () {
              showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return createCardBottomSheet(context, item, index);
                  });
            },
          ));
        }
      }
    }
  }

  bool containsKeyword(BaseModel baseModel) {
    if (baseModel is PasswordBean) {
      StringBuffer stringBuffer = StringBuffer();
      stringBuffer.write(baseModel.name.toLowerCase());
      stringBuffer.write(baseModel.username.toLowerCase());
      stringBuffer.write(baseModel.notes.toLowerCase());
      stringBuffer.write(StringUtil.list2PureStr(baseModel.label).toLowerCase());
      return stringBuffer.toString().contains(_searchText);
    } else if (baseModel is CardBean) {
      StringBuffer stringBuffer = StringBuffer();
      stringBuffer.write(baseModel.name.toLowerCase());
      stringBuffer.write(baseModel.ownerName.toLowerCase());
      stringBuffer.write(baseModel.notes.toLowerCase());
      stringBuffer.write(StringUtil.list2PureStr(baseModel.label).toLowerCase());
      return stringBuffer.toString().contains(_searchText);
    }
    return false;
  }

  /// 搜索栏
  Widget searchWidget() {
    return Container(
        padding: EdgeInsets.only(left: 0, right: 0, bottom: 11, top: 11),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(AllpassUI.smallBorderRadius)),
                  color: Theme.of(context).inputDecorationTheme.fillColor,
                ),
                height: 35,
                child: TextField(
                  style: TextStyle(fontSize: 14),
                  controller: _searchController,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.only(left: 20, right: 20),
                    hintText: "搜索名称、用户名、备注或标签",
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Config.lightTheme == 'dark'
                          ? Colors.grey
                          : Colors.grey[900],),
                  ),
                  onChanged: (_) async {
                    await getSearchResult();
                    setState(() {});
                  },
                  onEditingComplete: () async {
                    if (_type == AllpassType.Password) {
                      await Provider.of<PasswordProvider>(context).refresh();
                    } else if (_type == AllpassType.Card) {
                      await Provider.of<CardProvider>(context).refresh();
                    }
                    await getSearchResult();
                    setState(() {});
                  },
                  autofocus: true,
                ),
              )
            ),
            InkWell(
              child: Padding(
                padding: EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
                child: Text("取消", style: AllpassTextUI.secondTitleStyle),
              ),
              onTap: () => Navigator.pop(context),
            )
          ],
        ));
  }

  // 点击密码弹出模态菜单
  Widget createPassBottomSheet(BuildContext context, int index, PasswordBean data) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ListTile(
          leading: Icon(Icons.remove_red_eye, color: Colors.lightGreen,),
          title: Text("查看"),
          onTap: () {
            Navigator.push(context, CupertinoPageRoute(
                builder: (context) => ViewPasswordPage(index)))
                .then((_) => Navigator.pop(context));
          },
        ),
        ListTile(
          leading: Icon(Icons.edit, color: Colors.blue,),
          title: Text("编辑"),
          onTap: () {
            Navigator.push(context, CupertinoPageRoute(
                builder: (context) => EditPasswordPage(data, DataOperation.update)))
                .then((reData) => Navigator.pop(context));
          },
        ),
        ListTile(
          leading: Icon(Icons.person, color: Colors.teal,),
          title: Text("复制用户名"),
          onTap: () {
            Clipboard.setData(ClipboardData(text: data.username));
            Fluttertoast.showToast(msg: "已复制用户名");
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: Icon(Icons.content_copy, color: Colors.orange,),
          title: Text("复制密码"),
          onTap: () async {
            String pw = EncryptUtil.decrypt(data.password);
            Clipboard.setData(ClipboardData(text: pw));
            Fluttertoast.showToast(msg: "已复制密码");
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: Icon(Icons.delete_outline, color: Colors.red,),
          title: Text("删除密码"),
          onTap: () async {
            bool delete = await showDialog(
                context: context,
                builder: (context) => ConfirmDialog("确认删除", "你将删除此密码，确认吗？"));
            if (delete) {
              await Provider.of<PasswordProvider>(context).deletePassword(data);
              Navigator.pop(context);
            }
          },
        )
      ],
    );
  }

  // 点击卡片弹出模态菜单
  Widget createCardBottomSheet(BuildContext context, CardBean data, int index) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ListTile(
          leading: Icon(Icons.remove_red_eye, color: Colors.lightGreen,),
          title: Text("查看"),
          onTap: () {
            Navigator.push(context, CupertinoPageRoute(
                builder: (context) => ViewCardPage(index)))
                .then((_) => Navigator.pop(context));
          }),
        ListTile(
          leading: Icon(Icons.edit, color: Colors.blue,),
          title: Text("编辑"),
          onTap: () {
            Navigator.push(context, CupertinoPageRoute(
                builder: (context) => EditCardPage(data, DataOperation.update)))
                .then((_) => Navigator.pop(context));
          }),
        ListTile(
          leading: Icon(Icons.person, color: Colors.teal,),
          title: Text("复制用户名"),
          onTap: () {
            Clipboard.setData(ClipboardData(text: data.ownerName));
            Fluttertoast.showToast(msg: "已复制用户名");
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: Icon(Icons.content_copy, color: Colors.orange,),
          title: Text("复制卡号"),
          onTap: () {
            Clipboard.setData(ClipboardData(text: data.cardId));
            Fluttertoast.showToast(msg: "已复制卡号");
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: Icon(Icons.delete_outline, color: Colors.red,),
          title: Text("删除卡片"),
          onTap: () async {
            bool delete = await showDialog(
                context: context,
                builder: (context) => ConfirmDialog("确认删除", "你将删除此卡片，确认吗？"));
            if (delete) {
              await Provider.of<CardProvider>(context).deleteCard(data);
              Navigator.pop(context);
            }
          }
        )
      ],
    );
  }
}
