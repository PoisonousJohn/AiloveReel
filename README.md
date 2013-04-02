AiloveReel
==========

Cocos2d implementation of 3d slot machine reel

Usage example

```objective-c
    AiloveReel *reelLocal = [AiloveReel reelWithTexture: texture polygonsCount: 19 symbolSize:CGSizeMake(32, 32) symbolsCount: 3 reelHeight: 32*2 ];
    reelLocal.position = ccp(50, 100);
    reelLocal.spinningBlock = ^{
        reelLocal.textureColumn = 2;
    };
    reelLocal.slowingDownBlock = ^{
        reelLocal.textureColumn = 0;
    };
    [self addChild:reelLocal];
    [reelLocal spinWithVelocity:200];
    [reelLocal runAction:[CCSequence actionOne:[CCDelayTime actionWithDuration:3.5] two:[CCCallBlock actionWithBlock:^{
        [reelLocal stopAtIndex:i];
    }]]];
```
