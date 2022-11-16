import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crayon/constants/strings.dart';
import 'package:crayon/models/post.dart';
import 'package:crayon/models/comment.dart';
import 'package:crayon/views/02_sns/01_post_item_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SNSFirebaseApi {
  static Future uploadPost(Post post) async {
    await FirebaseFirestore.instance.collection('posts').add(post.toJson());
  }

  static Future<bool> deletePost(String docId) async {
    late bool success;
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(docId)
        .delete()
        .then((_) {
      success = true;
    }).catchError((error) {
      success = false;
    });
    return success;
  }

  static Future uploadComment(String postDocId, Comment comment) async {
    DocumentReference docRef =
        FirebaseFirestore.instance.collection("posts").doc(postDocId);
    docRef.update({
      "comments": FieldValue.arrayUnion([comment.toJson()])
    });
  }

  static Future deleteComment(String postDocId, Comment comment) async {
    DocumentReference docRef =
        FirebaseFirestore.instance.collection("posts").doc(postDocId);
    docRef.update({
      "comments": FieldValue.arrayRemove([comment.toJson()])
    });
  }

  static Future deleteCommentJSON(
      String postDocId, Map<String, dynamic> commentInJSON) async {
    DocumentReference docRef =
        FirebaseFirestore.instance.collection("posts").doc(postDocId);
    docRef.update({
      "comments": FieldValue.arrayRemove([commentInJSON])
    });
  }

  static Future<List<EmotionUser>> _getEmotionUserInfo(
      List<dynamic> emotionList,
      int emotionIndex,
      List<EmotionUser> resultList) async {
    print('here');
    for (var uid in emotionList) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .then((DocumentSnapshot documentSnapshot) {
        if (documentSnapshot.exists) {
          Map<String, dynamic> data =
              documentSnapshot.data()! as Map<String, dynamic>;
          resultList.add(EmotionUser(data['name'].toString(), uid,
              data['img'].toString(), emotionIndex));
        }
      });
    }
    return resultList;
  }

  static Future getEmotionUserInfos(List<dynamic> like, List<dynamic> amazed,
      List<dynamic> laugh, List<dynamic> sad, List<dynamic> angry) async {
    List<EmotionUser> allEmotionList = [];

    await _getEmotionUserInfo(like, 1, allEmotionList).then((value) async {
      await _getEmotionUserInfo(amazed, 2, value).then((value) async {
        await _getEmotionUserInfo(laugh, 3, value).then((value) async {
          await _getEmotionUserInfo(sad, 4, value).then((value) async {
            return await _getEmotionUserInfo(angry, 5, value);
          });
        });
      });
    });

    return allEmotionList;
  }

  static Future updateEmotion(
      String docId, int curReaction, int newReaction) async {
    print('firebase update emotion');
    print(curReaction);
    print(newReaction);
    DocumentReference docRef =
        FirebaseFirestore.instance.collection("posts").doc(docId);
    String _uid = FirebaseAuth.instance.currentUser!.uid;

    switch (curReaction) {
      case 1:
        {
          docRef.update({
            "like": FieldValue.arrayRemove([_uid])
          });
          break;
        }
      case 2:
        {
          docRef.update({
            "amazed": FieldValue.arrayRemove([_uid])
          });
          break;
        }
      case 3:
        {
          docRef.update({
            "laugh": FieldValue.arrayRemove([_uid])
          });
          break;
        }
      case 4:
        {
          docRef.update({
            "sad": FieldValue.arrayRemove([_uid])
          });
          break;
        }
      case 5:
        {
          docRef.update({
            "angry": FieldValue.arrayRemove([_uid])
          });
          break;
        }
    }

    switch (newReaction) {
      case 1:
        {
          docRef.update({
            "like": FieldValue.arrayUnion([_uid])
          });
          break;
        }
      case 2:
        {
          docRef.update({
            "amazed": FieldValue.arrayUnion([_uid])
          });
          break;
        }
      case 3:
        {
          docRef.update({
            "laugh": FieldValue.arrayUnion([_uid])
          });
          break;
        }
      case 4:
        {
          docRef.update({
            "sad": FieldValue.arrayUnion([_uid])
          });
          break;
        }
      case 5:
        {
          docRef.update({
            "angry": FieldValue.arrayUnion([_uid])
          });
          break;
        }
    }
  }

  static Future<QuerySnapshot> getPosts(
    int limit, {
    DocumentSnapshot? startAfter,
  }) async {
    final refUsers = FirebaseFirestore.instance
        .collection('posts')
        .where('showType', isNotEqualTo: SNS_OPEN_TO_CHILDREN)
        .orderBy('showType', descending: true)
        .orderBy('date', descending: true)
        .limit(limit);

    if (startAfter == null) {
      return await refUsers.get();
    } else {
      return refUsers.startAfterDocument(startAfter).get();
    }
  }
}
