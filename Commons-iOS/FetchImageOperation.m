//
//  FetchImageOperation.m
//
//  Created by MONTE HURD on 5/7/13.

#import "FetchImageOperation.h"

@interface FetchImageOperation(){
    int expectedContentLength_;
}

- (NSError *)getErrorWithMessage:(NSString *)msg code:(NSInteger)code;

@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSURLResponse *response;
@property (strong, nonatomic) NSMutableData *data;
@property (strong, nonatomic) NSError *error;

@end

@implementation FetchImageOperation{
    // In concurrent operations, we have to manage the operation's state
    BOOL executing_;
    BOOL finished_;
}

#pragma mark -
#pragma mark Initialization & Memory Management

- (id)initWithURL:(NSURL *)url
{
	if( (self = [super init]) ) {
        self.url = url;
        finished_ = NO;
        executing_ = NO;
        self.data = nil;
        self.error = nil;
        self.response = nil;
        self.connection = nil;
        self.completionHandler = nil;
        self.progressHandler = nil;
        self.doneInterval = 0;
        self.startInterval = 0;
        [self setQueuePriority:NSOperationQueuePriorityNormal];
        self.initInterval = [NSDate timeIntervalSinceReferenceDate];
    }
	return self;
}

- (void)dealloc
{
	if( self.connection ) {
		[self.connection cancel];
		self.connection = nil;
	}
    self.url = nil;
	self.data = nil;
	self.error = nil;
    self.response = nil;
    self.completionHandler = nil;
    self.progressHandler = nil;
}

#pragma mark -
#pragma mark Start & Utility Methods
	
// Convenience method to cancel URL connection if it still exists and finish up the operation.
- (void)done
{
    //NSLog(@"\n\nOperation Done!");
    
    self.doneInterval = [NSDate timeIntervalSinceReferenceDate];
    
    if (self.error != nil) {
        self.data = nil;
        self.response = nil;
    }
    
	if(self.connection) {
		[self.connection cancel];
		self.connection = nil;
	}
    
    if (self.completionHandler != nil) {
        self.completionHandler(self.response, self.data, self.error, self.doneInterval - self.startInterval);
    }
	
	// Alert anyone that we are finished
	[self willChangeValueForKey:@"isExecuting"];
	[self willChangeValueForKey:@"isFinished"];
	executing_ = NO;
	finished_  = YES;
	[self didChangeValueForKey:@"isFinished"];
	[self didChangeValueForKey:@"isExecuting"];
    
    // Now safe for the thread to exit - needed because of the @autoreleasepool
    // See: http://stackoverflow.com/a/1730053/135557 for more info
    CFRunLoopStop(CFRunLoopGetCurrent());
}

-(void)cancelled
{
	// Code for being cancelled    
    self.error = [self getErrorWithMessage:@"Operation Cancelled" code:100];
	[self done];
}

- (void)start{
		
    if(finished_ || [self isCancelled]) {
		[self cancelled];
		return;
	}
    
    //NSLog(@"Operation Start!");

    @autoreleasepool {
        
        self.startInterval = [NSDate timeIntervalSinceReferenceDate];
        
        // The autoreleasepool is needed to keep the thread from exiting before NSURLConnection finishes
        // See: http://stackoverflow.com/q/1728631/135557 for more info
        
        // From this point on, the operation is officially executing--remember, isExecuting
        // needs to be KVO compliant!
        [self willChangeValueForKey:@"isExecuting"];
        executing_ = YES;
        [self didChangeValueForKey:@"isExecuting"];
        
        // Create the NSURLConnection--this could have been done in init, but we delayed
        // until no in case the operation was never enqueued or was cancelled before starting
        
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:self.url];
        self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        
        CFRunLoopRun(); // Avoid thread exiting
    }
}
	
#pragma mark -
#pragma mark Overrides
	
- (BOOL)isConcurrent{
	return YES;
}

- (BOOL)isExecuting{
	return executing_;
}

- (BOOL)isFinished{
	return finished_;
}
	
#pragma mark -
#pragma mark NSURLConnection Delegate Methods

- (NSError*)getErrorWithMessage:(NSString *)msg code:(NSInteger)code
{
    return [[NSError alloc] initWithDomain:@"FetchImageOperation"
                                      code:code
                                  userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(msg, nil)}];
}

// The connection failed
- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    if (self.progressHandler != nil) self.progressHandler(expectedContentLength_, [self.data length]);

	// Check if the operation has been cancelled
	if([self isCancelled]) {
		[self cancelled];
        return;
	}
	else {
		self.error = error;
		[self done];
	}
}

// The connection received more data
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	// Check if the operation has been cancelled
	if([self isCancelled]) {
		[self cancelled];
		return;
	}	
	[self.data appendData:data];
    
    if (self.progressHandler != nil) self.progressHandler(expectedContentLength_, [self.data length]);
}

// Initial response
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    expectedContentLength_ = [response expectedContentLength];

	// Check if the operation has been cancelled
	if([self isCancelled]) {
		[self cancelled];
		return;
	}
	
	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
	NSInteger statusCode = [httpResponse statusCode];
	if( statusCode == 200 ) {
		NSUInteger contentSize = [httpResponse expectedContentLength] > 0 ? [httpResponse expectedContentLength] : 0;
		self.data = [[NSMutableData alloc] initWithCapacity:contentSize];
        self.response = response;
        self.error = nil;
	} else {
        self.error = [self getErrorWithMessage:@"Operation Received Bad Response" code:statusCode];
		[self done];
	}
}
	
- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
	// Check if the operation has been cancelled
	if([self isCancelled]) {
		[self cancelled];
		return;
	}
	else {
        // The response has been received - so self.data should be populated now
		[self done]; 
	}
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
	return nil;
}
	
@end
