//
//  CGImageRefToNSImageTransformer.m
//  CameraBrowser
//
//  Created by Danil Korotenko on 5/13/24.
//

#import "CGImageRefToNSImageTransformer.h"
#import <Cocoa/Cocoa.h>
#import <ImageCaptureCore/ImageCaptureCore.h>

@implementation CGImageRefToNSImageTransformer

+ (Class)transformedValueClass { return [NSImage class]; }

+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)item
{
    if ( item )
    {
        NSImage*  newImage  = nil;
        newImage = [[[NSImage alloc] initWithCGImage:(CGImageRef)item size:NSZeroSize] autorelease];
        return newImage;
    }
    return nil;
}

@end
