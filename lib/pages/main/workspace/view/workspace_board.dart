import 'package:appflowy_board/appflowy_board.dart';
import 'package:cross_scroll/cross_scroll.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:university_trello_analog/pages/main/workspace/bloc/workspace_bloc.dart';

class WorkspaceBoard extends StatefulWidget {
  const WorkspaceBoard({super.key});
  @override
  State<WorkspaceBoard> createState() => _WorkspaceBoardState();
}

class _WorkspaceBoardState extends State<WorkspaceBoard> {
  final AppFlowyBoardController controller = AppFlowyBoardController(
    onMoveGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {
      debugPrint('Move item from $fromIndex to $toIndex');
    },
    onMoveGroupItem: (groupId, fromIndex, toIndex) {
      debugPrint('Move $groupId:$fromIndex to $groupId:$toIndex');
    },
    onMoveGroupItemToGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {
      debugPrint('Move $fromGroupId:$fromIndex to $toGroupId:$toIndex');
    },
  );

  late AppFlowyBoardScrollController boardScrollController;
  final ScrollController scrollController = ScrollController();
  //TODO: Перенести в блок билдер
  @override
  void initState() {
    boardScrollController = AppFlowyBoardScrollController();
    final group1 = AppFlowyGroupData(id: "To Do", name: "To Do", items: [
      TextItem("Card 1"),
      TextItem("Card 2"),
      RichTextItem(title: "Card 3", subtitle: 'Сабтайтл'),
      TextItem("Card 4"),
      TextItem("Card 5"),
      TextItem("Card 6"),
      RichTextItem(title: "Card 7", subtitle: 'Сабтайтл'),
      RichTextItem(title: "Card 8", subtitle: 'Сабтайтл'),
      RichTextItem(title: "Card 9", subtitle: ''),
      //TextItem("Card 9"),
    ]);

    final group2 = AppFlowyGroupData(
      id: "In Progress",
      name: "In Progress",
      items: <AppFlowyGroupItem>[
        RichTextItem(title: "Card 10", subtitle: 'Сабтайтл'),
        TextItem("Card 11"),
      ],
    );

    final group3 = AppFlowyGroupData(
        id: "Done", name: "Done", items: <AppFlowyGroupItem>[]);
    final group4 =
        AppFlowyGroupData(id: "4", name: "d", items: <AppFlowyGroupItem>[]);

    controller.addGroup(group1);
    controller.addGroup(group2);
    controller.addGroup(group3);
    controller.addGroup(group4);
    for (var i = 0; i < 10; i++) {
      controller.addGroup(AppFlowyGroupData(
          id: i.toString(), name: i.toString(), items: <AppFlowyGroupItem>[]));
    }
    super.initState();
  }

  final config = AppFlowyBoardConfig(
    groupBackgroundColor: HexColor.fromHex('#F7F8FC'),
    stretchGroupHeight: false,
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<WorkspaceBloc, WorkspaceState>(
        builder: (context, state) {
          switch (state.status) {
            case WorkspaceStatus.initial:
              return Container();
            case WorkspaceStatus.loading:
              return Container();
            case WorkspaceStatus.loaded:
              return _boardWidget();
            case WorkspaceStatus.failure:
              return Container();
          }
        },
      ),
    );
  }

  Widget _boardWidget() {
    return CrossScroll(
      child: AppFlowyBoard(
          controller: controller,
          cardBuilder: (context, group, groupItem) {
            return AppFlowyGroupCard(
              key: ValueKey(groupItem.id),
              child: _buildCard(groupItem),
            );
          },
          scrollController: scrollController,
          boardScrollController: boardScrollController,
          footerBuilder: (context, columnData) {
            return AppFlowyGroupFooter(
              icon: const Icon(Icons.add, size: 20),
              title: const Text('New'),
              height: 50,
              margin: config.groupItemPadding,
              onAddButtonClick: () {
                boardScrollController.scrollToBottom(columnData.id);
              },
            );
          },
          headerBuilder: (context, columnData) {
            return AppFlowyGroupHeader(
              //icon: const Icon(Icons.lightbulb_circle),
              title: SizedBox(
                width: 160,
                child: TextField(
                  controller: TextEditingController()
                    ..text = columnData.headerData.groupName,
                  onSubmitted: (val) {
                    context
                        .read<WorkspaceBloc>()
                        .add(WorkspaceChangeNameEvent());
                    controller
                        .getGroupController(columnData.headerData.groupId)!
                        .updateGroupName(val);
                  },
                ),
              ),
              addIcon: const Icon(Icons.more_horiz, size: 20),
              height: 50,
              margin: config.groupItemPadding,
            );
          },
          groupConstraints: BoxConstraints.tightFor(
              width: 240, height: MediaQuery.of(context).size.height),
          config: config),
    );
  }

  Widget _buildCard(AppFlowyGroupItem item) {
    if (item is TextItem) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Text(item.s),
        ),
      );
    }

    if (item is RichTextItem) {
      return RichTextCard(item: item);
    }

    throw UnimplementedError();
  }
}

class RichTextCard extends StatefulWidget {
  final RichTextItem item;
  const RichTextCard({
    required this.item,
    Key? key,
  }) : super(key: key);

  @override
  State<RichTextCard> createState() => _RichTextCardState();
}

class _RichTextCardState extends State<RichTextCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item.title,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 10),
            Text(
              widget.item.subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            )
          ],
        ),
      ),
    );
  }
}

class TextItem extends AppFlowyGroupItem {
  final String s;

  TextItem(this.s);

  @override
  String get id => s;
}

class RichTextItem extends AppFlowyGroupItem {
  final String title;
  final String subtitle;

  RichTextItem({required this.title, required this.subtitle});

  @override
  String get id => title;
}

extension HexColor on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
