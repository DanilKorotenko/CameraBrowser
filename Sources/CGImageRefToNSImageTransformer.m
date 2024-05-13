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
        NSImage *newImage = [[NSImage alloc] initWithCGImage:(CGImageRef)item size:NSZeroSize];
        return newImage;
    }
    return nil;
}

@end
