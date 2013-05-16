//
//  DescriptionParser.h
//  Commons-iOS
//
//  Created by Monte Hurd on 5/15/13.

#import <Foundation/Foundation.h>

// Quickly parses description(s) out of "parsetree" xml
// Returns them in a dictionary passed to the "done" callback block
// Dictionary has lang ("en", "fr, "ru" etc) as keys and descriptions as values

@interface DescriptionParser : NSObject <NSXMLParserDelegate>

@property (strong, nonatomic) NSString *xml;
@property (strong, nonatomic) void(^done)(NSDictionary *);

-(void)parse;

@end
