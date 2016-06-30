//
//  CharTreeLayer.m
//  Worderer
//
//  Created by Danila Parkhomenko on 30/06/16.
//  Copyright © 2016 Itheme. All rights reserved.
//

#import "CharTreeLayer.h"
const char wordStartChar = 13;

@interface CharTreeLayer ()

@property (nonatomic, assign) unichar c;
@property (nonatomic, assign) int occurances;
@property (nonatomic, assign) int totalSubTreeOccurances;
@property (nonatomic, strong) NSMutableArray *subTree;

- (id)initWithChar:(unichar) ch subtree:(NSMutableArray *)subTree;
- (id)initWithChar:(unichar) ch;
- (CharTreeLayer *) addSubChar:(unichar) ch;
- (CharTreeLayer *) uniformlyRandomSubTree;
- (CharTreeLayer *) layerByC:(unichar) ch;

@end

@implementation CharTreeLayer

+ (CharTreeLayer *)createWithSampleWords:(NSArray<NSString *> *)words
{
    NSMutableArray *wordStartLayerArray = [NSMutableArray array];
    CharTreeLayer *charTree = [[CharTreeLayer alloc] initWithChar:wordStartChar
                                                          subtree:wordStartLayerArray];
    CharTreeLayer *l0 = nil;
    CharTreeLayer *l1 = nil;
    CharTreeLayer *l2 = nil;
    CharTreeLayer *l3 = nil;
    for (NSString *word in words) {
        l0 = l1 = l2 = l3 = nil;
        for (NSInteger i = 0; i < word.length; i++) {
            unichar c = [word characterAtIndex:i];
            //[word getCharacters:&c range:[word rangeOfComposedCharacterSequenceAtIndex:i]];
            if (l0 == nil) {
                l0 = [charTree addSubChar:c];
            } else {
                if (l1 == nil) {
                    l1 = [l0 addSubChar:c];
                } else {
                    if (l2 == nil) {
                        l2 = [l1 addSubChar:c];
                    } else {
                        l3 = [l2 addSubChar:c];
                        break;
                    }
                }
            }
        }
    }
    for (NSString *word in words) {
        l0 = l1 = l2 = l3 = nil;
        for (NSInteger i = 0; i < word.length; i++) {
            unichar c = [word characterAtIndex:i];
            if (l0 == nil) {
                l0 = [charTree addSubChar:c];
            } else {
                if (l1 == nil) {
                    l1 = [l0 addSubChar:c];
                } else {
                    if (l2 == nil) {
                        l2 = [l1 addSubChar:c];
                    } else {
                        l3 = [l2 addSubChar:c];
                        l0 = [l0 layerByC:l1.c];
                        l1 = [l1 layerByC:l2.c];
                        l2 = [l2 layerByC:l3.c];
                    }
                }
            }
        }
        if (l0 == nil) continue;
        if (l1) {
            if (l2) {
                if (l3) {
                    [l3 addSubChar:0];
                } else {
                    [l2 addSubChar:0];
                }
            } else {
                [l1 addSubChar:0];
            }
        } else {
            [l0 addSubChar:0];
        }
    }
    return charTree;
}

+ (CharTreeLayer *)createWithTestData {
    NSDictionary *bulk = [NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"TestData" withExtension:@"plist"]];
    NSArray <NSString *> *words = [[bulk[@"strings"] lowercaseString] componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]];
    return [CharTreeLayer createWithSampleWords:words];
}

- (id)initWithChar:(unichar) ch {
    return [self initWithChar:ch subtree:[NSMutableArray array]];
}

- (id)initWithChar:(unichar) ch subtree:(NSMutableArray *)subTree {
    if (self = [super init]) {
        self.c = ch;
        self.occurances = 1;
        self.subTree = subTree;
    }
    return self;
}

- (CharTreeLayer *) addSubChar:(unichar) ch
{
    self.totalSubTreeOccurances++;
    for (NSInteger i = 0; i < self.subTree.count; i++) {
        CharTreeLayer *layer = self.subTree[i];
        if (layer.c < ch) {
            continue;
        }
        if (layer.c == ch) {
            layer.occurances++;
            return layer;
        }
        if (layer.c > ch) {
            CharTreeLayer *result = [[CharTreeLayer alloc] initWithChar:ch];
            [self.subTree insertObject:result atIndex:i];
            return result;
        }
    }
    CharTreeLayer *result = [[CharTreeLayer alloc] initWithChar:ch];
    [self.subTree addObject:result];
    return result;
}

