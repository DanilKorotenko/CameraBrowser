//------------------------------------------------------------------------------------------------------------------------------
//
// File:       AppController.m
//
// Abstract:   Use the ImageCaptureCore framework to create a simple scanner application.
//
// Version:    1.0
//
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc. ("Apple")
//             in consideration of your agreement to the following terms, and your use,
//             installation, modification or redistribution of this Apple software
//             constitutes acceptance of these terms.  If you do not agree with these
//             terms, please do not use, install, modify or redistribute this Apple
//             software.
//
//             In consideration of your agreement to abide by the following terms, and
//             subject to these terms, Apple grants you a personal, non - exclusive
//             license, under Apple's copyrights in this original Apple software ( the
//             "Apple Software" ), to use, reproduce, modify and redistribute the Apple
//             Software, with or without modifications, in source and / or binary forms;
//             provided that if you redistribute the Apple Software in its entirety and
//             without modifications, you must retain this notice and the following text
//             and disclaimers in all such redistributions of the Apple Software. Neither
//             the name, trademarks, service marks or logos of Apple Inc. may be used to
//             endorse or promote products derived from the Apple Software without specific
//             prior written permission from Apple.  Except as expressly stated in this
//             notice, no other rights or licenses, express or implied, are granted by
//             Apple herein, including but not limited to any patent rights that may be
//             infringed by your derivative works or by other works in which the Apple
//             Software may be incorporated.
//
//             The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
//             WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
//             WARRANTIES OF NON - INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
//             PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
//             ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//             IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
//             CONSEQUENTIAL DAMAGES ( INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//             SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//             INTERRUPTION ) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
//             AND / OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER
//             UNDER THEORY OF CONTRACT, TORT ( INCLUDING NEGLIGENCE ), STRICT LIABILITY OR
//             OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Copyright ( C ) 2009 Apple Inc. All Rights Reserved.
//
//------------------------------------------------------------------------------------------------------------------------------

#import "AppController.h"
#import "CGImageRefToNSImageTransformer.h"

@interface AppController ()

@property(strong) IBOutlet NSWindow             *window;
@property(strong) IBOutlet NSTableView          *camerasTableView;
@property(strong) IBOutlet NSArrayController    *camerasController;
@property(strong) IBOutlet NSTableView          *cameraContentTableView;
@property(strong) IBOutlet NSArrayController    *mediaFilesController;


@property(strong) NSMutableArray *cameras;
@property(strong) ICDeviceBrowser *deviceBrowser;

@property(readonly) BOOL canDelete;
@property(readonly) BOOL canDownload;

@end


@implementation AppController

//------------------------------------------------------------------------------------------------------------------- initialize

+ (void)initialize
{
    CGImageRefToNSImageTransformer *imageTransformer = [[CGImageRefToNSImageTransformer alloc] init];
    [NSValueTransformer setValueTransformer:imageTransformer forName:@"CGImageRefToNSImage"];
}

//------------------------------------------------------------------------------------------------------- processICLaunchParams:

- (void)processICLaunchParams:(NSNotification*)notification
{
    NSLog( @"NSNotification: %@\n", notification );
}

//----------------------------------------------------------------------------------------------- applicationDidFinishLaunching:

- (void)applicationDidFinishLaunching:(NSNotification*)notification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(processICLaunchParams:)
        name:@"ICLaunchParamsNotification"
        object:NULL];

    self.cameras = [[NSMutableArray alloc] initWithCapacity:0];
    [self.camerasController setSelectsInsertedObjects:NO];

    [[self.cameraContentTableView tableColumnWithIdentifier:@"Date"] bind:@"value" toObject:self.mediaFilesController
        withKeyPath:@"arrangedObjects.metadataIfAvailable.{Exif}.DateTimeOriginal" options:nil];
    [[self.cameraContentTableView tableColumnWithIdentifier:@"Make"] bind:@"value" toObject:self.mediaFilesController
        withKeyPath:@"arrangedObjects.metadataIfAvailable.{TIFF}.Make" options:nil];
    [[self.cameraContentTableView tableColumnWithIdentifier:@"Model"] bind:@"value" toObject:self.mediaFilesController
        withKeyPath:@"arrangedObjects.metadataIfAvailable.{TIFF}.Model" options:nil];

    [self.mediaFilesController addObserver:self forKeyPath:@"selectedObjects" options:0 context:NULL];

    [self.camerasTableView setTarget:self];
    [self.camerasTableView setAction:@selector(openCamera)];

    self.deviceBrowser = [[ICDeviceBrowser alloc] init];
    self.deviceBrowser.delegate = self;
    self.deviceBrowser.browsedDeviceTypeMask =
        ICDeviceLocationTypeMaskLocal|ICDeviceLocationTypeMaskRemote|ICDeviceTypeMaskCamera;
    [self.deviceBrowser start];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

//------------------------------------------------------------------------------ observeValueForKeyPath:ofObject:change:context:

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if ( [keyPath isEqualToString:@"selectedObjects"] && (object == self.mediaFilesController) )
    {
        [self willChangeValueForKey:@"canDelete"];
        [self willChangeValueForKey:@"canDownload"];
        [self didChangeValueForKey:@"canDelete"];
        [self didChangeValueForKey:@"canDownload"];
    }
}

