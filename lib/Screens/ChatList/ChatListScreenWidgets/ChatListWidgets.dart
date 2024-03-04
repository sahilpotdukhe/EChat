import 'package:echat/Provider/UserProvider.dart';
import 'package:echat/Utils/utilities.dart';
import 'package:flutter/material.dart';
import 'package:echat/Utils/UniversalVariables.dart';
import 'package:provider/provider.dart';

class ChatCustomTile extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget icon;
  final Widget subtitle;
  final Widget trailing;
  final EdgeInsets margin;
  final bool mini;
  final Function() onTap;
  final Function() onLongPress;

  const ChatCustomTile(
      {super.key,
      required this.leading,
      required this.title,
      required this.icon,
      required this.subtitle,
      required this.trailing,
      required this.margin,
      required this.mini,
      required this.onTap,
      required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
          padding: EdgeInsets.symmetric(horizontal: mini ? 10 : 10),
          margin: margin,
          child: Row(
            children: [
              leading,
              Expanded(
                  child: Container(
                            margin: EdgeInsets.only(left: mini ? 10 : 15),
                            padding: EdgeInsets.symmetric(vertical: mini ? 3 : 20),
                            decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        width: 1,
                                        color: UniversalVariables.separatorColor))),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      title,
                                      SizedBox(
                                        height: 5,
                                      ),
                                     Row(
                                       children: [
                                         icon,
                                         subtitle
                                       ],
                                     )
                                    ],
                                  ),
                                ),
                                trailing
                              ],
                            ),
              ))
            ],
          )),
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget> actions;
  final Widget leading;
  final bool centerTitle;

  const CustomAppBar(
      {super.key,
      required this.title,
      required this.actions,
      required this.leading,
      required this.centerTitle});

  // these is to set the new height of appbar 10 more than the standard height of the appbar
  @override
  final Size preferredSize = const Size.fromHeight(kToolbarHeight + 10);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: UniversalVariables.blackColor,
          border: Border(
              bottom: BorderSide(
                  color: UniversalVariables.separatorColor,
                  width: 1.4,
                  style: BorderStyle.solid))),
      child: AppBar(
        backgroundColor: UniversalVariables.blueColor,
        elevation: 0,
        leading: leading,
        actions: actions,
        centerTitle: centerTitle,
        title: title,
      ),
    );
  }
}

