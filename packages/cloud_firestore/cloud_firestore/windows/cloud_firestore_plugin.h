/*
 * Copyright 2023, the Chromium project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */

#ifndef FLUTTER_PLUGIN_CLOUD_FIRESTORE_PLUGIN_H_
#define FLUTTER_PLUGIN_CLOUD_FIRESTORE_PLUGIN_H_

#include <flutter/event_channel.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

#include "firebase/app.h"
#include "firebase/firestore.h"
#include "firebase/log.h"
#include "firebase_core/firebase_core_plugin_c_api.h"
#include "messages.g.h"

namespace cloud_firestore_windows {

class CloudFirestorePlugin : public flutter::Plugin,
                             public FirebaseFirestoreHostApi {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);
  static firebase::firestore::FieldValue ConvertToFieldValue(
      const flutter::EncodableValue& variant);

  CloudFirestorePlugin();

  virtual ~CloudFirestorePlugin();

  static std::string GetErrorCode(firebase::firestore::Error authError);

  static FlutterError ParseError(const firebase::FutureBase& completed_future);

  // Disallow copy and assign.
  CloudFirestorePlugin(const CloudFirestorePlugin&) = delete;
  CloudFirestorePlugin& operator=(const CloudFirestorePlugin&) = delete;

  // FirebaseFirestoreHostApi methods.

  // Inherited via FirebaseFirestoreHostApi
  virtual void LoadBundle(
      const PigeonFirebaseApp& app, const std::vector<uint8_t>& bundle,
      std::function<void(ErrorOr<std::string> reply)> result) override;
  virtual void NamedQueryGet(
      const PigeonFirebaseApp& app, const std::string& name,
      const PigeonGetOptions& options,
      std::function<void(ErrorOr<PigeonQuerySnapshot> reply)> result) override;
  virtual void ClearPersistence(
      const PigeonFirebaseApp& app,
      std::function<void(std::optional<FlutterError> reply)> result) override;
  virtual void DisableNetwork(
      const PigeonFirebaseApp& app,
      std::function<void(std::optional<FlutterError> reply)> result) override;
  virtual void EnableNetwork(
      const PigeonFirebaseApp& app,
      std::function<void(std::optional<FlutterError> reply)> result) override;
  virtual void Terminate(
      const PigeonFirebaseApp& app,
      std::function<void(std::optional<FlutterError> reply)> result) override;
  virtual void WaitForPendingWrites(
      const PigeonFirebaseApp& app,
      std::function<void(std::optional<FlutterError> reply)> result) override;
  virtual void SetIndexConfiguration(
      const PigeonFirebaseApp& app, const std::string& index_configuration,
      std::function<void(std::optional<FlutterError> reply)> result) override;
  virtual void SetLoggingEnabled(
      bool logging_enabled,
      std::function<void(std::optional<FlutterError> reply)> result) override;
  virtual void SnapshotsInSyncSetup(
      const PigeonFirebaseApp& app,
      std::function<void(ErrorOr<std::string> reply)> result) override;
  virtual void TransactionCreate(
      const PigeonFirebaseApp& app, int64_t timeout, int64_t max_attempts,
      std::function<void(ErrorOr<std::string> reply)> result) override;
  virtual void TransactionStoreResult(
      const std::string& transaction_id,
      const PigeonTransactionResult& result_type,
      const flutter::EncodableList* commands,
      std::function<void(std::optional<FlutterError> reply)> result) override;
  virtual void TransactionGet(
      const PigeonFirebaseApp& app, const std::string& transaction_id,
      const std::string& path,
      std::function<void(ErrorOr<PigeonDocumentSnapshot> reply)> result)
      override;
  virtual void DocumentReferenceSet(
      const PigeonFirebaseApp& app, const DocumentReferenceRequest& request,
      std::function<void(std::optional<FlutterError> reply)> result) override;
  virtual void DocumentReferenceUpdate(
      const PigeonFirebaseApp& app, const DocumentReferenceRequest& request,
      std::function<void(std::optional<FlutterError> reply)> result) override;
  virtual void DocumentReferenceGet(
      const PigeonFirebaseApp& app, const DocumentReferenceRequest& request,
      std::function<void(ErrorOr<PigeonDocumentSnapshot> reply)> result)
      override;
  virtual void DocumentReferenceDelete(
      const PigeonFirebaseApp& app, const DocumentReferenceRequest& request,
      std::function<void(std::optional<FlutterError> reply)> result) override;
  virtual void QueryGet(
      const PigeonFirebaseApp& app, const std::string& path,
      bool is_collection_group, const PigeonQueryParameters& parameters,
      const PigeonGetOptions& options,
      std::function<void(ErrorOr<PigeonQuerySnapshot> reply)> result) override;
  virtual void AggregateQueryCount(
      const PigeonFirebaseApp& app, const std::string& path,
      const PigeonQueryParameters& parameters, const AggregateSource& source,
      std::function<void(ErrorOr<double> reply)> result) override;
  virtual void WriteBatchCommit(
      const PigeonFirebaseApp& app, const flutter::EncodableList& writes,
      std::function<void(std::optional<FlutterError> reply)> result) override;
  virtual void QuerySnapshot(
      const PigeonFirebaseApp& app, const std::string& path,
      bool is_collection_group, const PigeonQueryParameters& parameters,
      const PigeonGetOptions& options, bool include_metadata_changes,
      std::function<void(ErrorOr<std::string> reply)> result) override;
  virtual void DocumentReferenceSnapshot(
      const PigeonFirebaseApp& app, const DocumentReferenceRequest& parameters,
      bool include_metadata_changes,
      std::function<void(ErrorOr<std::string> reply)> result) override;

  static flutter::BinaryMessenger* messenger_;
  static std::map<
      std::string,
      std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>>>
      event_channels_;
  static std::map<std::string, std::unique_ptr<flutter::StreamHandler<>>>
      stream_handlers_;
  static std::map<std::string, std::unique_ptr<flutter::StreamHandler<>>>
      transaction_handlers_;
  static std::map<std::string,
                  std::shared_ptr<firebase::firestore::Transaction>>
      transactions_;
  static std::map<std::string, firebase::firestore::Firestore*>
      firestoreInstances_;

 private:
};

firebase::firestore::MapFieldValue ConvertToMapFieldValue(
    const flutter::EncodableMap& originalMap);

std::vector<firebase::firestore::FieldPath> ConvertToFieldPathVector(
    const flutter::EncodableList& encodableList);

}  // namespace cloud_firestore_windows

#endif  // FLUTTER_PLUGIN_CLOUD_FIRESTORE_PLUGIN_H_
