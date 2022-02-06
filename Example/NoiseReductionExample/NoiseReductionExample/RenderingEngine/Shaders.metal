//
//  Shaders.metal
//  RosaKitExample
//
//  Created by Dmytro Hrebeniuk on 12/6/17.
//  Copyright © 2017 dmytro. All rights reserved.
//

#include <metal_stdlib>
#include "CommonUtils.h"
using namespace metal;

typedef struct {
	float4 renderedCoordinate [[position]];
	float2 textureCoordinate;
} TextureMappingVertex;

vertex TextureMappingVertex mapTexture(unsigned int vertex_id [[ vertex_id ]]) {
	float4x4 renderedCoordinates = float4x4(float4( -1.0, -1.0, 0.0, 1.0 ),	  /// (x, y, depth, W)
											float4(  1.0, -1.0, 0.0, 1.0 ),
											float4( -1.0,  1.0, 0.0, 1.0 ),
											float4(  1.0,  1.0, 0.0, 1.0 ));
    
	float4x2 textureCoordinates = float4x2(float2( 0.0, 1.0 ), /// (x, y)
										   float2( 1.0, 1.0 ),
										   float2( 0.0, 0.0 ),
										   float2( 1.0, 0.0 ));
	TextureMappingVertex outVertex;
	outVertex.renderedCoordinate = renderedCoordinates[vertex_id];
	outVertex.textureCoordinate = textureCoordinates[vertex_id];
	
	return outVertex;
}

fragment half4 displayBackTexture(TextureMappingVertex mappingVertex [[ stage_in ]],
							  texture2d<float, access::sample> luminanceTexture [[ texture(0) ]]) {
	constexpr sampler s(address::clamp_to_edge, filter::linear);

    float2 coords = mappingVertex.textureCoordinate;
    coords.x = coords.x;
	float4 luminance = luminanceTexture.sample(s, float2(1.0 - coords.y, coords.x));
	
    float hue = luminance.x*3.0;
    
    float3 rgb = hsv2rgb(float3(hue, 1.0, min(10.0*pow(luminance.x, 2.0), 1.0)));
	
	return half4(float4(rgb, 1.0));
}

