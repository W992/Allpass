import 'package:flutter/material.dart';

import 'package:allpass/bean/password_bean.dart';
import 'package:allpass/params/changed.dart';
import 'package:allpass/utils/allpass_ui.dart';

/// 查看或编辑密码页面
class ViewAndEditPasswordPage extends StatefulWidget {
  final PasswordBean data;

  ViewAndEditPasswordPage(this.data);

  @override
  _ViewPasswordPage createState() {
    return _ViewPasswordPage(data);
  }
}

class _ViewPasswordPage extends State<ViewAndEditPasswordPage> {

  final PasswordBean oldData;
  PasswordBean newData;

  bool _passwordVisible = false;

  _ViewPasswordPage(this.oldData);

  @override
  Widget build(BuildContext context) {

    newData = PasswordBean(oldData.key, oldData.username, oldData.password, oldData.url,
        name: oldData.name, folder: oldData.folder,
        label: oldData.label, notes: oldData.notes);

    var nameController = TextEditingController(text: newData.name);
    var usernameController = TextEditingController(text: newData.username);
    var passwordController = TextEditingController(text: newData.password);
    var notesController = TextEditingController(text: newData.notes);
    var urlController = TextEditingController(text: newData.url);

    return WillPopScope(
      onWillPop: () {
        Navigator.of(context).pop(oldData);
        return Future<bool>.value(false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "查看密码",
            style: AllpassTextUI.firstTitleStyleBlack,
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.check,
                color: Colors.black,
              ),
              onPressed: () {
                print("点击了保存按钮");
                Navigator.pop<PasswordBean>(context, newData);
              },
            )
          ],
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
          elevation: 0,
        ),
        body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(left: 40, right: 40, bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "名称",
                        style: AllpassTextUI.firstTitleStyleBlue,
                      ),
                      TextField(
                        controller: nameController,
                        onChanged: (text) {
                          newData.name = text;
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(left: 40, right: 40, bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "URL",
                        style: AllpassTextUI.firstTitleStyleBlue,
                      ),
                      TextField(
                        controller: urlController,
                        onChanged: (text) {
                          newData.url = text;
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(left: 40, right: 40, bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "用户名",
                        style: AllpassTextUI.firstTitleStyleBlue,
                      ),
                      TextField(
                        controller: usernameController,
                        onChanged: (text) {
                          newData.username = text;
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(left: 40, right: 40, bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "密码",
                        style: AllpassTextUI.firstTitleStyleBlue,
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: passwordController,
                              obscureText: !_passwordVisible,
                              onChanged: (text) {
                                newData.password = text;
                              },
                            ),
                          ),
                          IconButton(
                            icon: _passwordVisible == true
                                ? Icon(Icons.visibility)
                                : Icon(Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                if (_passwordVisible == false)
                                  _passwordVisible = true;
                                else
                                  _passwordVisible = false;
                              });
                            },
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(left: 40, right: 40, bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "文件夹",
                        style: AllpassTextUI.firstTitleStyleBlue,
                      ),
                      // TODO 修改后页面无反应
                      DropdownButton<String>(
                        value: newData.folder,
                        onChanged: (String newValue) {
                          setState(() {
                            newData.folder = newValue;
                          });
                        },
                        items: FolderAndLabelList.folderList
                             .map<DropdownMenuItem<String>>((String value) {
                           return DropdownMenuItem<String>(
                             value: value,
                             child: Text(value),
                           );
                         }).toList(),
                        style: AllpassTextUI.firstTitleStyleBlack,
                        elevation: 8,
                        iconSize: 30,
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(left: 40, right: 40, bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.only(bottom: 10),
                        child: Text(
                          "标签",
                          style: AllpassTextUI.firstTitleStyleBlue,
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          Wrap(
                              crossAxisAlignment: WrapCrossAlignment.start,
                              spacing: 8.0,
                              runSpacing: 10.0,
                              children: _getTag()
                          )
                        ],
                      )
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(left: 40, right: 40, bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "备注",
                        style: AllpassTextUI.firstTitleStyleBlue,
                      ),
                      TextField(
                        controller: notesController,
                        onChanged: (text) {
                          newData.notes = text;
                        },
                      ),
                    ],
                  ),
                )
              ],
            )),
        backgroundColor: Colors.white,
      ),
    );
  }

  List<Widget> _getTag() {
      List<Widget> labelChoices = List();
      FolderAndLabelList.labelList.forEach((item) {
        labelChoices.add(ChoiceChip(
          label: Text(item),
          labelStyle: AllpassTextUI.secondTitleStyleBlack,
          selected: oldData.label.contains(item),
          onSelected: (selected) {
            setState(() {
              oldData.label.contains(item)
                  ? oldData.label.remove(item)
                  : oldData.label.add(item);
            });
          },
          selectedColor: AllpassColorUI.mainColor,
        ));
      });
      return labelChoices;
  }
}

