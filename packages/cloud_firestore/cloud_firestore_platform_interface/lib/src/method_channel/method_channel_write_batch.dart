// ignore_for_file: require_trailing_commas
// Copyright 2018, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';

import 'method_channel_firestore.dart';
import 'utils/exception.dart';

/// An implementation of [WriteBatchPlatform] that uses [MethodChannel] to
/// communicate with Firebase plugins.
///
/// Operations done on a [MethodChannelWriteBatch] do not take effect until you [commit].
///
/// Once committed, no further operations can be performed on the [MethodChannelWriteBatch],
/// nor can it be committed again.
class MethodChannelWriteBatch extends WriteBatchPlatform {
  /// Create an instance of [MethodChannelWriteBatch]
  MethodChannelWriteBatch(this.pigeonApp) : super();

  final PigeonFirebaseApp pigeonApp;

  /// Keeps track of all batch writes in order.
  List<PigeonTransactionCommand> _writes = [];

  /// The committed state of this batch.
  ///
  /// Once a batch has been committed, a [StateError] will
  /// be thrown if the batch is modified after.
  bool _committed = false;

  @override
  Future<void> commit() async {
    _assertNotCommitted();
    _committed = true;

    if (_writes.isEmpty) {
      return;
    }

    try {
      await MethodChannelFirebaseFirestore.pigeonChannel
          .writeBatchCommit(pigeonApp, _writes);
    } catch (e, stack) {
      convertPlatformException(e, stack);
    }
  }

  @override
  void delete(String documentPath) {
    _assertNotCommitted();
    _writes.add(PigeonTransactionCommand(
      path: documentPath,
      type: PigeonTransactionType.deleteType,
    ));
  }

  @override
  void set(String documentPath, Map<String, dynamic> data,
      [SetOptions? options]) {
    _assertNotCommitted();
    _writes.add(PigeonTransactionCommand(
      path: documentPath,
      type: PigeonTransactionType.set,
      data: data,
      option: PigeonDocumentOption(
        merge: options?.merge,
        mergeFields: options?.mergeFields?.map((e) => e.components).toList(),
      ),
    ));
  }

  @override
  void update(
    String documentPath,
    Map<String, dynamic> data,
  ) {
    _assertNotCommitted();
    _writes.add(PigeonTransactionCommand(
      path: documentPath,
      type: PigeonTransactionType.update,
      data: data,
    ));
  }

  /// Ensures that once a batch has been committed, it can not be modified again.
  void _assertNotCommitted() {
    if (_committed) {
      throw StateError(
          'This batch has already been committed and can no longer be changed.');
    }
  }
}
