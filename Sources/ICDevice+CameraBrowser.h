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
- (BOOL)canSyncClock;
- (BOOL)canTakePicture;
- (BOOL)canDeleteOneFile;
- (BOOL)canDeleteAllFiles;
- (BOOL)canReceiveFile;
- (BOOL)canEject;
@end

NS_ASSUME_NONNULL_END
