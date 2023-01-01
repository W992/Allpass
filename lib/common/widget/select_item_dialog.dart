import 'package:flutter/material.dart';

typedef WidgetBuilder<T> = Widget Function(BuildContext context, T data);
typedef StringBuilder = String? Function();
typedef StringGetter<T> = String Function(T);

abstract class SelectItemDialog<T> extends StatelessWidget {
  final Key? key;
  final List<T> list;
  final bool Function(T)? selector;
  final String? helpText;

  final bool Function(T) defaultSelector = (data) => false;

  SelectItemDialog({required this.list, this.selector, this.helpText, this.key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("请选择"),
      content: SingleChildScrollView(
        child: Column(children: _getList(context)),
      ),
      actions: buildActions(context),
    );
  }

  List<Widget> _getList(BuildContext context) {
    List<Widget> widgetList = [];
    if (helpText != null) {
      widgetList.add(Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text(
          helpText!,
          style: Theme.of(context).textTheme.caption?.copyWith(fontSize: 12),
        ),
      ));
    }

    for (T data in list) {
      widgetList.add(buildItem(context, data));
    }
    return widgetList;
  }

  List<Widget> buildActions(BuildContext context) {
    return [];
  }

  Widget buildItem(BuildContext context, T data);
}

class DefaultSelectItemDialog<T> extends SelectItemDialog<T> {
  final StringBuilder? titleBuilder;
  final WidgetBuilder<T>? itemBuilder;
  final StringGetter<T>? itemTitleBuilder;
  final void Function(T) onSelected;

  final Widget Function(T, StringGetter<T>?) _defaultItemBuilder =
      (data, titleBuilder) => Text(titleBuilder?.call(data) ?? data.toString());
  final StringBuilder _defaultTitleBuilder = () => "请选择";

  DefaultSelectItemDialog({
    required List<T> list,
    required this.onSelected,
    this.titleBuilder,
    this.itemBuilder,
    this.itemTitleBuilder,
    bool Function(T)? selector,
    String? helpText,
    Key? key,
  }) : super(list: list, key: key, selector: selector, helpText: helpText);

  @override
  Widget build(BuildContext context) {
    var title = (titleBuilder ?? _defaultTitleBuilder).call();
    return AlertDialog(
        title: title == null ? null : Text(title),
        content: SingleChildScrollView(
          child: Column(children: _getList(context)),
        ));
  }

  @override
  Widget buildItem(BuildContext context, T data) {
    var itemTitle = itemBuilder?.call(context, data);
    var selected = selector?.call(data) ?? defaultSelector(data);
    return ListTile(
        title: itemTitle ?? _defaultItemBuilder(data, itemTitleBuilder),
        trailing: selected ? Icon(Icons.check, color: Colors.grey) : null,
        onTap: () {
          Navigator.pop<T>(context, data);
          onSelected.call(data);
        });
  }
}
