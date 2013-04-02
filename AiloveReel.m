//
// Created by JohnPoison <truefiresnake@gmail.com> on 3/30/13.




#import "AiloveReel.h"

static const int VertexSize = sizeof(ccV3F_C4B_T2F);

@implementation AiloveReel {

}

+ (id)reelWithTexture:(CCTexture2D *)aTexture polygonsCount:(NSUInteger)polygonsCount symbolSize:(CGSize)symbolSize symbolsCount:(NSUInteger)symbolsCount reelHeight:(float)reelHeight {
    return [[[AiloveReel alloc] initWithTexture: aTexture polygonsCount: polygonsCount symbolSize: symbolSize symbolsCount: symbolsCount reelHeight: reelHeight] autorelease];
}


- (id)initWithTexture:(CCTexture2D *)aTexture polygonsCount:(NSUInteger)polygonsCount symbolSize:(CGSize)symbolSize symbolsCount:(NSUInteger)symbolsCount reelHeight:(float)reelHeight {
    self.texture = aTexture;
    self.symbolSize = symbolSize;
    self.symbolsCount = symbolsCount;
    self.reelHeight = reelHeight;
    self.polygonsCount = polygonsCount;
    self.textureColumn = 0;
    self.amortization = 0.3f;
    lastSymbolIndex = 0;
    _offset = 0;

    NSArray *points = [self meshPoints:polygonsCount];

    return [self initWithPoints: points andTexture: aTexture];

}

-(id) initWithPoints: (NSArray *) polygonPoints andTexture: (CCTexture2D *) fillTexture {
    if( (self=[super init])) {

        [self setPoints:polygonPoints];
        [self setupIndices];

        self.texture = fillTexture;

        self.shaderProgram = [[CCShaderCache sharedShaderCache] programForKey:kCCShader_PositionTexture];

        glGenBuffers(2, &buffersVBO_[0]);
    }

    return self;
}


-(NSArray *) meshPoints: (NSUInteger) segmentsCount {

    float radius = self.reelHeight / 2;
    float alphaStep = 180.f / (float)segmentsCount;

    NSMutableArray *points = [NSMutableArray array];
    NSMutableArray *rightPoints= [NSMutableArray array];

    float alpha = -90;
    for (int i = 0; i < segmentsCount; i++) {
        float y = sin(CC_DEGREES_TO_RADIANS(alpha)) * radius;
        float nextY = sin(CC_DEGREES_TO_RADIANS(alpha+alphaStep)) * radius;
        // y shouldn't be in minus range, so we'll add a half height
        y += self.reelHeight / 2;
        nextY += self.reelHeight / 2;

        CGPoint leftPoint = ccp(0, y);
        CGPoint rightPoint = ccp(self.symbolSize.width, y);

        [points addObject:[NSValue valueWithCGPoint:leftPoint]];
        [points addObject:[NSValue valueWithCGPoint:rightPoint]];

        leftPoint = ccp(0, nextY);
        rightPoint = ccp(self.symbolSize.width, nextY);

        [points addObject:[NSValue valueWithCGPoint:leftPoint]];
        [points addObject:[NSValue valueWithCGPoint:rightPoint]];

        alpha +=alphaStep;
    }

    return points;
}

-(void) setPoints: (NSArray *) points {
    if (meshPoints)
        free(meshPoints);
    if (textureCoordinates)
        free(textureCoordinates);


    meshPointsCount = (int)[points count];
    meshPoints = (ccV3F_C4B_T2F *) malloc(sizeof(ccV3F_C4B_T2F) * meshPointsCount);

    for (int i = 0; i < meshPointsCount; i++) {

#ifdef __CC_PLATFORM_IOS
        CGPoint vert = [[points objectAtIndex:i] CGPointValue];
#else
        CGPoint vert = [[points objectAtIndex:i] pointValue];
#endif
        ccV3F_C4B_T2F vertex;
        vertex.vertices = (ccVertex3F) { vert.x, vert.y, 0 };
        meshPoints[i] = vertex;
    }

    isDirty = YES;
}

- (void)setTextureColumn:(NSUInteger)textureColumn {
    _textureColumn = textureColumn;
    isDirty = YES;
}

