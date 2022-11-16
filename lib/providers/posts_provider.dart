import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crayon/providers/current_user.dart';
import 'package:crayon/resources/sns_firebase_api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crayon/models/post.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PostsProvider extends ChangeNotifier {
  final _postsSnapshot = <DocumentSnapshot>[];
  String _errorMessage = '';
  int documentLimit = 10;
  bool _hasNext = true;
  bool _isFetchingPosts = false;
  late DocumentSnapshot _lastDocument;

  String _uid = FirebaseAuth.instance.currentUser!.uid;

  String get errorMessage => _errorMessage;

  bool get hasNext => _hasNext;

  List<Post> _posts = [];

  List<Post> get posts => _posts;

  Future addToPostList(List addtionalPosts) async {
    print(_posts.length);
    addtionalPosts.forEach((snap) async {
      Map<String, dynamic> postmap = snap.data() as Map<String, dynamic>;

      Post post = Post.fromjson(postmap);
      post.docId = snap.id;

      if (postmap['like'].contains(_uid))
        post.reaction = 1;
      else if (postmap['amazed'].contains(_uid))
        post.reaction = 2;
      else if (postmap['laugh'].contains(_uid))
        post.reaction = 3;
      else if (postmap['sad'].contains(_uid))
        post.reaction = 4;
      else if (postmap['angry'].contains(_uid))
        post.reaction = 5;
      else
        post.reaction = 0;

      _posts.add(post);
    });

    print("포스트개수: ${_posts.length}");

    _lastDocument = _postsSnapshot.last;
    print(_lastDocument.id);
    _posts.sort((b, a) => a.date.compareTo(b.date));

    _postsSnapshot.clear();
    notifyListeners();
  }

  Future initializePosts(List _blocked) async {
    print('initializePost');
    if (_isFetchingPosts) return;

    _errorMessage = '';
    _isFetchingPosts = true;

    _postsSnapshot.clear();
    _posts.clear();
    _hasNext = true;

    try {
      final snap = await SNSFirebaseApi.getPosts(
        documentLimit,
        startAfter: null,
      );
      print("길이: ${snap.docs.length}");

      snap.docs.forEach((_item) {
        Map postItem = _item.data() as Map;

        if (!_blocked.contains(postItem['posterUid'])) {
          _postsSnapshot.add(_item);
        }
      });

      print(_postsSnapshot.length);
      await addToPostList(_postsSnapshot);

      if (snap.docs.length < documentLimit) _hasNext = false;
      print(_hasNext);
      notifyListeners();
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
    }
    print(errorMessage);

    _isFetchingPosts = false;
  }

  Future fetchNextPosts(BuildContext context) async {
    print('fetchNextPost');
    if (_isFetchingPosts) return;
    _errorMessage = '';
    _isFetchingPosts = true;

    try {
      final snap = await SNSFirebaseApi.getPosts(
        documentLimit,
        startAfter: _posts.isNotEmpty ? _lastDocument : null,
      );
      print("길이: ${snap.docs.length}");

      snap.docs.forEach((_item) {
        Map postItem = _item.data() as Map;
        if (!Provider.of<CurrentUser>(context, listen: false)
            .blocked
            .contains(postItem['posterUid'])) {
          _postsSnapshot.add(_item);
        }
      });

      await addToPostList(_postsSnapshot);

      if (snap.docs.length < documentLimit) _hasNext = false;

      notifyListeners();
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
    }

    _isFetchingPosts = false;
  }
}
