//
//  YLModel.m
//  YLLabel
//
//  Created by 苏沫离 on 2020/8/19.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import "YLModel.h"


@implementation YLImage

@end


@implementation YLWeb

@end

@implementation YLPageModel

- (void)dealloc{
    if (_frameRef) {
        CFRelease(_frameRef);
    }
}

@end
