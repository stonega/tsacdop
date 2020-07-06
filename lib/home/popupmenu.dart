import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tsacdop/local_storage/key_value_storage.dart';
import 'package:xml/xml.dart' as xml;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:line_icons/line_icons.dart';
import 'package:intl/intl.dart';

import '../settings/settting.dart';
import '../state/refresh_podcast.dart';
import '../state/subscribe_podcast.dart';
import '../util/context_extension.dart';
import 'about.dart';

class OmplOutline {
  final String text;
  final String xmlUrl;
  OmplOutline({this.text, this.xmlUrl});

  factory OmplOutline.parse(xml.XmlElement element) {
    if (element == null) return null;
    return OmplOutline(
      text: element.getAttribute("text")?.trim(),
      xmlUrl: element.getAttribute("xmlUrl")?.trim(),
    );
  }
}

class PopupMenu extends StatefulWidget {
  @override
  _PopupMenuState createState() => _PopupMenuState();
}

class _PopupMenuState extends State<PopupMenu> {
  Future<String> _getRefreshDate(BuildContext context) async {
    int refreshDate;
    final s = context.s;
    KeyValueStorage refreshstorage = KeyValueStorage('refreshdate');
    int i = await refreshstorage.getInt();
    if (i == 0) {
      KeyValueStorage refreshstorage = KeyValueStorage('refreshdate');
      await refreshstorage.saveInt(DateTime.now().millisecondsSinceEpoch);
      refreshDate = DateTime.now().millisecondsSinceEpoch;
    } else {
      refreshDate = i;
    }
    DateTime date = DateTime.fromMillisecondsSinceEpoch(refreshDate);
    var difference = DateTime.now().difference(date);
    if (difference.inSeconds < 60) {
      return s.secondsAgo(difference.inSeconds);
    } else if (difference.inMinutes < 60) {
      return s.minsAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return s.hoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return s.daysAgo(difference.inDays);
    } else {
      return DateFormat.yMMMd()
          .format(DateTime.fromMillisecondsSinceEpoch(refreshDate));
    }
  }

  @override
  Widget build(BuildContext context) {
    var refreshWorker = Provider.of<RefreshWorker>(context, listen: false);
    var subscribeWorker = Provider.of<SubscribeWorker>(context, listen: false);
    final s = context.s;
    void _saveOmpl(String path) async {
      File file = File(path);
      try {
        String opml = file.readAsStringSync();

        var content = xml.XmlDocument.parse(opml);
        var total = content
            .findAllElements('outline')
            .map((ele) => OmplOutline.parse(ele))
            .toList();
        if (total.length == 0) {
          Fluttertoast.showToast(
            msg: s.toastFileNotValid,
            gravity: ToastGravity.BOTTOM,
          );
        } else {
          for (int i = 0; i < total.length; i++) {
            if (total[i].xmlUrl != null) {
              //  importOmpl.rssTitle = total[i].text;
              //await saveOmpl(total[i].xmlUrl);
              SubscribeItem item =
                  SubscribeItem(total[i].xmlUrl, total[i].text);
              await subscribeWorker.setSubscribeItem(item);
              await Future.delayed(Duration(milliseconds: 500));
              print(total[i].text);
            }
          }
          print('Import fisnished');
        }
      } catch (e) {
        print(e);
        Fluttertoast.showToast(
          msg: s.toastFileError,
          gravity: ToastGravity.TOP,
        );
        //await Future.delayed(Duration(seconds: 5));
        //  importOmpl.importState = ImportState.stop;
      }
    }

    void _getFilePath() async {
      try {
        String filePath = await FilePicker.getFilePath(type: FileType.any);
        if (filePath == '') {
          return;
        }
        print('File Path' + filePath);
        //importOmpl.importState = ImportState.start;
        Fluttertoast.showToast(
          msg: s.toastReadFile,
          gravity: ToastGravity.TOP,
        );
        _saveOmpl(filePath);
      } on PlatformException catch (e) {
        print(e.toString());
      }
    }

    return PopupMenuButton<int>(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10))),
      elevation: 1,
      tooltip: s.menu,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 1,
          child: Container(
            padding: EdgeInsets.only(left: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(LineIcons.cloud_download_alt_solid),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.0),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      s.homeToprightMenuRefreshAll,
                    ),
                    FutureBuilder<String>(
                        future: _getRefreshDate(context),
                        builder: (_, snapshot) {
                          if (snapshot.hasData)
                            return Text(
                              snapshot.data,
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            );
                          else
                            return Center();
                        })
                  ],
                ),
              ],
            ),
          ),
        ),
        PopupMenuItem(
          value: 2,
          child: Container(
            padding: EdgeInsets.only(left: 10),
            child: Row(
              children: <Widget>[
                Icon(LineIcons.paperclip_solid),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.0),
                ),
                Text(s.homeToprightMenuImportOMPL),
              ],
            ),
          ),
        ),
        PopupMenuItem(
          value: 4,
          child: Container(
            padding: EdgeInsets.only(left: 10),
            child: Row(
              children: <Widget>[
                Icon(LineIcons.cog_solid),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.0),
                ),
                Text(s.homeToprightMenuSettings),
              ],
            ),
          ),
        ),
        PopupMenuItem(
          value: 5,
          child: Container(
            padding: EdgeInsets.only(left: 10),
            child: Row(
              children: <Widget>[
                Icon(LineIcons.info_circle_solid),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.0),
                ),
                Text(s.homeToprightMenuAbout),
              ],
            ),
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 5) {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => AboutApp()));
        } else if (value == 2) {
          _getFilePath();
        } else if (value == 1) {
          //_refreshAll();
          refreshWorker.start();
        } else if (value == 3) {
          //  setting.theme != 2 ? setting.setTheme(2) : setting.setTheme(1);
        } else if (value == 4) {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => Settings()));
        }
      },
    );
  }
}
