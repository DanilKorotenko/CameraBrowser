//
//  ICDevice+CameraBrowser.h
//  CameraBrowser
//
//  Created by Danil Korotenko on 5/13/24.
//

#import <Foundation/Foundation.h>
#import <ImageCaptureCore/ImageCaptureCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface ICDevice(CameraBrowserExtension)

@property(readonly) BOOL canSyncClock;
@property(readonly) BOOL canTakePicture;
@property(readonly) BOOL canDeleteOneFile;
@property(readonly) BOOL canDeleteAllFiles;
@property(readonly) BOOL canReceiveFile;
@property(readonly) BOOL canEject;

@end

NS_ASSUME_NONNULL_END
