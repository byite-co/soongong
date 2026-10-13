#import <Foundation/Foundation.h>
#import "FIPOwnedImageStore.h"
#include <stdlib.h>
#include <string.h>
#include <limits.h>

static NSUInteger checks;
static void check(BOOL value) { checks++; if (!value) { fprintf(stderr, "ownership assertion %lu failed\n", (unsigned long)checks); exit(1); } }
static NSString *task(NSString *root, NSString *scope, NSString *identifier, NSString *kind) {
  NSString *path = [[[[root stringByAppendingPathComponent:@"soongong-owned-v1"]
      stringByAppendingPathComponent:scope] stringByAppendingPathComponent:identifier] stringByAppendingPathComponent:@"payload"];
  check([NSFileManager.defaultManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil]);
  NSDictionary *marker = @{@"version": @1, @"scope": scope, @"task": identifier, @"kind": kind, @"created": @1, @"expires": @(LLONG_MAX)};
  NSData *bytes = [NSJSONSerialization dataWithJSONObject:marker options:0 error:nil];
  check([bytes writeToFile:[path.stringByDeletingLastPathComponent stringByAppendingPathComponent:@"marker.json"] atomically:NO]);
  return path;
}
static NSString *identifier(void) { return NSUUID.UUID.UUIDString.lowercaseString; }

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    NSString *root = argc > 2 ? [NSString stringWithUTF8String:argv[2]] :
        [[NSTemporaryDirectory() stringByResolvingSymlinksInPath] stringByAppendingPathComponent:identifier()];
    check([NSFileManager.defaultManager createDirectoryAtPath:root withIntermediateDirectories:YES attributes:nil error:nil]);
    [FIPOwnedImageStore configureWithTemporaryRoot:root];
    NSString *scope = identifier(), *one = identifier();
    NSString *payload = task(root, scope, one, @"picker");
    check([FIPOwnedImageStore temporaryPathWithSuffix:@".jpg"] == nil);
    check(![FIPOwnedImageStore prepareScope:@"../escape" task:one]);
    check([FIPOwnedImageStore payloadForScope:scope task:one kind:@"export"] == nil);
    check([FIPOwnedImageStore prepareScope:scope task:one]);
    FIPOwnedTask *owner = [FIPOwnedImageStore begin]; check(owner != nil);
    NSString *saved = [FIPOwnedImageStore performForTask:owner block:^id {
      NSString *path = [FIPOwnedImageStore temporaryPathWithSuffix:@".jpg"];
      check([path.stringByDeletingLastPathComponent isEqual:payload]);
      check([FIPOwnedImageStore writeData:[@"synthetic-image" dataUsingEncoding:NSUTF8StringEncoding] toPath:path]);
      return path;
    }];
    check([NSFileManager.defaultManager fileExistsAtPath:saved]);
    check([[FIPOwnedImageStore recover][@"active"] boolValue]);
    check(![FIPOwnedImageStore releaseScope:scope task:one]);
    if (argc > 1 && strcmp(argv[1], "orphan") == 0) {
      // Actual child process exits before callback/finish: marker + file survive for scanner.
      _Exit(0);
    }
    check([[FIPOwnedImageStore cancelScope:scope task:one][@"active"] boolValue]);
    check([FIPOwnedImageStore performForTask:owner block:^id { return @"must not run"; }] == nil);
    [FIPOwnedImageStore finish:owner];
    check(![[FIPOwnedImageStore statusScope:scope task:one][@"active"] boolValue]);
    check([FIPOwnedImageStore releaseScope:scope task:one]);

    // A delayed callback retains A, so preparing B never redirects its writer.
    NSString *two = identifier(); NSString *payloadB = task(root, scope, two, @"picker");
    check([FIPOwnedImageStore prepareScope:scope task:two]);
    FIPOwnedTask *ownerB = [FIPOwnedImageStore begin]; check(ownerB != nil);
    check([FIPOwnedImageStore performForTask:owner block:^id { return @"must not run"; }] == nil);
    check([NSFileManager.defaultManager contentsOfDirectoryAtPath:payloadB error:nil].count == 0);
    check([FIPOwnedImageStore performForTask:ownerB block:^id {
      NSString *path = [FIPOwnedImageStore temporaryPathWithSuffix:@".jpg"];
      NSString *fence = [payloadB.stringByDeletingLastPathComponent stringByAppendingPathComponent:@".delete"];
      check([[@"1" dataUsingEncoding:NSUTF8StringEncoding] writeToFile:fence atomically:NO]);
      check(![FIPOwnedImageStore writeData:[NSMutableData dataWithLength:10] toPath:path]);
      check(![NSFileManager.defaultManager fileExistsAtPath:path]);
      return @YES;
    }] != nil);
    [FIPOwnedImageStore finish:ownerB]; check([FIPOwnedImageStore releaseScope:scope task:two]);
    check(![FIPOwnedImageStore prepareScope:scope task:two]);

    // Symlink payload never redirects writes into another task/source directory.
    NSString *three = identifier(), *linked = task(root, scope, three, @"picker");
    check([NSFileManager.defaultManager removeItemAtPath:linked error:nil]);
    check([NSFileManager.defaultManager createSymbolicLinkAtPath:linked withDestinationPath:payloadB error:nil]);
    check(![FIPOwnedImageStore prepareScope:scope task:three]);

    // No-copy export validation: roots remain independent and a revoked scope is rejected.
    NSString *exportScope = identifier(), *exportA = identifier(), *exportB = identifier();
    NSString *fileA = task(root, exportScope, exportA, @"export"), *fileB = task(root, exportScope, exportB, @"export");
    check([FIPOwnedImageStore payloadForScope:exportScope task:exportA kind:@"export"] != nil);
    check([FIPOwnedImageStore payloadForScope:exportScope task:exportB kind:@"export"] != nil);
    check(![fileA isEqual:fileB]);
    NSString *shareFile = [fileA stringByAppendingPathComponent:@"attachment.json"];
    check([[@"synthetic export" dataUsingEncoding:NSUTF8StringEncoding] writeToFile:shareFile atomically:NO]);
    FIPOwnedShareAttachment *deferredItem = [[FIPOwnedShareAttachment alloc] initWithScope:exportScope task:exportA relativeName:@"attachment.json"];
    check(deferredItem.URL != nil);
    NSString *revoked = [[fileA.stringByDeletingLastPathComponent stringByDeletingLastPathComponent] stringByAppendingPathComponent:@".revoked"];
    check([[@"1" dataUsingEncoding:NSUTF8StringEncoding] writeToFile:revoked atomically:NO]);
    check([FIPOwnedImageStore payloadForScope:exportScope task:exportA kind:@"export"] == nil);
    check([FIPOwnedImageStore payloadForScope:exportScope task:exportB kind:@"export"] == nil);
    check(deferredItem.URL == nil); // Deferred item request after revoke cannot return A's URL.
    check([NSFileManager.defaultManager fileExistsAtPath:shareFile]); // Even if cleanup failed.

    // Kill-before-callback is a real new process, not a fake Future or simulated return value.
    NSString *orphanRoot = [root stringByAppendingPathComponent:@"orphan-process"];
    NSTask *child = [[NSTask alloc] init];
    child.executableURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[0]]];
    child.arguments = @[@"orphan", orphanRoot];
    check([child launchAndReturnError:nil]); [child waitUntilExit]; check(child.terminationStatus == 0);
    NSArray *orphans = [NSFileManager.defaultManager subpathsAtPath:orphanRoot];
    check([[orphans filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF ENDSWITH %@", @"marker.json"]] count] == 1);
    check([[orphans filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF ENDSWITH %@", @".jpg"]] count] == 1);
    check(![[FIPOwnedImageStore recover][@"active"] boolValue]);
    check([NSFileManager.defaultManager removeItemAtPath:root error:nil]);
    printf("OwnedImageStore: %lu ownership assertions passed (including real orphan subprocess)\n", (unsigned long)checks);
  }
  return 0;
}
