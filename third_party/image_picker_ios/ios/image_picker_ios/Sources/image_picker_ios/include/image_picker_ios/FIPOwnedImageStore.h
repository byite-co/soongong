// SoonGong RC-02. Foundation-only ownership fence; upstream BSD license retained.
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface FIPOwnedTask : NSObject
@property(nonatomic, readonly) NSString *scope;
@property(nonatomic, readonly) NSString *task;
@end

@interface FIPOwnedImageStore : NSObject
+ (void)configureWithTemporaryRoot:(NSString *)root;
+ (BOOL)isConfigured;
+ (BOOL)prepareScope:(NSString *)scope task:(NSString *)task;
+ (nullable FIPOwnedTask *)begin;
+ (BOOL)allowed:(nullable FIPOwnedTask *)task;
+ (void)finish:(nullable FIPOwnedTask *)task;
+ (NSDictionary *)statusScope:(NSString *)scope task:(NSString *)task;
+ (NSDictionary *)cancelScope:(NSString *)scope task:(NSString *)task;
+ (BOOL)releaseScope:(NSString *)scope task:(NSString *)task;
+ (NSDictionary *)recover;
+ (nullable NSString *)payloadForScope:(NSString *)scope task:(NSString *)task kind:(NSString *)kind
    NS_SWIFT_NAME(payload(scope:task:kind:));
+ (nullable id)performForTask:(nullable FIPOwnedTask *)task block:(id _Nullable (^)(void))block;
+ (nullable NSString *)temporaryPathWithSuffix:(NSString *)suffix;
+ (BOOL)writeData:(NSData *)data toPath:(NSString *)path;
@end

// A share sheet asks for its item later. Resolve again at that exact boundary.
@interface FIPOwnedShareAttachment : NSObject
- (instancetype)initWithScope:(NSString *)scope task:(NSString *)task relativeName:(NSString *)name
    NS_SWIFT_NAME(init(scope:task:relativeName:));
@property(nonatomic, readonly, nullable) NSURL *URL NS_SWIFT_NAME(url);
@end
NS_ASSUME_NONNULL_END