//-------------------------------------------------------------------------------------------------------------------- canDelete

- (BOOL)canDelete
{
    BOOL      can           = NO;
    NSArray*  selectedFiles = [self.mediaFilesController selectedObjects];

    if ( [selectedFiles count] )
    {
        for ( ICCameraFile* f in selectedFiles )
        {
            if ( f.locked == NO )
            {
                can = YES;
                break;
            }
        }
    }

    return can;
}

//------------------------------------------------------------------------------------------------------------------ canDownload

- (BOOL)canDownload
{
    if ( [[self.mediaFilesController selectedObjects] count] )
    {
        return YES;
    }
    return NO;
}

//--------------------------------------------------------------------------------------------------------------- selectedCamera

- (ICCameraDevice*)selectedCamera
{
    ICCameraDevice* camera = NULL;

    id selectedObjects = [self.camerasController selectedObjects];

    if ( [selectedObjects count] )
    {
        camera = [selectedObjects objectAtIndex:0];
    }

    return camera;
}

//--------------------------------------------------------------------------------------------------------------- downloadFiles:
// This method request the currently selected camera to download an array of files to ~/Pictures directory.

- (void)downloadFiles:(NSArray*)files
{
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSURL fileURLWithPath:[@"~/Pictures" stringByExpandingTildeInPath]], ICDownloadsDirectoryURL,
        nil];

    for ( ICCameraFile* f in files )
    {
        [f.device requestDownloadFile:f options:options downloadDelegate:self
            didDownloadSelector:@selector(didDownloadFile:error:options:contextInfo:) contextInfo:NULL];
    }
}

// The following method will be invoked when the download request is completed. If the file is downloaded successfully, options will have the actual path to the downloaded file and error will be set to NULL.

- (void)didDownloadFile:(ICCameraFile*)file error:(NSError*)error options:(NSDictionary*)options contextInfo:(void*)contextInfo
{
    NSLog( @"didDownloadFile called with:\n" );
    NSLog( @"  file:        %@\n", file );
    NSLog( @"  error:       %@\n", error );
    NSLog( @"  options:     %@\n", options );
    NSLog( @"  contextInfo: %p\n", contextInfo );
}

//------------------------------------------------------------------------------------------------------------------- readFiles:
// This method requests currently selected camera to read an array of files.
 
- (void)readFiles:(NSArray*)files
{
    for ( ICCameraFile* f in files )
    {
        [f.device requestReadDataFromFile:f atOffset:0 length:f.fileSize readDelegate:self
            didReadDataSelector:@selector(didReadData:fromFile:error:contextInfo:) contextInfo:NULL];
    }
}

// The following method will be invoked when the read request is completed. If the file is read successfully, the file data will be returned in  data and error will be set to NULL.

- (void)didReadData:(NSData*)data fromFile:(ICCameraFile*)file error:(NSError*)error contextInfo:(void*)contextInfo
{
    NSLog( @"didReadData called with:\n" );
    NSLog( @"  data:        %p\n", data );
    NSLog( @"  file:        %@\n", file );
    NSLog( @"  error:       %@\n", error );
    NSLog( @"  contextInfo: %p\n", contextInfo );

    if ( data )
    {
        [data writeToFile:file.name atomically:NO];
    }
}

//------------------------------------------------------------------------------------------------------------------- uploadFile

- (void)uploadFile
{
    NSURL* file = [NSURL fileURLWithPath:@"IMG_0048.JPG" isDirectory:NO]; // Update this line of code with the URL to the file to be uploaded

    [[self selectedCamera] requestUploadFile:file options:NULL uploadDelegate:self
        didUploadSelector:@selector(didUploadFile:error:contextInfo:) contextInfo:NULL];
}

- (void)didUploadFile:(NSURL*)fileURL error:(NSError*)error contextInfo:(void*)contextInfo
{
    NSLog( @"didUploadFile called with:\n" );
    NSLog( @"  fileURL:     %@\n", fileURL );
    NSLog( @"  error:       %@\n", error );
    NSLog( @"  contextInfo: %p\n", contextInfo );
}

//------------------------------------------------------------------------------------------------------------------- openCamera

- (void)openCamera
{
    [[self selectedCamera] requestOpenSession];
}

#pragma mark -
#pragma mark ICDeviceBrowser delegate methods
//------------------------------------------------------------------------------------------------------------------------------
// Please refer to the header files in ImageCaptureCore.framework for documentation about the following delegate methods.

//--------------------------------------------------------------------------------------- deviceBrowser:didAddDevice:moreComing:

- (void)deviceBrowser:(ICDeviceBrowser*)browser didAddDevice:(ICDevice*)addedDevice moreComing:(BOOL)moreComing
{
    NSLog( @"deviceBrowser:didAddDevice:moreComing: \n%@\n", addedDevice );

    if ( (addedDevice.type & ICDeviceTypeMaskCamera) == ICDeviceTypeCamera )
    {
        [self willChangeValueForKey:@"cameras"];
        [self.cameras addObject:addedDevice];
        [self didChangeValueForKey:@"cameras"];
        addedDevice.delegate = self;
    }
}

