// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTImagePickerPhotoAssetUtil.h"
#import "FIPOwnedImageStore.h"
#import "FLTImagePickerImageUtil.h"
#import "FLTImagePickerMetaDataUtil.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@implementation FLTImagePickerPhotoAssetUtil

+ (PHAsset *)getAssetFromImagePickerInfo:(NSDictionary *)info {
  return info[UIImagePickerControllerPHAsset];
}

+ (NSURL *)saveVideoFromURL:(NSURL *)videoURL {
  if (![[NSFileManager defaultManager] isReadableFileAtPath:[videoURL path]]) {
    return nil;
  }
  NSString *fileName = [videoURL lastPathComponent];
  NSString *path = [self temporaryFilePath:fileName];
  if (!path) return nil;
  NSURL *destination = [NSURL fileURLWithPath:path];
  NSError *error;
  [[NSFileManager defaultManager] copyItemAtURL:videoURL toURL:destination error:&error];
  if (error) {
    return nil;
  }
  return destination;
}

+ (NSString *)saveImageWithOriginalImageData:(NSData *)originalImageData
                                       image:(UIImage *)image
                                    maxWidth:(NSNumber *)maxWidth
                                   maxHeight:(NSNumber *)maxHeight
                                imageQuality:(NSNumber *)imageQuality {
  NSString *suffix = kFLTImagePickerDefaultSuffix;
  FLTImagePickerMIMEType type = kFLTImagePickerMIMETypeDefault;
  NSDictionary *metaData = nil;
  // Getting the image type from the original image data if necessary.
  if (originalImageData) {
    type = [FLTImagePickerMetaDataUtil getImageMIMETypeFromImageData:originalImageData];
    suffix =
        [FLTImagePickerMetaDataUtil imageTypeSuffixFromType:type] ?: kFLTImagePickerDefaultSuffix;
    metaData = [FLTImagePickerMetaDataUtil getMetaDataFromImageData:originalImageData];
  }
  if (type == FLTImagePickerMIMETypeGIF) {
    GIFInfo *gifInfo = [FLTImagePickerImageUtil scaledGIFImage:originalImageData
                                                      maxWidth:maxWidth
                                                     maxHeight:maxHeight];

    return [self saveImageWithMetaData:metaData gifInfo:gifInfo suffix:suffix];
  } else {
    return [self saveImageWithMetaData:metaData
                                 image:image
                                suffix:suffix
                                  type:type
                          imageQuality:imageQuality];
  }
}

+ (NSString *)saveImageWithPickerInfo:(nullable NSDictionary *)info
                                image:(UIImage *)image
                         imageQuality:(NSNumber *)imageQuality {
  NSDictionary *metaData = info[UIImagePickerControllerMediaMetadata];
  return [self saveImageWithMetaData:metaData
                               image:image
                              suffix:kFLTImagePickerDefaultSuffix
                                type:kFLTImagePickerMIMETypeDefault
                        imageQuality:imageQuality];
}

+ (NSString *)saveImageWithMetaData:(NSDictionary *)metaData
                            gifInfo:(GIFInfo *)gifInfo
                             suffix:(NSString *)suffix {
  NSString *path = [self temporaryFilePath:suffix];
  return [self saveImageWithMetaData:metaData gifInfo:gifInfo path:path];
}

+ (NSString *)saveImageWithMetaData:(NSDictionary *)metaData
                              image:(UIImage *)image
                             suffix:(NSString *)suffix
                               type:(FLTImagePickerMIMEType)type
                       imageQuality:(NSNumber *)imageQuality {
  NSData *data = [FLTImagePickerMetaDataUtil convertImage:image
                                                usingType:type
                                                  quality:imageQuality];
  if (metaData) {
    NSData *updatedData = [FLTImagePickerMetaDataUtil imageFromImage:data withMetaData:metaData];
    // If updating the metadata fails, just save the original.
    if (updatedData) {
      data = updatedData;
    }
  }

  return [self createFile:data suffix:suffix];
}

+ (NSString *)saveImageWithMetaData:(NSDictionary *)metaData
                            gifInfo:(GIFInfo *)gifInfo
                               path:(NSString *)path {
  if (!path) return nil;
  CFStringRef imageType;
  if (@available(iOS 14.0, *)) {
    imageType = (__bridge CFStringRef)UTTypeGIF.identifier;
  } else {
    imageType = kUTTypeGIF;
  }
  CGImageDestinationRef destination = CGImageDestinationCreateWithURL(
      (__bridge CFURLRef)[NSURL fileURLWithPath:path], imageType, gifInfo.images.count, NULL);

  if (!destination) return nil;
  NSDictionary *frameProperties = @{
    (__bridge NSString *)kCGImagePropertyGIFDictionary : @{
      (__bridge NSString *)kCGImagePropertyGIFDelayTime : @(gifInfo.interval),
    },
  };

  NSMutableDictionary *gifMetaProperties = [NSMutableDictionary dictionaryWithDictionary:metaData];
  NSMutableDictionary *gifProperties =
      (NSMutableDictionary *)gifMetaProperties[(NSString *)kCGImagePropertyGIFDictionary];
  if (gifMetaProperties == nil) {
    gifProperties = [NSMutableDictionary dictionary];
  }

  gifProperties[(__bridge NSString *)kCGImagePropertyGIFLoopCount] = @0;

  CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)gifMetaProperties);

  for (NSInteger index = 0; index < gifInfo.images.count; index++) {
    UIImage *image = (UIImage *)[gifInfo.images objectAtIndex:index];
    CGImageDestinationAddImage(destination, image.CGImage,
                               (__bridge CFDictionaryRef)frameProperties);
  }

  CGImageDestinationFinalize(destination);
  CFRelease(destination);

  return path;
}

+ (NSString *)temporaryFilePath:(NSString *)suffix {
  return [FIPOwnedImageStore temporaryPathWithSuffix:suffix];
}

+ (NSString *)createFile:(NSData *)data suffix:(NSString *)suffix {
  NSString *path = [self temporaryFilePath:suffix];
  return path && [FIPOwnedImageStore writeData:data toPath:path] ? path : nil;
}

@end