-(void) calculateTextureCoordinates {

    float visibleTextureHeight = self.symbolSize.height * CC_CONTENT_SCALE_FACTOR() * self.symbolsCount;
    float unscaledSpriteHeight = visibleTextureHeight / self.polygonsCount;

    float offset = [self normalizedOffset];

    float normalizedXLeft = self.textureColumn * self.symbolSize.width * CC_CONTENT_SCALE_FACTOR() / self.texture.pixelsWide;
    float normalizedXRight = (self.textureColumn+1) * self.symbolSize.width * CC_CONTENT_SCALE_FACTOR() / self.texture.pixelsWide;

    for (int i = 0; i <= self.polygonsCount; i++) {
        float pixelsYOffset = unscaledSpriteHeight * i + offset ;
        pixelsYOffset = fmodf(pixelsYOffset, (float)self.texture.pixelsHigh - self.symbolSize.height * CC_CONTENT_SCALE_FACTOR());
        float normalizedY = pixelsYOffset / (float)self.texture.pixelsHigh;
        float normalizedYBottom = (pixelsYOffset + unscaledSpriteHeight) / (float)self.texture.pixelsHigh;

//        NSLog(@"normY: %5.5f", normalizedY);
//        NSLog(@"normYBottom: %5.5f", normalizedYBottom);

        ccTex2F tl = (ccTex2F){normalizedXLeft, normalizedY};
        ccTex2F tr = (ccTex2F){normalizedXRight, normalizedY};
        ccTex2F bl = (ccTex2F){normalizedXLeft, normalizedYBottom};
        ccTex2F br = (ccTex2F){normalizedXRight, normalizedYBottom};

        int baseIndex = meshPointsCount -1-i*4;

        meshPoints[baseIndex].texCoords     = tl;
        meshPoints[baseIndex-1].texCoords   = tr;
        meshPoints[baseIndex-2].texCoords   = bl;
        meshPoints[baseIndex-3].texCoords   = br;

    }
}

-(void) setupIndices {
    // 6 indices per polygon
    if (indices)
        free(indices);

    indices = malloc(sizeof(GLuint) * self.polygonsCount * 6);

    for (int i = 0; i < self.polygonsCount; i++) {
        indices[i*6+0] = (GLuint)i*4+0;
        indices[i*6+1] = (GLuint)i*4+1;
        indices[i*6+2] = (GLuint)i*4+2;

        indices[i*6+3] = (GLuint)i*4+1;
        indices[i*6+4] = (GLuint)i*4+2;
        indices[i*6+5] = (GLuint)i*4+3;
    }

    isDirty = YES;
}

- (void)setOffset:(float)offset {
    _offset = offset;
    isDirty = YES;
    uint currentSymbol = [self indexOfCurrentSymbol];
    if (currentSymbol != lastSymbolIndex) {
        [self symbolChangedFrom: lastSymbolIndex to: currentSymbol];
//        NSLog(@"symbol changed from %d to %d", lastSymbolIndex, currentSymbol);
        lastSymbolIndex = currentSymbol;
    }
}

- (void) bindData {

    if (isDirty) {

        [self calculateTextureCoordinates];
        [self setupIndices];


        glBindBuffer(GL_ARRAY_BUFFER, buffersVBO_[0]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(meshPoints[0]) * meshPointsCount, meshPoints, GL_DYNAMIC_DRAW);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffersVBO_[1]);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLuint) * 6 * self.polygonsCount, indices, GL_DYNAMIC_DRAW);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

        isDirty = NO;
    }

}

-(void) draw {
    CC_NODE_DRAW_SETUP();

    ccGLBindTexture2D( self.texture.name );

    [self bindData];

    ccGLBlendFunc( self.blendFunc.src, self.blendFunc.dst);

    // enable array buffer
    glBindBuffer(GL_ARRAY_BUFFER, buffersVBO_[0]);

    // vertex attribs
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position | kCCVertexAttribFlag_TexCoords );
    glVertexAttribPointer(kCCVertexAttrib_Position, 3, GL_FLOAT, GL_FALSE, VertexSize, (GLvoid*) offsetof( ccV3F_C4B_T2F, vertices ));
    glVertexAttribPointer(kCCVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, VertexSize,  (GLvoid*) offsetof( ccV3F_C4B_T2F, texCoords));

    // reset vertex buffer
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffersVBO_[1]);
    glDrawElements(GL_TRIANGLE_STRIP, 6 * self.polygonsCount, GL_UNSIGNED_INT, 0);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

    CHECK_GL_ERROR_DEBUG();

    CC_INCREMENT_GL_DRAWS(1);
}

