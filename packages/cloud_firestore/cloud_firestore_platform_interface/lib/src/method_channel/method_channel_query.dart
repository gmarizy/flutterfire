// ignore_for_file: require_trailing_commas, unnecessary_lambdas
// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_flutterfire_internals/_flutterfire_internals.dart';
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_platform_interface/src/internal/pointer.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';

import 'method_channel_aggregate_query.dart';
import 'method_channel_firestore.dart';
import 'method_channel_query_snapshot.dart';
import 'utils/exception.dart';

/// An implementation of [QueryPlatform] that uses [MethodChannel] to
/// communicate with Firebase plugins.
class MethodChannelQuery extends QueryPlatform {
  /// Create a [MethodChannelQuery] from a [path] and optional [parameters]
  MethodChannelQuery(
    FirebaseFirestorePlatform _firestore,
    String path,
    this.pigeonApp, {
    Map<String, dynamic>? parameters,
    this.isCollectionGroupQuery = false,
  })  : _pointer = Pointer(path),
        super(_firestore, parameters);

  /// Flags whether the current query is for a collection group.
  @override
  final bool isCollectionGroupQuery;

  final Pointer _pointer;
  final PigeonFirebaseApp pigeonApp;

  /// Returns the Document path that that this query relates to.
  String get path {
    return _pointer.path;
  }

  PigeonQueryParameters get _pigeonParameters {
    return PigeonQueryParameters(
      where: parameters['where'],
      orderBy: parameters['orderBy'],
      limit: parameters['limit'],
      limitToLast: parameters['limitToLast'],
      startAt: parameters['startAt'],
      startAfter: parameters['startAfter'],
      endAt: parameters['endAt'],
      endBefore: parameters['endBefore'],
      filters: parameters['filters'],
    );
  }

