import 'package:allpass/common/ui/allpass_ui.dart';
import 'package:allpass/common/widget/confirm_dialog.dart';
import 'package:allpass/common/widget/empty_data_widget.dart';
import 'package:allpass/common/widget/multi_edit_button.dart';
import 'package:allpass/common/widget/route_floating_action_button.dart';
import 'package:allpass/common/widget/select_item_dialog.dart';
import 'package:allpass/core/enums/allpass_type.dart';
import 'package:allpass/core/param/constants.dart';
import 'package:allpass/core/param/runtime_data.dart';
import 'package:allpass/extension/widget_extension.dart';
import 'package:allpass/password/data/password_provider.dart';
import 'package:allpass/password/model/password_bean.dart';
import 'package:allpass/password/page/edit_password_page.dart';
import 'package:allpass/common/data/multi_item_edit_provider.dart';
import 'package:allpass/password/page/view_password_page.dart';
import 'package:allpass/password/widget/letter_index_bar.dart';
import 'package:allpass/password/widget/password_widget_item.dart';
import 'package:allpass/search/search_page.dart';
import 'package:allpass/search/search_provider.dart';
import 'package:allpass/search/widget/search_button_widget.dart';
import 'package:allpass/util/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 密码页面
class PasswordPage extends StatefulWidget {
  @override
  _PasswordPageState createState() {
    return _PasswordPageState();
  }
}

class _PasswordPageState extends State<PasswordPage>
    with AutomaticKeepAliveClientMixin {
  late ScrollController _controller;

  @override
  void initState() {
    _controller = ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  Future<Null> _query(PasswordProvider model) async {
    await model.refresh();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: AllpassEdgeInsets.smallLPadding,
          child: InkWell(
            splashColor: Colors.transparent,
            child: Text(
              "密码",
              style: AllpassTextUI.titleBarStyle,
            ),
            onTap: _controller.scrollToTop,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: _buildAppBarActions(),
      ),
      body: Column(
        children: <Widget>[
          // 搜索框 按钮
          SearchButtonWidget(_searchPress, "密码"),
          // 密码列表
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _query(context.read<PasswordProvider>()),
              child: Scrollbar(
                child: _buildPasswordContent(),
              ),
            ),
          )
        ],
      ),
      floatingActionButton: Selector<MultiItemEditProvider<PasswordBean>, bool>(
        selector: (_, editProvider) => editProvider.editMode,
        builder: (_, editMode, child) => editMode ? Container() : child!,
        child: MaterialRouteFloatingActionButton(
          heroTag: "add_password",
          tooltip: "添加密码条目",
          builder: (_) => EditPasswordPage(null, DataOperation.add),
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  void _searchPress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: SearchProvider(AllpassType.password, context),
          child: SearchPage(AllpassType.password),
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      Selector<MultiItemEditProvider<PasswordBean>, bool>(
        selector: (_, editProvider) => editProvider.editMode,
        builder: (context, editMode, __) {
          var provider = context.read<PasswordProvider>();
          var editProvider = context.read<MultiItemEditProvider<PasswordBean>>();
          return MultiEditButton(
            inEditMode: editMode,
            onClickMove: () => _movePassword(context, provider, editProvider),
            onClickDelete: () => _deletePassword(context, provider, editProvider),
            onClickEdit: editProvider.switchEditMode,
            onClickSelectAll: () {
              if (editProvider.selectedCount != provider.count) {
                editProvider.selectAll(provider.passwordList);
              } else {
                editProvider.unselectAll();
              }
            },
          );
        },
      )
    ];
  }

  Widget _buildPasswordContent() {
    return Selector<PasswordProvider, bool>(
      selector: (_, provider) => provider.passwordList.isEmpty,
      builder: (_, empty, emptyWidget) {
        if (empty) {
          return emptyWidget!;
        } else {
          return _buildPasswordList();
        }
      },
      child: const EmptyDataWidget(subtitle: "这里存储你的密码信息，例如\n微博账号、知乎账号等"),
    );
  }

  Widget _buildPasswordList() {
    return Consumer2<PasswordProvider, MultiItemEditProvider<PasswordBean>>(
      builder: (_, provider, editProvider, postList) {
        if (editProvider.editMode) {
          return ListView.builder(
            controller: _controller,
            itemBuilder: (context, index) => MultiPasswordWidgetItem(
              password: provider.passwordList[index],
              selection: editProvider.isSelected,
              onChanged: editProvider.select,
            ),
            itemCount: provider.count,
            physics: const AlwaysScrollableScrollPhysics(),
          );
        } else {
          return postList!;
        }
      },
      child: Stack(
        children: <Widget>[
          Consumer<PasswordProvider>(
            builder: (_, provider, __) => ListView.builder(
              controller: _controller,
              itemBuilder: (context, index) {
                return MaterialPasswordWidget(
                  data: provider.passwordList[index],
                  containerShape: 0,
                  pageCreator: (_) => ViewPasswordPage(),
                  onClick: () => provider.previewPassword(index: index),
                );
              },
              itemCount: provider.count,
              physics: const AlwaysScrollableScrollPhysics(),
            ),
          ),
          LetterIndexBar(_controller),
        ],
      ),
    );
  }

  void _deletePassword(
    BuildContext context,
    PasswordProvider provider,
    MultiItemEditProvider<PasswordBean> editProvider,
  ) {
    if (editProvider.isEmpty) {
      ToastUtil.show(msg: "请选择至少一项密码");
    } else {
      showDialog<bool>(
        context: context,
        builder: (context) => ConfirmDialog(
          "确认删除",
          "您将删除${editProvider.selectedCount}项密码，确认吗？",
          danger: true,
          onConfirm: () async {
            for (var item in editProvider.selectedItem) {
              await provider.deletePassword(item);
            }
            ToastUtil.show(msg: "已删除 ${editProvider.selectedCount} 项密码");
            editProvider.unselectAll();
          },
        ),
      );
    }
  }

  void _movePassword(
    BuildContext context,
    PasswordProvider provider,
    MultiItemEditProvider<PasswordBean> editProvider,
  ) {
    if (editProvider.isEmpty) {
      ToastUtil.show(msg: "请选择至少一项密码");
    } else {
      showDialog(
        context: context,
        builder: (context) => DefaultSelectItemDialog<String>(
          list: RuntimeData.folderList,
          onSelected: (value) async {
            editProvider.selectedItem.forEach((element) async {
              element.folder = value;
              await provider.updatePassword(element);
            });
            ToastUtil.show(
              msg: "已移动 ${editProvider.selectedCount} 项密码至 $value 文件夹",
            );
            editProvider.unselectAll();
          },
        ),
      );
    }
  }
}
