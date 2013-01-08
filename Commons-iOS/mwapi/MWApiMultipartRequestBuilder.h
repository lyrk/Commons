//
//  MWApiMultipartRequestBuilder.h
//  mwapi
//
//  Created by Jaikumar Bhambhwani on 12/2/12.
//  Copyright (c) 2012 Wikimedia Foundation. All rights reserved.
//

#import "MWApiRequestBuilder.h"

@interface MWApiMultipartRequestBuilder : MWApiRequestBuilder{
    NSString *contentDisposition_;
    NSString *contentType_;
    NSString *charset_;
    NSString *contentEncoding_;
    NSString *boundaryString_;
}

-(NSURLRequest *) buildRequest:(NSString *)requestType withFilename:(NSString *)filename withFileData:(NSData *)data;

@end