-(void) updateBlendFunc {
    ccBlendFunc blendFunc;
    // it's possible to have an untextured sprite
    if( !texture || ! [texture hasPremultipliedAlpha] ) {
        blendFunc.src = GL_SRC_ALPHA;
        blendFunc.dst = GL_ONE_MINUS_SRC_ALPHA;
        //[self setOpacityModifyRGB:NO];
    } else {
        blendFunc.src = CC_BLEND_SRC;
        blendFunc.dst = CC_BLEND_DST;
        //[self setOpacityModifyRGB:YES];
    }

    self.blendFunc = blendFunc;
}

-(void) setTexture:(CCTexture2D *) texture2D {

    // accept texture==nil as argument
    NSAssert( !texture || [texture isKindOfClass:[CCTexture2D class]], @"setTexture expects a CCTexture2D. Invalid argument");

    texture = texture2D;

    float normalizedHeight = self.symbolSize.height * CC_CONTENT_SCALE_FACTOR();
    symbolsPerTexture = (uint)((self.texture.pixelsHigh - normalizedHeight) / normalizedHeight);
    currentSymbolReelIndex = (uint)ceilf((float)self.symbolsCount / 2.f) - 1;

    [self updateBlendFunc];

    isDirty = YES;
}

-(CCTexture2D *) texture {
    return texture;
}

-(void) dealloc {
    if (meshPoints)
        free(meshPoints);
    if (textureCoordinates)
        free(textureCoordinates);
    if (indices)
        free(indices);

    glDeleteBuffers(2, buffersVBO_);

    self.texture = nil;
    self.spinningBlock = nil;
    self.idleBlock = nil;
    self.stopBlock = nil;
    self.slowingDownBlock = nil;

    [super dealloc];
}

- (float)velocity {
    return velocity;
}
-(float) rawOffset {
   return fmodf((self.offset * CC_CONTENT_SCALE_FACTOR()), (float)self.texture.pixelsHigh-self.symbolSize.height * CC_CONTENT_SCALE_FACTOR());
}

-(float) normalizedOffset {
    float offset = [self rawOffset];

    if (offset < 0) {
        offset = (float)self.texture.pixelsHigh-self.symbolSize.height * CC_CONTENT_SCALE_FACTOR() + offset;
    }

    return offset;
}

- (void) idle {

    state = StateIdle;
    [self unschedule:@selector(update:)];

    if (self.idleBlock)
        self.idleBlock();
}
- (void) stopAtIndex: (NSUInteger) index {
    state = StateWillStop;
    stopIndex = index % symbolsPerTexture;
}

- (void) stop {
    state = StateStopped;

    if (self.stopBlock)
        self.stopBlock();

    [self idle];
}


- (void)update: (float) dt {
    self.offset += velocity * dt;


    if (state == StateSlowingDown) {
        velocity += amortizationVelocity;
    }
}

- (float)offsetOfSymbolAtIndex: (int) index {
    int factualIndex = (index-currentSymbolReelIndex);
    if (factualIndex < 0)
        factualIndex = symbolsPerTexture + factualIndex;
    float offset = self.symbolSize.height * (float)factualIndex;

    return offset;
}

- (NSUInteger)indexOfCurrentSymbol {
    float normalizedOffset = [self normalizedOffset];
    float normalizedHeight = self.symbolSize.height * CC_CONTENT_SCALE_FACTOR();
    int index = ((int)ceil((normalizedOffset / normalizedHeight)) + currentSymbolReelIndex ) % (int)ceil(symbolsPerTexture);

    return (uint)index;
}

- (void)spinWithVelocity:(float)v {
    if(!v) return;

    velocity = -v;
    amortizationVelocity = self.amortization * v;
    state = StateSpinning;
    lastSymbolIndex = [self indexOfCurrentSymbol];
    [self schedule:@selector(update:)];

    if (self.spinningBlock)
        self.spinningBlock();
}

- (void)symbolChangedFrom: (NSUInteger) from to: (NSUInteger) to {
    if (state == StateWillStop && stopIndex == to) {
        state = StateSlowingDown;
        if (self.slowingDownBlock)
            self.slowingDownBlock();
    }

    if (state == StateSlowingDown && stopIndex == from) {
        [self stop];
        self.offset = [self offsetOfSymbolAtIndex: stopIndex];
    }
}

@end