#import "FIPOwnedImageStore.h"
#include <fcntl.h>
#include <unistd.h>

@interface FIPOwnedTask ()
@property(nonatomic, readwrite) NSString *scope;
@property(nonatomic, readwrite) NSString *task;
@property(nonatomic) BOOL started;
@property(nonatomic) BOOL finished;
@property(nonatomic) BOOL cancelled;
@property(nonatomic) NSUInteger writers;
@end
@implementation FIPOwnedTask
@end

@implementation FIPOwnedShareAttachment {
  NSString *_scope;
  NSString *_task;
  NSString *_name;
}
- (instancetype)initWithScope:(NSString *)scope task:(NSString *)task relativeName:(NSString *)name {
  if ((self = [super init])) { _scope = [scope copy]; _task = [task copy]; _name = [name copy]; }
  return self;
}
- (NSURL *)URL {
  if (![@[@"attachment", @"attachment.json", @"attachment.csv", @"attachment.zip", @"attachment.txt"] containsObject:_name]) return nil;
  NSString *payload = [FIPOwnedImageStore payloadForScope:_scope task:_task kind:@"export"];
  if (!payload) return nil;
  NSString *path = [payload stringByAppendingPathComponent:_name];
  NSDictionary *attributes = [NSFileManager.defaultManager attributesOfItemAtPath:path error:nil];
  if (![attributes[NSFileType] isEqual:NSFileTypeRegular] || ![path isEqual:path.stringByResolvingSymlinksInPath]) return nil;
  return [NSURL fileURLWithPath:path];
}
@end

@implementation FIPOwnedImageStore
static NSString *temporaryRoot;
static FIPOwnedTask *currentTask;
static NSString *const threadKey = @"co.byite.soongong.pickerOwner";

