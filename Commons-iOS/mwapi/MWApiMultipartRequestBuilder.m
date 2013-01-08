//
//  MWApiMultipartRequestBuilder.m
//  mwapi
//
//  Created by Jaikumar Bhambhwani on 12/2/12.
//  Copyright (c) 2012 Wikimedia Foundation. All rights reserved.
//

#import "MWApiMultipartRequestBuilder.h"
#import "MWApi.h"

@implementation MWApiMultipartRequestBuilder

- (id) initWithApi:(MWApi *)mwapi
{
    //Default values for ivars
    contentDisposition_ = @"form-data";
    contentType_ = @"text/plain";
    charset_ = @"US-ASCII";
    contentEncoding_ = @"8bit";
    boundaryString_ = [MWApiMultipartRequestBuilder generateBoundaryString];
    
    self = [super initWithApi:mwapi];
    return self;
}

+ (NSString *)generateBoundaryString
{
    CFUUIDRef       uuid;
    CFStringRef     uuidStr;
    NSString *      result;
    
    uuid = CFUUIDCreate(NULL);
    assert(uuid != NULL);
    
    uuidStr = CFUUIDCreateString(NULL, uuid);
    assert(uuidStr != NULL);
    
    result = [NSString stringWithFormat:@"Boundary-%@", uuidStr];
    
    CFRelease(uuidStr);
    CFRelease(uuid);
    
    return result;
}

- (NSString *)generateBodyForParam:(NSString *)name  withValue:(NSString *)value withFilename:(NSString *)filename withContentType:(NSString *)contentType withCharset:(NSString *)charset withContentEncoding:(NSString *) contentEncoding
{
    NSString *filenameParam = (filename != nil)?[NSString stringWithFormat:@"; filename=\"%@\"",filename]:@"";
    NSString *charsetParam  = (filename == nil)?[NSString stringWithFormat:@"; charset=%@",(charset !=nil)?charset:charset_]:@"";
    NSString *bodyPrefixStr = [NSString stringWithFormat:
                     @
                     // empty preamble
                     "\r\n"
                     "--%@\r\n"
                     "Content-Disposition: %@; name=\"%@\"%@\r\n"
                     "Content-Type: %@%@\r\n"
                     "Content-Transfer-Encoding: %@\r\n"
                     "\r\n%@"
                     "",
                     boundaryString_,contentDisposition_,name,filenameParam,
                     (contentType !=nil)?contentType:contentType_,
                     charsetParam,
                     (contentEncoding !=nil)?contentEncoding:contentEncoding_,
                     value
                     ];
    return bodyPrefixStr;
}

- (NSString *)generateBodyForParam:(NSString *)name  withValue:(NSString *)value
{
    return [self generateBodyForParam:name withValue:value withFilename:nil withContentType:nil withCharset:nil withContentEncoding:nil];
}

-(NSString *) generateParamsBody
{
    NSString *paramsBody = @"";
    
    for (NSString *key in params_) {
        NSString *value = [params_ objectForKey:key];
        paramsBody = [paramsBody stringByAppendingString:[self generateBodyForParam:key withValue:value]];
    }
    return paramsBody;
}

// A separate function since the filepath can be only be available in the wrapper

-(NSData *)dataToUpload:(NSString *)filename withFileData:(NSData *)data
{
    NSString *uploadBodyHead = [self generateBodyForParam:@"file" withValue:@"" withFilename:filename withContentType:@"application/octet-stream" withCharset:nil withContentEncoding:@"binary"];
    NSString *uploadBodySuffix = [NSString stringWithFormat:
                     @
                     "\r\n"
                     "--%@--\r\n"
                     "\r\n",
                     //empty epilogue,
                     boundaryString_
                     ];
    NSMutableData *uploadBodyData = [NSMutableData dataWithData:[uploadBodyHead dataUsingEncoding:NSUTF8StringEncoding]];
    [uploadBodyData appendData:data];
    [uploadBodyData appendData:[NSMutableData dataWithData:[uploadBodySuffix dataUsingEncoding:NSUTF8StringEncoding]]];
    return uploadBodyData;
}

- (NSURLRequest *) buildRequest:(NSString *)requestType withFilename:(NSString *)filename withFilePath:(NSString *)filepath
{
    return [self buildRequest:requestType withFilename:filename withFileData:[NSData dataWithContentsOfFile:filepath]];
}

- (NSURLRequest *) buildRequest:(NSString *)requestType withFilename:(NSString *)filename withFileData:(NSData *)data
{
    [params_ setValue:dataType_ forKey:@"format"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]init];
    NSMutableData *body = [NSMutableData dataWithData:[[self generateParamsBody] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[self dataToUpload:filename withFileData:data]];
    
    [request setURL:api_.apiURL];
    [request setHTTPMethod:requestType];
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundaryString_] forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"" forHTTPHeaderField:@"Accept-Encoding"];
    [request setHTTPBody:body];
    return request;
}

@end
