//
//  DescriptionParser.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/15/13.

#import "DescriptionParser.h"

@implementation DescriptionParser{
    NSMutableDictionary *descriptionsFound_;
    NSMutableString *currentNodeContent_;
    int informationTemplateDepth_;
    BOOL isInformationTemplate_;
    NSMutableArray *nodeStack_;
    int descriptionPartDepth_;
    BOOL isDescriptionPart_;
    NSXMLParser *xmlParser_;
    NSString *lastTitle_;
}

- (id)init
{
    self = [super init];
    if (self) {
        descriptionsFound_ = [[NSMutableDictionary alloc] init];
        nodeStack_ = [[NSMutableArray alloc] init];
        [self resetDefaults];
        self.done = nil;
    }
    return self;
}

-(void)resetDefaults
{
    [descriptionsFound_ removeAllObjects];
    [nodeStack_ removeAllObjects];
    informationTemplateDepth_ = 0;
    descriptionPartDepth_ = 0;
    isInformationTemplate_ = NO;
    isDescriptionPart_ = NO;
    lastTitle_ = @"";
}

-(void)parse
{
    [self resetDefaults];
    xmlParser_ = [[NSXMLParser alloc] initWithData:[self.xml dataUsingEncoding:NSUTF8StringEncoding]];
    xmlParser_.delegate = self;
    [xmlParser_ parse];
}

-(NSString *)getCurrentNodeParentElementName
{
    if(nodeStack_.count < 2) return nil;
    return nodeStack_[nodeStack_.count - 2];
}

#pragma mark - NSXMLParserDelegate Methods

- (void) parser:(NSXMLParser *)parser didEndElement:(NSString *)elementname namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    // Now that this "didEndElement:" method has been invoked it is safe
    // to start making decisions about what was found...
    
    // Trim leading and trailing whitespace
    NSString *trimmedCurrentNodeContent = [currentNodeContent_ stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    
    
    /*
    - Debugging bootstrap
     
    - Quick node debug printout
    NSLog(@"\nNODE \n\tHERITAGE: %@ \n\tCONTENT: %@ \n\tPARENT: %@",
        [nodeStack_ componentsJoinedByString:@"->"],
        trimmedCurrentNodeContent,
        [self getCurrentNodeParentElementName]
    );
    
    - For debugging get the "parsetree" xml for an image which has descriptions in *many* languages:
    http://commons.wikimedia.org/wiki/Special:ApiSandbox#action=query&prop=revisions&format=json&rvprop=content&rvlimit=1&rvgeneratexml=&rvparse=&titles=File%3A2011-08-01%2010-31-42%20Switzerland%20Segl-Maria.jpg&redirects=
     
    - Do the same for an image which only has one description (xml has slight difference from many language version):
     http://commons.wikimedia.org/wiki/Special:ApiSandbox#action=query&prop=revisions&format=json&rvprop=content&rvlimit=1&rvgeneratexml=&rvparse=&titles=File%3AA%20Test%20Image.jpeg&redirects=
    
    - Follow link above, click "Make Request", scroll to bottom, search for "parsetree"
    - Copy that xml to http://www.freeformatter.com/xml-formatter.html#ad-output
     
    - This parser code quickly extracts just the descriptions
    */
    
    

    // If parsed "<title>Information</title>" within <template> tag...
    if ([elementname isEqualToString:@"title"]) {
        
        // Remember the last title so if/when a description is grabbed its language can be known
        lastTitle_ = trimmedCurrentNodeContent;
        
        if ([[self getCurrentNodeParentElementName] isEqualToString:@"template"]) {
            if ([[trimmedCurrentNodeContent lowercaseString] isEqualToString:@"information"]) {
                // Within the "Information" template tag
                isInformationTemplate_ = YES;
                // Track depth so it can be known when no longer within "Information" template tag
                informationTemplateDepth_ = nodeStack_.count - 1;
            }
        }
    }
    else if (isInformationTemplate_ && [elementname isEqualToString:@"template"]) {
        if (nodeStack_.count == informationTemplateDepth_) {
            // No longer within "Information" template tag
            isInformationTemplate_ = NO;
        }
    }
    // If parsed "<name>Description</name>" within <part> tag...
    else if (isInformationTemplate_ && [elementname isEqualToString:@"name"]) {
        if ([[self getCurrentNodeParentElementName] isEqualToString:@"part"]) {
            if ([[trimmedCurrentNodeContent lowercaseString] isEqualToString:@"description"]) {
                // Within the "Description" part tag
                isDescriptionPart_ = YES;
                // Track depth so it can be known when no longer within "Description" part tag
                descriptionPartDepth_ = nodeStack_.count - 1;
            }
        }
    }
    else if (isDescriptionPart_ && [elementname isEqualToString:@"part"]) {
        if (nodeStack_.count == descriptionPartDepth_) {
            // If no longer within "Description" part tag it is time to invoke the "done:" callback block
            // so the found descriptions can be used
            if(self.done != nil){
                self.done(descriptionsFound_);
                self.done = nil;
            }
            [parser abortParsing];
        }
    }
    // If examining a "value" element nested in an information template and also nested in a description part
    else if (isInformationTemplate_ && isDescriptionPart_ && [elementname isEqualToString:@"value"]) {
        if (trimmedCurrentNodeContent.length > 0){
            // If only one entry, should the title be changed to "en"?
            if ([[lastTitle_ lowercaseString] isEqualToString:@"information"]) lastTitle_ = @"en";
            descriptionsFound_[lastTitle_] = trimmedCurrentNodeContent;
        }
    }
    
    [nodeStack_ removeLastObject];
    currentNodeContent_ = nil;
}

- (void) parser:(NSXMLParser *)parser didStartElement:(NSString *)elementname namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    currentNodeContent_ = nil;
    [nodeStack_ addObject:elementname];
}

- (void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (!currentNodeContent_) {
        currentNodeContent_ = [NSMutableString string];
    }
    // NSXMLParser may retrieve node content in multiple chunks, so you must append:
    // See: http://stackoverflow.com/a/9396532/135557
    [currentNodeContent_ appendString:string];
}

@end
