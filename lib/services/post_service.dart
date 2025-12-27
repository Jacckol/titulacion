import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_frontend/models/post.dart';

class PostService {
  Dio dio = Dio();
  final String baseUrl = "http://localhost:4000"; // <-- backend local

  Future<Response?> getAllPost() async {
    try {
      return await dio.get('$baseUrl/getallpost');
    } on DioError catch (err) {
      return err.response;
    }
  }

  Future<Response?> searchPost(String searchKey) async {
    try {
      return await dio.get('$baseUrl/searchpost/$searchKey');
    } on DioError catch (err) {
      return err.response;
    }
  }

  Future<Response?> deletePost(String id) async {
    try {
      return await dio.delete('$baseUrl/deletepost/$id');
    } on DioError catch (err) {
      return err.response;
    }
  }

  Future<Response?> createPost(
      String title, String body, String author, String authorId) async {
    try {
      return await dio.post(
        '$baseUrl/addpost',
        options: Options(headers: {
          HttpHeaders.contentTypeHeader: "application/json",
        }),
        data: jsonEncode({
          'title': title,
          'body': body,
          'author': author,
          'author_id': authorId
        }),
      );
    } on DioError catch (err) {
      return err.response;
    }
  }

  Future<Response?> updatePost(Post post) async {
    try {
      return await dio.put(
        '$baseUrl/updatepost/${post.id}',
        options: Options(headers: {
          HttpHeaders.contentTypeHeader: "application/json",
        }),
        data: jsonEncode({
          'title': post.title,
          'body': post.body,
          'author': post.author,
          'author_id': post.authorId
        }),
      );
    } on DioError catch (err) {
      return err.response;
    }
  }
}
