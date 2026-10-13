import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/book.dart';
import '../screens/user_session.dart';
import 'user_data_service.dart';

class ReviewService {
  static final instance = ReviewService();
  DatabaseReference get root => UserDataService.instance.root;
  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified || user.uid != UserSession.uid)
      throw StateError('Please sign in.');
    return user.uid;
  }

  Stream<List<Review>> watch(String bookId, String viewer) =>
      Stream<List<Review>>.multi((controller) {
        DataSnapshot? entries, likes;
        void emit() {
          if (entries == null || likes == null) return;
          final result = entries!.children.map((entry) {
            final data = Map<String, dynamic>.from(entry.value as Map);
            final votes = likes!.child(entry.key!);
            return Review(
              id: entry.key!,
              userId: data['userId'] as String,
              user: data['user'] as String,
              rating: (data['rating'] as num).toDouble(),
              comment: data['comment'] as String,
              date: DateTime.tryParse(data['updatedAt'] as String? ?? ''),
              likes: votes.children.where((vote) => vote.value == true).length,
              likedByMe: votes.child(viewer).value == true,
            );
          }).toList()..sort((a, b) => b.date.compareTo(a.date));
          controller.add(result);
        }

        final a = root.child('bookReviews/$bookId').onValue.listen((event) {
          entries = event.snapshot;
          emit();
        }, onError: controller.addError);
        final b = root.child('reviewLikes/$bookId').onValue.listen((event) {
          likes = event.snapshot;
          emit();
        }, onError: controller.addError);
        controller.onCancel = () async {
          await a.cancel();
          await b.cancel();
        };
      });
  Future<void> save(String bookId, double rating, String comment) {
    final uid = _uid;
    if (rating < 1 ||
        rating > 5 ||
        rating % 1 != 0 ||
        comment.trim().isEmpty ||
        comment.trim().length > 2000)
      throw ArgumentError('Choose 1–5 stars and write up to 2000 characters.');
    return root.child('bookReviews/$bookId/$uid').set({
      'userId': uid,
      'user': UserSession.name,
      'rating': rating,
      'comment': comment.trim(),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> setLiked(String bookId, String reviewId, bool liked) => root
      .child('reviewLikes/$bookId/$reviewId/$_uid')
      .set(liked ? true : null);
}
