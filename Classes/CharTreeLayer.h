//
//  CharTreeLayer.h
//  Worderer
//
//  Created by Danila Parkhomenko on 30/06/16.
//  Copyright © 2016 Itheme. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CharTreeLayer : NSObject

+ (CharTreeLayer *) createWithSampleWords:(NSArray <NSString *> *)words;
+ (CharTreeLayer *) createWithTestData;
+ (CharTreeLayer *) createFromJSON:(NSData *)data error:(NSError **)error;

- (NSString *)randomWord;
- (NSData *)json;

@end
