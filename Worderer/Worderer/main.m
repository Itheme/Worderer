//
//  main.m
//  Worderer
//
//  Created by Danila Parkhomenko on 30/06/16.
//  Copyright © 2016 Itheme. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CharTreeLayer.h"

typedef enum : NSUInteger {
    InputModeBroken = 0,
    InputModeHelp = 1,
    InputModeResourcesToJSON = 2,
    InputModeResourcesToXML = 3,
    InputModeResourcesToCode = 4,
    InputModeResourcesToRandom = 5,
    InputModeFileToJSON = 6,
    InputModeFileToXML = 7,
    InputModeFileToCode = 8,
    InputModeFileToRandom = 9
} InputMode;

InputMode validateInput(int argc, const char * argv[], NSString **inputFile, NSInteger *genCount) {
    if (argc < 2) {
        return InputModeResourcesToJSON;
    }
    NSMutableArray *args = [NSMutableArray array];
    BOOL json = false;
    BOOL code = false;
    BOOL generate = false;
    BOOL graphml = false;
    for (NSInteger i = 1; i < argc; i++) {
        NSString *string = [NSString stringWithCString:argv[i] encoding:NSASCIIStringEncoding];
        if ([string isEqualToString:@"-h"]) {
            return InputModeHelp;
        }
        if ([string isEqualToString:@"-json"]) {
            json = true;
            continue;
        }
        if ([string isEqualToString:@"-graphml"]) {
            graphml = true;
            continue;
        }
//        if ([string isEqualToString:@"-c"]) {
//            code = true;
//            continue;
//        }
        [args addObject:string];
    }
    for (NSInteger i = 0; i < args.count; i++) {
        if ([args[i] isEqualToString:@"-g"]) {
            generate = YES;
            [args removeObjectAtIndex:i];
            if (i < args.count) {
                *genCount = [args[i] integerValue];
                if (*genCount) {
                    [args removeObjectAtIndex:i];
                } else {
                    *genCount = 1;
                }
            }
            break;
        }
    }
    if (args.count > 0) {
        if ([args[0] isEqualToString:@"-i"]) {
            if (args.count > 1) {
                if ([[NSFileManager defaultManager] fileExistsAtPath:args[1]]) {
                    *inputFile = args[1];
                    if (generate) {
                        return InputModeFileToRandom;
                    }
                    if (code) {
                        return InputModeFileToCode;
                    }
                    if (graphml) {
                        return InputModeFileToXML;
                    }
                    return InputModeFileToJSON;
                }
                printf("%s", [[NSString stringWithFormat:@"File %@ found\n", args[1]] cStringUsingEncoding:NSASCIIStringEncoding]);
                return InputModeBroken;
            }
            printf("File not specified\n");
            return InputModeBroken;
        }
    }
    if (generate) {
        return InputModeResourcesToRandom;
    }
    if (code) {
        return InputModeResourcesToCode;
    }
    if (graphml) {
        return InputModeResourcesToXML;
    }
    return InputModeResourcesToJSON;
}


void collectTreeMap(CharTreeLayer *tree, NSMutableArray <CharTreeLayer *> **allObjects) {
    BOOL found = NO;
    for (CharTreeLayer *t in *allObjects) {
        if ([t isEqual:tree]) {
            found = YES;
            break;
        }
    }
    if (!found) {
        [*allObjects addObject:tree];
    }
    NSMutableArray *subs = [tree performSelector:@selector(subTree)];
    for (CharTreeLayer *sub in subs) {
        collectTreeMap(sub, allObjects);
    }
}

