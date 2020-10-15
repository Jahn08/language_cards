import 'dart:convert';
import 'package:http/http.dart';

class HttpResponder {

    HttpResponder._();

    static Response respondWithJson(Object body) => new Response(
        json.encode(body),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'}
    );
}