//----------------------------------------------------------------------------------------------- deviceBrowser:didRemoveDevice:

- (void)deviceBrowser:(ICDeviceBrowser*)browser didRemoveDevice:(ICDevice*)removedDevice moreGoing:(BOOL)moreGoing
{
    NSLog( @"deviceBrowser:didRemoveDevice: \n%@\n", removedDevice );
    [self.camerasController removeObject:removedDevice];
}

//------------------------------------------------------------------------------------------- deviceBrowser:deviceDidChangeName:

- (void)deviceBrowser:(ICDeviceBrowser*)browser deviceDidChangeName:(ICDevice*)device;
{
    NSLog( @"deviceBrowser:\n%@\ndeviceDidChangeName: \n%@\n", browser, device );
}

#pragma mark -
#pragma mark ICDevice & ICCameraDevice delegate methods
//------------------------------------------------------------------------------------------------------------- didRemoveDevice:

- (void)didRemoveDevice:(ICDevice*)removedDevice
{
    NSLog( @"didRemoveDevice: \n%@\n", removedDevice );
    [self.camerasController removeObject:removedDevice];
}

//---------------------------------------------------------------------------------------------- device:didOpenSessionWithError:

- (void)device:(ICDevice*)device didOpenSessionWithError:(NSError*)error
{
    NSLog( @"device:didOpenSessionWithError: \n" );
    NSLog( @"  device: %@\n", device );
    NSLog( @"  error : %@\n", error );
}

//-------------------------------------------------------------------------------------------------------- deviceDidBecomeReady:

- (void)deviceDidBecomeReady:(ICCameraDevice*)camera;
{
    NSLog( @"deviceDidBecomeReady: \n%@\n\nmediaFiles:\n\n", camera );
    //NSLog( @"contents:\n%@", [device contents] );
    //NSLog( @"mediaFiles:\n%@", [device mediaFiles] );
}

//--------------------------------------------------------------------------------------------- device:didCloseSessionWithError:

- (void)device:(ICDevice*)device didCloseSessionWithError:(NSError*)error
{
    NSLog( @"device:didCloseSessionWithError: \n" );
    NSLog( @"  device: %@\n", device );
    NSLog( @"  error : %@\n", error );
}

- (void)deviceDidChangeName:(ICDevice*)device;
{
    NSLog( @"deviceDidChangeName: \n%@\n", device );
}

- (void)device:(ICDevice*)device didReceiveStatusInformation:(NSDictionary*)status
{
    NSLog( @"device: \n%@\ndidReceiveStatusInformation: \n%@\n", device, status );
}

- (void)device:(ICDevice*)device didEncounterError:(NSError*)error
{
    NSLog( @"device: \n%@\ndidEncounterError: \n%@\n", device, error );

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = [error localizedDescription];

    [alert beginSheetModalForWindow:self.window completionHandler:nil];
}

- (void)cameraDeviceDidChangeCapability:(ICCameraDevice*)device
{
    NSLog( @"cameraDeviceDidChangeCapability: \n%@\n", device );
}

- (void)cameraDevice:(nonnull ICCameraDevice *)camera didAddItems:(nonnull NSArray<ICCameraItem *> *)items
{
    NSLog( @"cameraDevice: \n%@\ndidAddItems: \n%@\n", camera, items );
}

- (void)cameraDevice:(nonnull ICCameraDevice *)camera didReceiveMetadata:(NSDictionary * _Nullable)metadata
    forItem:(nonnull ICCameraItem *)item error:(NSError * _Nullable)error
{
    NSLog( @"cameraDevice:didReceiveMetadataForItem:\n" );
    NSLog( @"  device: %@\n", camera );
    NSLog( @"  item:   %@\n", item );
}

- (void)cameraDevice:(nonnull ICCameraDevice *)camera didReceivePTPEvent:(nonnull NSData *)eventData
{

}

- (void)cameraDevice:(nonnull ICCameraDevice *)camera didReceiveThumbnail:(CGImageRef _Nullable)thumbnail
    forItem:(nonnull ICCameraItem *)item error:(NSError * _Nullable)error
{
    NSLog( @"cameraDevice:didReceiveThumbnailForItem:\n" );
    NSLog( @"  device: %@\n", camera );
    NSLog( @"  item:   %@\n", item );
}

- (void)cameraDevice:(nonnull ICCameraDevice *)camera didRemoveItems:(nonnull NSArray<ICCameraItem *> *)items
{
    NSLog( @"cameraDevice: \n%@\ndidRemoveItems: \n%@\n", camera, items );
}

- (void)cameraDevice:(nonnull ICCameraDevice *)camera didRenameItems:(nonnull NSArray<ICCameraItem *> *)items
{

}

- (void)cameraDeviceDidEnableAccessRestriction:(nonnull ICDevice *)device
{

}

- (void)cameraDeviceDidRemoveAccessRestriction:(nonnull ICDevice *)device
{

}

- (void)deviceDidBecomeReadyWithCompleteContentCatalog:(nonnull ICCameraDevice *)device
{

}

@end
