//
//  YLModel.m
//  YLLabel
//
//  Created by 苏沫离 on 2020/8/19.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import "YLModel.h"

NSAttributedStringKey const kYLAttachmentAttributeName = @"com.yl.attachment";

@implementation YLAttachment

- (NSDictionary *)dictionaryRepresentation{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.url forKey:@"url"];
    [mutableDict setValue:self.title forKey:@"title"];
    if (self.image) {
        [mutableDict setValue:self.image forKey:@"image"];
        [mutableDict setValue:[NSValue valueWithCGRect:self.imageFrame] forKey:@"imageFrame"];
    }
    return [NSDictionary dictionaryWithDictionary:mutableDict];
}

- (NSString *)description {
    NSString *type = self.image ? @"图片" : self.title;
    return [NSString stringWithFormat:@"%@ : %@",type, [self dictionaryRepresentation]];
}


@end




@implementation YLPageModel

- (void)dealloc{
    if (_frameRef) {
        CFRelease(_frameRef);
    }
}

@end