  /// Creates a new instance of [MethodChannelQuery], however overrides
  /// any existing [parameters].
  ///
  /// This is in place to ensure that changes to a query don't mutate
  /// other queries.
  MethodChannelQuery _copyWithParameters(Map<String, dynamic> parameters) {
    return MethodChannelQuery(
      firestore,
      _pointer.path,
      pigeonApp,
      isCollectionGroupQuery: isCollectionGroupQuery,
      parameters: Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.from(this.parameters)..addAll(parameters),
      ),
    );
  }

  @override
  QueryPlatform endAtDocument(List<dynamic> orders, List<dynamic> values) {
    return _copyWithParameters(<String, dynamic>{
      'orderBy': orders,
      'endAt': values,
      'endBefore': null,
    });
  }

  @override
  QueryPlatform endAt(Iterable<dynamic> fields) {
    return _copyWithParameters(<String, dynamic>{
      'endAt': fields,
      'endBefore': null,
    });
  }

  @override
  QueryPlatform endBeforeDocument(
      Iterable<dynamic> orders, Iterable<dynamic> values) {
    return _copyWithParameters(<String, dynamic>{
      'orderBy': orders,
      'endAt': null,
      'endBefore': values,
    });
  }

  @override
  QueryPlatform endBefore(Iterable<dynamic> fields) {
    return _copyWithParameters(<String, dynamic>{
      'endAt': null,
      'endBefore': fields,
    });
  }

  /// Fetch the documents for this query
  @override
  Future<QuerySnapshotPlatform> get(
      [GetOptions options = const GetOptions()]) async {
    try {
      final PigeonQuerySnapshot result =
          await MethodChannelFirebaseFirestore.pigeonChannel.queryGet(
        pigeonApp,
        _pointer.path,
        isCollectionGroupQuery,
        _pigeonParameters,
        PigeonGetOptions(
          source: options.source,
          serverTimestampBehavior: options.serverTimestampBehavior,
        ),
      );

      return MethodChannelQuerySnapshot(firestore, result);
    } catch (e, stack) {
      convertPlatformException(e, stack);
    }
  }

  @override
  QueryPlatform limit(int limit) {
    return _copyWithParameters(<String, dynamic>{
      'limit': limit,
      'limitToLast': null,
    });
  }

  @override
  QueryPlatform limitToLast(int limit) {
    return _copyWithParameters(<String, dynamic>{
      'limit': null,
      'limitToLast': limit,
    });
  }

  @override
  Stream<QuerySnapshotPlatform> snapshots({
    bool includeMetadataChanges = false,
    ServerTimestampBehavior serverTimestampBehavior =
        ServerTimestampBehavior.none,
  }) {
    // It's fine to let the StreamController be garbage collected once all the
    // subscribers have cancelled; this analyzer warning is safe to ignore.
    late StreamController<QuerySnapshotPlatform>
        controller; // ignore: close_sinks

    StreamSubscription<dynamic>? snapshotStreamSubscription;

    controller = StreamController<QuerySnapshotPlatform>.broadcast(
      onListen: () async {
        final observerId =
            await MethodChannelFirebaseFirestore.pigeonChannel.querySnapshot(
          pigeonApp,
          _pointer.path,
          isCollectionGroupQuery,
          _pigeonParameters,
          PigeonGetOptions(
            source: Source.serverAndCache,
            serverTimestampBehavior: serverTimestampBehavior,
          ),
          includeMetadataChanges,
        );

        snapshotStreamSubscription =
            MethodChannelFirebaseFirestore.querySnapshotChannel(observerId)
                .receiveGuardedBroadcastStream(
          onError: convertPlatformException,
        )
                .listen(
          (snapshot) {
            final snapshotList = snapshot as List<Object?>;
            // We force the types here of list because they are not automatically
            // decoded by the pigeon generated code.
            final List<PigeonDocumentSnapshot> documents =
                (snapshotList[0]! as List)
                    .map((e) => PigeonDocumentSnapshot.decode(e))
                    .toList()
                    .cast<PigeonDocumentSnapshot>();
            final List<PigeonDocumentChange> changes =
                (snapshotList[1]! as List)
                    .map((e) => PigeonDocumentChange.decode(e))
                    .toList()
                    .cast<PigeonDocumentChange>();
            final PigeonQuerySnapshot result = PigeonQuerySnapshot.decode(
                [documents, changes, snapshotList[2]]);
            controller.add(MethodChannelQuerySnapshot(firestore, result));
          },
          onError: controller.addError,
        );
      },
      onCancel: () {
        snapshotStreamSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  QueryPlatform orderBy(Iterable<List<dynamic>> orders) {
    return _copyWithParameters(<String, dynamic>{
      'orderBy': orders,
    });
  }

  @override
  QueryPlatform startAfterDocument(List<dynamic> orders, List<dynamic> values) {
    return _copyWithParameters(<String, dynamic>{
      'orderBy': orders,
      'startAt': null,
      'startAfter': values,
    });
  }

  @override
  QueryPlatform startAfter(Iterable<dynamic> fields) {
    return _copyWithParameters(<String, dynamic>{
      'startAt': null,
      'startAfter': fields,
    });
  }

  @override
  QueryPlatform startAtDocument(
      Iterable<dynamic> orders, Iterable<dynamic> values) {
    return _copyWithParameters(<String, dynamic>{
      'orderBy': orders,
      'startAt': values,
      'startAfter': null,
    });
  }

  @override
  QueryPlatform startAt(Iterable<dynamic> fields) {
    return _copyWithParameters(<String, dynamic>{
      'startAt': fields,
      'startAfter': null,
    });
  }

  @override
  QueryPlatform where(Iterable<List<dynamic>> conditions) {
    return _copyWithParameters(<String, dynamic>{
      'where': conditions,
    });
  }

  @override
  QueryPlatform whereFilter(FilterPlatformInterface filter) {
    return _copyWithParameters(<String, dynamic>{
      'filters': filter.toJson(),
    });
  }

  @override
  AggregateQueryPlatform count() {
    return MethodChannelAggregateQuery(
      this,
      _pigeonParameters,
      _pointer.path,
      pigeonApp,
    );
  }

  @override
  bool operator ==(Object other) {
    return runtimeType == other.runtimeType &&
        other is MethodChannelQuery &&
        other.firestore == firestore &&
        other._pointer == _pointer &&
        other.isCollectionGroupQuery == isCollectionGroupQuery &&
        const DeepCollectionEquality().equals(other.parameters, parameters);
  }

  @override
  int get hashCode => Object.hash(
        runtimeType,
        firestore,
        _pointer,
        isCollectionGroupQuery,
        const DeepCollectionEquality().hash(parameters),
      );
}
