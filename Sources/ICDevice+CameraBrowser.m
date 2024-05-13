//
//  ICDevice+CameraBrowser.m
//  CameraBrowser
//
//  Created by Danil Korotenko on 5/13/24.
//

#import "ICDevice+CameraBrowser.h"

@implementation ICDevice(CameraBrowserExtension)

- (BOOL)canTakePicture
{
    if ( [self.capabilities containsObject:ICCameraDeviceCanTakePicture] )
    {
        return YES;
    }
    return NO;
}

- (BOOL)canDeleteOneFile
{
    if ( [self.capabilities containsObject:ICCameraDeviceCanDeleteOneFile] )
    {
        return YES;
    }
    return NO;
}

- (BOOL)canDeleteAllFiles
{
    if ( [self.capabilities containsObject:ICCameraDeviceCanDeleteAllFiles] )
    {
        return YES;
    }
    return NO;
}

- (BOOL)canSyncClock
{
    if ( [self.capabilities containsObject:ICCameraDeviceCanSyncClock] )
    {
        return YES;
    }
    return NO;
}

- (BOOL)canReceiveFile
{
    if ( [self.capabilities containsObject:ICCameraDeviceCanReceiveFile] )
    {
        return YES;
    }
    return NO;
}

- (BOOL)canEject
{
    if ( [self.capabilities containsObject:ICDeviceCanEjectOrDisconnect] )
    {
        return YES;
    }
    return NO;
}

@end
