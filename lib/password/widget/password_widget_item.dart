import 'dart:io';

import 'package:allpass/common/ui/allpass_ui.dart';
import 'package:allpass/core/param/config.dart';
import 'package:allpass/password/data/password_provider.dart';
import 'package:allpass/password/model/password_bean.dart';
import 'package:allpass/encrypt/encrypt_util.dart';
import 'package:allpass/util/toast_util.dart';
import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class MaterialPasswordWidget extends StatelessWidget {
  final PasswordBean data;

  final WidgetBuilder pageCreator;

  final VoidCallback? onClick;

  final double containerShape;

  final Color? itemColor;

  const MaterialPasswordWidget({
    Key? key,
    required this.data,
    required this.containerShape,
    required this.pageCreator,
    this.onClick,
    this.itemColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return PasswordWidgetItem(
        key: key,
        data: data,
        onPasswordClicked: () {
          onClick?.call();
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (ctx) => pageCreator.call(ctx)),
          );
        },
      );
    }

    var backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    return OpenContainer(
      openBuilder: (context, closedContainer) {
        return pageCreator.call(context);
      },
      openColor: backgroundColor,
      closedColor: itemColor ?? backgroundColor,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(this.containerShape)),
      ),
      closedElevation: 0,
      closedBuilder: (context, openContainer) {
        return PasswordWidgetItem(
          key: key,
          data: data,
          onPasswordClicked: () {
            onClick?.call();
            openContainer();
          },
        );
      },
    );
  }
}

class PasswordWidgetItem extends StatelessWidget {
  final Key? key;

  final PasswordBean data;

  final VoidCallback? onPasswordClicked;

  PasswordWidgetItem({this.key, required this.data, this.onPasswordClicked})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
   GestureLongPressCallback? longPressCallback;
    if (Config.longPressCopy) {
      longPressCallback = () {
        Clipboard.setData(ClipboardData(
          text: EncryptUtil.decrypt(data.password),
        ));
        ToastUtil.show(msg: "已复制密码");
      };
    }

    return Container(
      margin: AllpassEdgeInsets.listInset,
      child: GestureDetector(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: data.color,
            child: Text(
              data.name.substring(0, 1),
              style: TextStyle(color: Colors.white),
            ),
          ),
          title: Text(
            data.name,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            data.username,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => onPasswordClicked?.call(),
          onLongPress: longPressCallback,
        ),
      ),
    );
  }
}

class MultiPasswordWidgetItem extends StatefulWidget {
  final Key? key;
  final PasswordBean password;
  final bool Function(PasswordBean) selection;
  final void Function(bool, PasswordBean) onChanged;

  const MultiPasswordWidgetItem({
    this.key,
    required this.password,
    required this.selection,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MultiPasswordWidgetItem();
  }
}

class _MultiPasswordWidgetItem extends State<MultiPasswordWidgetItem> {
  @override
  Widget build(BuildContext context) {
    return Consumer<PasswordProvider>(
      builder: (context, model, child) {
        var data = widget.password;
        return Container(
          margin: AllpassEdgeInsets.listInset,
          child: CheckboxListTile(
            value: widget.selection(data),
            onChanged: (value) {
              widget.onChanged(value ?? false, data);
            },
            secondary: CircleAvatar(
              backgroundColor: data.color,
              child: Text(
                data.name.substring(0, 1),
                style: TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              data.name,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              data.username,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}