+ (void)configureWithTemporaryRoot:(NSString *)root {
  @synchronized(self) { temporaryRoot = [root stringByResolvingSymlinksInPath]; }
}
+ (BOOL)isConfigured { @synchronized(self) { return temporaryRoot != nil; } }
+ (BOOL)validUUID:(NSString *)value {
  return [value isKindOfClass:NSString.class] &&
      [[[[NSUUID alloc] initWithUUIDString:value] UUIDString].lowercaseString isEqualToString:value];
}
+ (BOOL)plainDirectory:(NSString *)path {
  BOOL directory = NO;
  return [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&directory] && directory &&
      [path isEqualToString:[path stringByResolvingSymlinksInPath]];
}
+ (NSString *)payloadForScope:(NSString *)scope task:(NSString *)task kind:(NSString *)kind {
  @synchronized(self) {
    if (!temporaryRoot || ![self validUUID:scope] || ![self validUUID:task]) return nil;
    NSString *root = [temporaryRoot stringByAppendingPathComponent:@"soongong-owned-v1"];
    NSString *scopePath = [root stringByAppendingPathComponent:scope];
    NSString *taskPath = [scopePath stringByAppendingPathComponent:task];
    NSString *payload = [taskPath stringByAppendingPathComponent:@"payload"];
    for (NSString *path in @[root, scopePath, taskPath, payload]) {
      if (![self plainDirectory:path]) return nil;
    }
    NSFileManager *files = NSFileManager.defaultManager;
    if ([files fileExistsAtPath:[scopePath stringByAppendingPathComponent:@".revoked"]] ||
        [files fileExistsAtPath:[taskPath stringByAppendingPathComponent:@".delete"]]) return nil;
    NSString *marker = [taskPath stringByAppendingPathComponent:@"marker.json"];
    NSDictionary *attributes = [files attributesOfItemAtPath:marker error:nil];
    if (![attributes[NSFileType] isEqual:NSFileTypeRegular] || [attributes[NSFileSize] unsignedLongLongValue] > 4096 ||
        ![marker isEqualToString:[marker stringByResolvingSymlinksInPath]]) return nil;
    NSData *bytes = [NSData dataWithContentsOfFile:marker];
    id data = bytes ? [NSJSONSerialization JSONObjectWithData:bytes options:0 error:nil] : nil;
    if (![data isKindOfClass:NSDictionary.class] || ![data[@"version"] isEqual:@1] ||
        ![data[@"scope"] isEqual:scope] || ![data[@"task"] isEqual:task] || ![data[@"kind"] isEqual:kind] ||
        ![data[@"created"] isKindOfClass:NSNumber.class] || ![data[@"expires"] isKindOfClass:NSNumber.class] ||
        [data[@"created"] longLongValue] <= 0 || [data[@"expires"] longLongValue] <= [data[@"created"] longLongValue]) return nil;
    return payload;
  }
}
+ (BOOL)prepareScope:(NSString *)scope task:(NSString *)task {
  @synchronized(self) {
    if (currentTask || ![self payloadForScope:scope task:task kind:@"picker"]) return NO;
    currentTask = [[FIPOwnedTask alloc] init]; currentTask.scope = scope; currentTask.task = task;
    return YES;
  }
}
+ (FIPOwnedTask *)begin {
  @synchronized(self) {
    if (currentTask.started || ![self allowed:currentTask]) return nil;
    currentTask.started = YES; return currentTask;
  }
}
+ (BOOL)allowed:(FIPOwnedTask *)task {
  @synchronized(self) {
    return task && task == currentTask && !task.cancelled && !task.finished &&
        [self payloadForScope:task.scope task:task.task kind:@"picker"] != nil;
  }
}
+ (void)finish:(FIPOwnedTask *)task { @synchronized(self) { task.finished = YES; } }
+ (NSDictionary *)statusScope:(NSString *)scope task:(NSString *)task {
  @synchronized(self) {
    BOOL matches = [currentTask.scope isEqual:scope] && [currentTask.task isEqual:task];
    return @{@"active": @(matches && (currentTask.writers > 0 || (currentTask.started && !currentTask.finished))), @"unknown": @NO};
  }
}
+ (NSDictionary *)cancelScope:(NSString *)scope task:(NSString *)task {
  @synchronized(self) {
    if ([currentTask.scope isEqual:scope] && [currentTask.task isEqual:task]) currentTask.cancelled = YES;
    return [self statusScope:scope task:task];
  }
}
+ (BOOL)releaseScope:(NSString *)scope task:(NSString *)task {
  @synchronized(self) {
    if (![currentTask.scope isEqual:scope] || ![currentTask.task isEqual:task]) return YES;
    if ([[self statusScope:scope task:task][@"active"] boolValue]) return NO;
    currentTask = nil; return YES;
  }
}
+ (NSDictionary *)recover {
  @synchronized(self) {
    // iOS does not restart a killed plugin's callbacks in a fresh process. Disk
    // markers enumerate every orphan; the Dart owner sweeps them before reuse.
    if (currentTask) return [self statusScope:currentTask.scope task:currentTask.task];
    return @{@"active": @NO, @"unknown": @NO};
  }
}
+ (id)performForTask:(FIPOwnedTask *)task block:(id (^)(void))block {
  @synchronized(self) {
    if (![self allowed:task]) return nil;
    task.writers++;
  }
  NSMutableDictionary *locals = NSThread.currentThread.threadDictionary;
  id previous = locals[threadKey]; locals[threadKey] = task;
  @try { return block(); }
  @finally {
    if (previous) locals[threadKey] = previous; else [locals removeObjectForKey:threadKey];
    @synchronized(self) { task.writers--; }
  }
}
+ (NSString *)temporaryPathWithSuffix:(NSString *)suffix {
  @synchronized(self) {
    FIPOwnedTask *task = NSThread.currentThread.threadDictionary[threadKey];
    if (![self allowed:task]) return nil;
    NSString *extension = [suffix hasPrefix:@"."] ? [suffix substringFromIndex:1] : suffix.pathExtension;
    NSCharacterSet *unsafe = NSCharacterSet.alphanumericCharacterSet.invertedSet;
    if (extension.length == 0 || extension.length > 10 || [extension rangeOfCharacterFromSet:unsafe].location != NSNotFound) extension = @"jpg";
    return [[self payloadForScope:task.scope task:task.task kind:@"picker"]
        stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", NSUUID.UUID.UUIDString.lowercaseString, extension]];
  }
}
+ (BOOL)writeData:(NSData *)data toPath:(NSString *)path {
  FIPOwnedTask *task = NSThread.currentThread.threadDictionary[threadKey];
  if (![self allowed:task] || !path || !data) return NO;
  NSString *payload = [self payloadForScope:task.scope task:task.task kind:@"picker"];
  if (![path.stringByDeletingLastPathComponent isEqual:payload]) return NO;
  int descriptor = open(path.fileSystemRepresentation, O_CREAT | O_EXCL | O_WRONLY | O_NOFOLLOW, 0600);
  if (descriptor < 0) return NO;
  BOOL ok = YES;
  const uint8_t *bytes = data.bytes;
  NSUInteger offset = 0;
  while (offset < data.length) {
    if (![self allowed:task]) { ok = NO; break; }
    ssize_t count = write(descriptor, bytes + offset, MIN((NSUInteger)65536, data.length - offset));
    if (count <= 0) { ok = NO; break; }
    offset += (NSUInteger)count;
  }
  if (close(descriptor) != 0) ok = NO;
  return ok && [self allowed:task];
}
@end
