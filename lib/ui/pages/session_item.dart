import 'dart:async';

import 'package:droidkaigi2018/models/session.dart';
import 'package:droidkaigi2018/models/speaker.dart';
import 'package:droidkaigi2018/repository/repository_factory.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

class SessionsItem extends StatefulWidget {
  SessionsItem(this._session, this.googleSignIn);

  final Session _session;

  final googleSignIn;

  @override
  _SessionsItemState createState() => new _SessionsItemState();
}

class _SessionsItemState extends State<SessionsItem> {
  bool _favorite = false;

  @override
  void initState() {
    super.initState();
    fetchFavorite(widget.googleSignIn);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle timeStyle = theme.textTheme.caption;
    final TextStyle titleStyle = theme.textTheme.title;
    final TextStyle descriptionStyle = theme.textTheme.caption;
    final TextStyle speakerNameStyle = theme.textTheme.body2;

    final Session _session = widget._session;

    final formatter =
        new DateFormat.Hm(Localizations.localeOf(context).languageCode);
    final startAt = formatter.format(_session.startsAt);
    final endAt = formatter.format(_session.endsAt);

    Future<Null> _toggleFavorite() async {
      await _ensureLoggedIn(widget.googleSignIn);
      await _updateFavorite(widget.googleSignIn, _session, !_favorite);
      setState(() => _favorite = !_favorite);
    }

    return new Card(
      child: new Padding(
        padding: const EdgeInsets.all(16.0),
        child: new Stack(
          children: [
            new Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                new Text(
                  "$startAt - $endAt / ${_session.room.name}",
                  style: timeStyle,
                ),
                new Container(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: new Text(_session.title, style: titleStyle)),
                new DefaultTextStyle(
                  style: descriptionStyle,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                  child: new Padding(
                    child: new Text(_session.description),
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  ),
                ),
                new Text(
                  _session.topic.name,
                  style: descriptionStyle,
                ),
                new Padding(
                  child: new Column(
                    children:
                        _createSpeakerRows(_session.speakers, speakerNameStyle),
                  ),
                  padding: const EdgeInsets.only(top: 8.0),
                )
              ],
            ),
            new Positioned(
              bottom: -8.0,
              right: -8.0,
              child: new IconButton(
                icon: (_favorite
                    ? new Icon(
                        Icons.favorite,
                        color: theme.primaryColor,
                      )
                    : new Icon(
                        Icons.favorite_border,
                        color: Colors.grey[500],
                      )),
                onPressed: _toggleFavorite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Null> fetchFavorite(GoogleSignIn googleSignIn) async {
    await _ensureLoggedIn(googleSignIn);
    GoogleSignInAccount user = googleSignIn.currentUser;

    new RepositoryFactory()
        .getFavoriteRepository()
        .findAll(user.id)
        .then((Map<String, bool> result) {
      setState(() {
        _favorite = result.containsKey(widget._session.id);
      });
    });
  }
}

List<Widget> _createSpeakerRows(
    List<Speaker> speakers, TextStyle speakerNameStyle) {
  return speakers.map((speaker) {
    return new Container(
      padding: const EdgeInsets.only(top: 8.0),
      child: new Row(
        children: [
          new SizedBox(
            width: 32.0,
            height: 32.0,
            child: new CircleAvatar(
              backgroundImage: new NetworkImage(speaker.profilePicture),
            ),
          ),
          new Container(
              padding: const EdgeInsets.only(left: 8.0),
              child: new Text(speaker.fullName, style: speakerNameStyle)),
        ],
      ),
    );
  }).toList();
}

Future<Null> _ensureLoggedIn(GoogleSignIn googleSignIn) async {
  GoogleSignInAccount user = googleSignIn.currentUser;
  if (user == null) {
    user = await googleSignIn.signInSilently();
  }
  if (user == null) {
    await googleSignIn.signIn();
  }
}

Future<Null> _updateFavorite(
    GoogleSignIn googleSignIn, Session session, bool favorite) async {
  await _ensureLoggedIn(googleSignIn);
  GoogleSignInAccount user = googleSignIn.currentUser;

  await new RepositoryFactory()
      .getFavoriteRepository()
      .update(user.id, session.id, favorite);
}