- (CharTreeLayer *) uniformlyRandomSubTree {
    int r = arc4random_uniform(self.totalSubTreeOccurances);
    for (CharTreeLayer *l in self.subTree) {
        r -= l.occurances;
        if (r > 0) continue;
        return l;
    }
    return nil;
}

- (CharTreeLayer *) layerByC:(unichar)ch {
    for (CharTreeLayer *l in self.subTree) {
        if (l.c < ch) continue;
        if (l.c == ch) return l;
        break;
    }
    return [self uniformlyRandomSubTree];
}

- (id)initWithDict:(NSDictionary *)dict
{
    if (self = [super init]) {
        self.c = [dict[@"c"] characterAtIndex:0];
        NSNumber *n = dict[@"n"];
        if (n) {
            self.occurances = [n intValue];
        } else {
            self.occurances = 1;
        }
        n = dict[@"t"];
        if (n) {
            self.totalSubTreeOccurances = [n intValue];
        } else {
            self.totalSubTreeOccurances = 1;
        }
        self.subTree = [NSMutableArray array];
        for (NSDictionary *d in dict[@"s"]) {
            [self.subTree addObject:[[CharTreeLayer alloc] initWithDict:d]];
        }

    }
    return self;
}

+ (CharTreeLayer *)createFromJSON:(NSData *)data error:(NSError **)error;
{
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    if (dict) {
        return [[CharTreeLayer alloc] initWithDict:dict];
    }
    return nil;
}

- (NSString *)randomWord
{
    unichar cString[500];
    NSInteger i = 0;
    CharTreeLayer *l0 = [self uniformlyRandomSubTree];
    int minLength = 3+arc4random_uniform(5);
    cString[i++] = l0.c;
    CharTreeLayer *l1 = [l0 uniformlyRandomSubTree];
    cString[i++] = l1.c;
    NSInteger wrongCutTimes = 0;
    while (l1.c) {
        CharTreeLayer *l2 = [l1 uniformlyRandomSubTree];
        if (l2 == nil) {
            l2 = [l0 uniformlyRandomSubTree]; // actually not needed
        }
        if (wrongCutTimes > 30) {
            return [self randomWord];
        }
        if ((l2.c == 0) && (i < minLength)) {
            l1 = [l0 uniformlyRandomSubTree];
            wrongCutTimes++;
            continue;
        }
        cString[i++] = l2.c;
        if (l2.c == 0) {
            break;
        }
        l0 = [self layerByC:l0.c];
        l1 = [l0 layerByC:l1.c];
        l2 = [l1 layerByC:l2.c];
        
        l0 = l1;
        l1 = l2;
    }
    if (i > 10) {
        return [self randomWord];
    }
    return [NSString stringWithCharacters:cString length:i];

}

- (NSMutableDictionary *)jsonDict
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.c) {
        dict[@"c"] = [NSString stringWithFormat:@"%c", self.c];
    }
    if (self.occurances > 1) {
        dict[@"n"] = @(self.occurances);
    }
    if (self.totalSubTreeOccurances > 1) {
        dict[@"t"] = @(self.totalSubTreeOccurances);
    }
    NSMutableArray *subs = [NSMutableArray array];
    for (CharTreeLayer *sub in self.subTree) {
        [subs addObject:[sub jsonDict]];
    }
    if (subs.count > 0) {
        dict[@"s"] = subs;
    }
    return dict;
}

- (NSData *)json {
    NSMutableDictionary *dict = [self jsonDict];
    NSMutableData *data = [[NSJSONSerialization dataWithJSONObject:dict
                                                           options:0//NSJSONWritingPrettyPrinted
                                                             error:nil] mutableCopy];
    char zero = 0;
    [data appendBytes:&zero length:1];
    return data;

    //return [NSString stringWithCharacters:[data bytes] length:data.length];
}

@end
