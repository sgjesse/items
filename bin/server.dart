import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appengine/appengine.dart';

import '../web/model.dart';

void notFound(request) {
  request.response.statusCode = HttpStatus.NOT_FOUND;
  request.response.close();
}

Future sendJSONResponse(HttpRequest request, json) {
  request.response
      ..headers.contentType = ContentType.JSON
      ..headers.set("Cache-Control", "no-cache")
      ..add(UTF8.encode(JSON.encode(json)));

  return request.response.close();
}

Future readJSONRequest(HttpRequest request) {
  return request.fold(new BytesBuilder(), (builder, data) => builder..add(data))
      .then((builder) => UTF8.decode(builder.takeBytes()))
      .then((json) {
        return JSON.decode(json);
      });
}

rootKey() {
  var rootKey = context.services.db.emptyKey.append(ItemsRoot, id: 1);
}

Future<List<Item>> readItems() {
  var query = context.services.db.query(
      Item, ancestorKey: rootKey())..order('name');
  return query.run();
}

handleItems(HttpRequest request) {
  if (request.method == 'GET') {
    return readItems().then((List<Item> items) {
      var result = items.map((item) => item.serialize()).toList();
      var json = {'success': true, 'result': result};
      return sendJSONResponse(request, json);
    });
  } else if (request.method == 'POST') {
    return readJSONRequest(request).then((json) {
      var item = Item.deserialize(json)..parentKey = rootKey();
      var error = item.validate();
      if (error != null) {
        json = {'success': false, 'error': error};
        return sendJSONResponse(request, json);
      } else {
        return context.services.db.commit(inserts: [item]).then((_) {
          json = {'success': true};
          return sendJSONResponse(request, json);
        });
      }
    });
  }
}

Future handleClean(HttpRequest request) {
  return readItems().then((items) {
    var deletes = items.map((item) => item.key).toList();
    return context.services.db.commit(deletes: deletes);
  });
}

void requestHandler(HttpRequest request) {
  if (request.uri.path == '/items') {
    handleItems(request);
  } else if (request.uri.path == '/clean') {
    handleClean(request).then((_) {
      request.response.redirect(Uri.parse('/index.html'));
    });
  } else if (request.uri.path == '/') {
    request.response.redirect(Uri.parse('/index.html'));
  } else {
    context.assets.serve(request.response);
  }
}

main() {
  runAppEngine(requestHandler).then((_) {
    // Server running.
  });
}