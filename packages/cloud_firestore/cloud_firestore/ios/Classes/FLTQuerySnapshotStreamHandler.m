// Copyright 2021 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Firebase/Firebase.h>
#import <firebase_core/FLTFirebasePluginRegistry.h>

#import "Private/FLTFirebaseFirestoreUtils.h"
#import "Private/FLTQuerySnapshotStreamHandler.h"
#import "Private/PigeonParser.h"
#import "Public/CustomPigeonHeaderFirestore.h"

@interface FLTQuerySnapshotStreamHandler ()
@property(readwrite, strong) id<FIRListenerRegistration> listenerRegistration;
@end

@implementation FLTQuerySnapshotStreamHandler

- (instancetype)initWithFirestore:(FIRFirestore *)firestore
                            query:(FIRQuery *)query
           includeMetadataChanges:(BOOL)includeMetadataChanges
          serverTimestampBehavior:(FIRServerTimestampBehavior)serverTimestampBehavior {
  self = [super init];
  if (self) {
    _firestore = firestore;
    _query = query;
    _includeMetadataChanges = includeMetadataChanges;
    _serverTimestampBehavior = serverTimestampBehavior;
  }
  return self;
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(nonnull FlutterEventSink)events {
  FIRQuery *query = self.query;

  if (query == nil) {
    return [FlutterError
        errorWithCode:@"sdk-error"
              message:@"An error occurred while parsing query arguments, see native logs for more "
                      @"information. Please report this issue."
              details:nil];
  }

  id listener = ^(FIRQuerySnapshot *_Nullable snapshot, NSError *_Nullable error) {
    if (error) {
      NSArray *codeAndMessage = [FLTFirebaseFirestoreUtils ErrorCodeAndMessageFromNSError:error];
      NSString *code = codeAndMessage[0];
      NSString *message = codeAndMessage[1];
      NSDictionary *details = @{
        @"code" : code,
        @"message" : message,
      };
      dispatch_async(dispatch_get_main_queue(), ^{
        events([FLTFirebasePlugin createFlutterErrorFromCode:code
                                                     message:message
                                             optionalDetails:details
                                          andOptionalNSError:error]);
      });
    } else {
      dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray *toListResult = [[NSMutableArray alloc] initWithCapacity:3];

        NSMutableArray *documents =
            [[NSMutableArray alloc] initWithCapacity:snapshot.documents.count];
        NSMutableArray *documentChanges =
            [[NSMutableArray alloc] initWithCapacity:snapshot.documentChanges.count];

        for (FIRDocumentSnapshot *documentSnapshot in snapshot.documents) {
          [documents addObject:[[PigeonParser toPigeonDocumentSnapshot:documentSnapshot
                                               serverTimestampBehavior:self.serverTimestampBehavior]
                                   toList]];
        }

        for (FIRDocumentChange *documentChange in snapshot.documentChanges) {
          [documentChanges
              addObject:[[PigeonParser toPigeonDocumentChange:documentChange
                                      serverTimestampBehavior:self.serverTimestampBehavior]
                            toList]];
        }

        [toListResult addObject:documents];
        [toListResult addObject:documentChanges];
        [toListResult addObject:[[PigeonParser toPigeonSnapshotMetadata:snapshot.metadata] toList]];

        events(toListResult);
      });
    }
  };

  self.listenerRegistration =
      [query addSnapshotListenerWithIncludeMetadataChanges:_includeMetadataChanges
                                                  listener:listener];

  return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
  [self.listenerRegistration remove];
  self.listenerRegistration = nil;

  return nil;
}

@end
