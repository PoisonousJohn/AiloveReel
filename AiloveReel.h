//
// Created by JohnPoison <truefiresnake@gmail.com> on 3/30/13.




#import <Foundation/Foundation.h>
#import "cocos2d.h"

typedef enum {
    StateIdle,
    StateSpinning,
    StateWillStop,
    StateSlowingDown,
    StateStopped,
} AiloveReelState;


@interface AiloveReel : CCNode {

    int meshPointsCount;

    CCTexture2D *texture;

    ccV3F_C4B_T2F *meshPoints;
    ccVertex2F *textureCoordinates;
    GLuint *indices;

    GLuint buffersVBO_[2];

    BOOL isDirty;

    AiloveReelState state;

    float velocity;
    NSUInteger stopIndex;
    float amortizationVelocity;

    NSUInteger lastSymbolIndex;
    // symbols in a column minus one cycled symbol
    NSUInteger symbolsPerTexture;
    // index of centered symbol
    NSUInteger currentSymbolReelIndex;
}

@property (nonatomic, strong) CCTexture2D *texture;


@property (nonatomic, assign) CGSize symbolSize;
@property (nonatomic, assign) float reelHeight;
@property (nonatomic, assign) NSUInteger polygonsCount;
@property (nonatomic, assign) NSUInteger symbolsCount;
@property (nonatomic, assign) float offset;
@property (nonatomic, assign) NSUInteger textureColumn;
@property (nonatomic, assign) ccBlendFunc blendFunc;
@property (nonatomic, assign) float amortization;
@property (nonatomic, copy) void (^idleBlock)();
@property (nonatomic, copy) void (^spinningBlock)();
@property (nonatomic, copy) void (^stopBlock)();
@property (nonatomic, copy) void (^slowingDownBlock)();


-(id) initWithPoints: (NSArray *) polygonPoints andTexture: (CCTexture2D *) fillTexture;

- (id)initWithTexture:(CCTexture2D *)aTexture polygonsCount:(NSUInteger)polygonsCount symbolSize:(CGSize)symbolSize symbolsCount:(NSUInteger)symbolsCount reelHeight:(float)reelHeight;

-(void) setPoints: (NSArray *) points;

-(void) spinWithVelocity: (float)v;
-(float) velocity;
-(void) stopAtIndex: (NSUInteger) index;


@end