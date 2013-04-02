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


// symbol size in points
@property (nonatomic, assign) CGSize symbolSize;
// reel height in points
@property (nonatomic, assign) float reelHeight;
// how many polygons will be used for reel
@property (nonatomic, assign) NSUInteger polygonsCount;
// how many symbols should be visible on this reel
@property (nonatomic, assign) NSUInteger symbolsCount;
// default: 0. Texture column y-offset from top
@property (nonatomic, assign) float offset;
// default: 0. Texture column x-offset (e.g. you can use different columns for displaying normal or blurry symbols)
@property (nonatomic, assign) NSUInteger textureColumn;
@property (nonatomic, assign) ccBlendFunc blendFunc;
// default: 0.3f. Amortization speed factor (determines how fast reel will stop its spin)
@property (nonatomic, assign) float amortization;
@property (nonatomic, copy) void (^idleBlock)();
@property (nonatomic, copy) void (^spinningBlock)();
@property (nonatomic, copy) void (^stopBlock)();
@property (nonatomic, copy) void (^slowingDownBlock)();


/**
* @param aTexture           texture with symbols
* @param polygonsCount      how many polygons will be used to display a reel
* @param symbolSize         CGSize of a single symbol in points
* @param symbolsCount       visible symbols on a reel (make this odd)
* @param reelHeight         reel height in points
*/
+(id) reelWithTexture:(CCTexture2D *)aTexture polygonsCount:(NSUInteger)polygonsCount symbolSize:(CGSize)symbolSize symbolsCount:(NSUInteger)symbolsCount reelHeight:(float)reelHeight;
-(id) initWithTexture:(CCTexture2D *)aTexture polygonsCount:(NSUInteger)polygonsCount symbolSize:(CGSize)symbolSize symbolsCount:(NSUInteger)symbolsCount reelHeight:(float)reelHeight;
-(id) initWithPoints: (NSArray *) polygonPoints andTexture: (CCTexture2D *) fillTexture;
-(void) setPoints: (NSArray *) points;

-(void) spinWithVelocity: (float)v;
-(float) velocity;
-(void) stopAtIndex: (NSUInteger) index;


@end