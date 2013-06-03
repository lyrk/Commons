//
//  FetchImageOperation.h
//
//  Created by MONTE HURD on 5/7/13.

@interface FetchImageOperation : NSOperation <NSURLConnectionDelegate>{

}

@property (strong, nonatomic) void (^completionHandler)(NSURLResponse*, NSData*, NSError*, NSTimeInterval);
@property (strong, nonatomic) void (^progressHandler)(float, float);
@property (strong, nonatomic) NSURL *url;

@property (nonatomic) NSTimeInterval startInterval;
@property (nonatomic) NSTimeInterval doneInterval;
@property (nonatomic) NSTimeInterval initInterval;

- (id)initWithURL:(NSURL*)url;
- (void)cancel;

@end