NSXMLDocument *makeGraphML(CharTreeLayer *tree) {
    NSXMLElement *root = [[NSXMLElement alloc] init];
    NSXMLDocument *doc = [[NSXMLDocument alloc] initWithRootElement:root];
    doc.version = @"1.0";
    doc.characterEncoding = @"UTF-8";
    root.name = @"graphml";
    [root setAttributesAsDictionary:@{@"xmlns": @"http://graphml.graphdrawing.org/xmlns",
                                      @"xmlns:xsi": @"http://www.w3.org/2001/XMLSchema-instance",
                                      @"xsi:schemaLocation": @"http://graphml.graphdrawing.org/xmlns\nhttp://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd"}];
    NSXMLElement *graph = [[NSXMLElement alloc] initWithName:@"graph"];
    [graph setAttributesAsDictionary:@{@"id": @"chars",
                                       @"edgedefault": @"directed"}];
    [root addChild:graph];
    NSMutableArray <CharTreeLayer *> *allObjects = [NSMutableArray array];
    collectTreeMap(tree, &allObjects);
    [allObjects enumerateObjectsUsingBlock:^(CharTreeLayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSXMLElement *node = [NSXMLElement elementWithName:@"node"];
        unichar c = (unichar)[obj performSelector:@selector(c)];
        [node setAttributesAsDictionary:@{@"id": [NSString stringWithFormat:@"n%ld", idx],
                                          @"label": [NSString stringWithFormat:@"%c", c]}];
        [graph addChild:node];
    }];
    __block NSInteger edgeNumber = 0;
    for (NSInteger sourceIdx = 0; sourceIdx < allObjects.count; sourceIdx++) {
        CharTreeLayer *source = allObjects[sourceIdx];
        NSMutableArray *subs = [source performSelector:@selector(subTree)];
        for (CharTreeLayer *sub in subs) {
            for (NSInteger tagetIdx = 0; tagetIdx < allObjects.count; tagetIdx++) {
                CharTreeLayer *target = allObjects[tagetIdx];
                if ([target isEqual:sub]) {
                    NSXMLElement *edge = [NSXMLElement elementWithName:@"edge"];
                    [edge setAttributesAsDictionary:@{@"id": [NSString stringWithFormat:@"e%ld", edgeNumber++],
                                                      @"source": [NSString stringWithFormat:@"n%ld", sourceIdx],
                                                      @"target": [NSString stringWithFormat:@"n%ld", tagetIdx]}];
                    [graph addChild:edge];
                    break;
                }
            }
        }
    }
    
    return doc;
}
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString *fileName = nil;
        NSInteger genCount = 0;
        InputMode mode = validateInput(argc, argv, &fileName, &genCount);
        if (mode == InputModeBroken) {
            return 1;
        }
        if (mode == InputModeHelp) {
            printf("Usage: \n");
            printf("  Worderer [-h]\n");
            printf("  Worderer [-i wordlist.txt] [{-json|-graphml|-g [count]}]\n");
            printf("    -h help\n");
            printf("    -i wordlist.txt words, one word per line in UTF8. If omitted, basic set of english words is used\n");
            printf("    -json output is json probability tree (default)\n");
//printf("    -c output is in form of objective c code\n");
            printf("    -g generates random words");
        } else {
            NSString *dataString;
            if (mode < InputModeFileToJSON) {
                NSDictionary *bulk = [NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"TestData" withExtension:@"plist"]];
                dataString = bulk[@"strings"];
            } else {
                dataString = [NSString stringWithContentsOfFile:fileName
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil];
            }
            NSArray <NSString *> *words = [[dataString lowercaseString] componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]];
            CharTreeLayer *charTree = [CharTreeLayer createWithSampleWords:words];
            //charTree = [CharTreeLayer createFromJSON:[NSData dataWithContentsOfFile:@"x.json"] error:nil];
            switch (mode) {
                case InputModeFileToJSON:
                case InputModeResourcesToJSON: {
                    NSData *data = [charTree json];
                    printf("%s\n", data.bytes);
                    break;
                }
                case InputModeResourcesToXML:
                case InputModeFileToXML: {
                    NSXMLDocument *doc = makeGraphML(charTree);
                    printf("%s\n", [doc XMLData].bytes);
                    break;
                }
                default: // InputModeResourcesToRandom, InputModeFileToRandom
                    for (NSInteger i = genCount; i--; ) {
                        NSString *s = [charTree randomWord];
                        printf("%s\n", [s cStringUsingEncoding:NSUTF8StringEncoding]);//NSASCIIStringEncoding]);
                    }
                    break;
            }
            
        }
    }
    return 0;
}
