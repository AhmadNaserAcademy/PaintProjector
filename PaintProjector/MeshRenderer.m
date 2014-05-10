//
//  MeshRenderer.m
//  PaintProjector
//
//  Created by 胡 文杰 on 2/2/14.
//  Copyright (c) 2014 WenjiHu. All rights reserved.
//

#import "MeshRenderer.h"

@implementation MeshRenderer
- (id)initWithMeshFilter:(MeshFilter*)meshFilter{
    self = [super init];
    if (self != nil) {
        _meshFilter = meshFilter;
        
    }
    return  self;
}

- (void)render{
    [GLWrapper.current bindVertexArrayOES:self.meshFilter.mesh.vertexArray];
    size_t offset = 0;
    
    size_t subMeshCount = self.meshFilter.mesh.subMeshTriCounts.count;
    for (size_t i = 0; i < subMeshCount; ++i) {
        Material *material = nil;
        if (i < self.materials.count) {
            material = [self.materials objectAtIndex:i];
        }

        if (!material) {
            material = [self.sharedMaterials objectAtIndex:i];
            if (!material) {
                continue;
            }
        }

        NSNumber *subMeshTriCount = [self.meshFilter.mesh.subMeshTriCounts objectAtIndex:i];
        if (!subMeshTriCount) {
            continue;
        }
        
        if (material.transparent) {
            glDepthMask(GL_FALSE);
        }
        
//        if (material.effect != nil) {
//            [material.effect prepareToDraw];
//        }
//        else{
            [GLWrapper.current useProgram:material.shader.program uniformBlock:^{
            }];
            if (material.mainTexture.texID) {
                [GLWrapper.current activeTexSlot:GL_TEXTURE0 bindTexture:material.mainTexture.texID];
            }
//        }
        
        //TODO: use other texture
        [self.delegate willRenderSubMeshAtIndex:i];
        
        //    size_t triangleCount = data.length / (sizeof(short) * 3);
        size_t indiceCount = subMeshTriCount.intValue * 3;
        
        GLvoid *ptr = (GLvoid*)(offset * sizeof(short));
        
        //test
        if (self.meshFilter.mesh.topology == Triangles) {
            glDrawElements(GL_TRIANGLES, indiceCount, GL_UNSIGNED_SHORT, ptr);
        }

        offset += indiceCount;
        
        if (material.transparent) {
            glDepthMask(GL_TRUE);
        }
    }
}

- (id)copyWithZone:(NSZone *)zone{
    MeshRenderer *renderer = (MeshRenderer *)[super copyWithZone:zone];
    renderer.meshFilter = [self.meshFilter copy];
    return  renderer;
}
@end