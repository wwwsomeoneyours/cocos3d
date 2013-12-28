/*
 * CC3ShaderContext.m
 *
 * cocos3d 2.0.0
 * Author: Bill Hollings
 * Copyright (c) 2011-2013 The Brenwill Workshop Ltd. All rights reserved.
 * http://www.brenwill.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * http://en.wikipedia.org/wiki/MIT_License
 * 
 * See header file CC3ShaderContext.h for full API documentation.
 */

#import "CC3ShaderContext.h"
#import "CC3ShaderMatcher.h"


#pragma mark -
#pragma mark CC3ShaderContext

@implementation CC3ShaderContext

@synthesize shouldEnforceCustomOverrides=_shouldEnforceCustomOverrides;
@synthesize shouldEnforceVertexAttributes=_shouldEnforceVertexAttributes;

-(CC3ShaderProgram*) program { return _program; }

-(void) setProgram:(CC3ShaderProgram*) program {
	if (program == _program) return;
	_program = program;
	_pureColorProgram = nil;
	[self removeAllOverrides];
}

-(CC3ShaderProgram*) pureColorProgram {
	if ( !_pureColorProgram )
		self.pureColorProgram = [CC3ShaderProgram.shaderMatcher pureColorProgramMatching: self.program];
	return _pureColorProgram;
}

-(void) setPureColorProgram:(CC3ShaderProgram*) program {
	if (program == _pureColorProgram) return;
	_pureColorProgram = program;
}


#pragma mark Variables

-(CC3GLSLUniform*) uniformOverrideNamed: (NSString*) name {
	CC3GLSLUniform* rtnVar = [_uniformsByName objectForKey: name];
	return rtnVar ? rtnVar : [self addUniformOverrideFor: [_program uniformNamed: name]];
}

-(CC3GLSLUniform*) uniformOverrideForSemantic: (GLenum) semantic at: (GLuint) semanticIndex {
	for (CC3GLSLUniform* var in _uniforms)
		if (var.semantic == semantic && var.semanticIndex == semanticIndex)
			return var;
	return [self addUniformOverrideFor: [_program uniformForSemantic: semantic at: semanticIndex]];
}

-(CC3GLSLUniform*) uniformOverrideForSemantic: (GLenum) semantic {
	return [self uniformOverrideForSemantic: semantic at: 0];
}

-(CC3GLSLUniform*) uniformOverrideAtLocation: (GLint) uniformLocation {
	for (CC3GLSLUniform* var in _uniforms) if (var.location == uniformLocation) return var;
	return [self addUniformOverrideFor: [_program uniformAtLocation: uniformLocation]];
}

-(CC3GLSLUniform*)	addUniformOverrideFor: (CC3GLSLUniform*) uniform {
	if( !uniform ) return nil;		// Don't add override for non-existant uniform
	
	if ( !_uniforms ) _uniforms = [NSMutableArray array];
	if ( !_uniformsByName ) _uniformsByName = [NSMutableDictionary new];

	CC3GLSLUniform* newUniform = [uniform copyAsClass: CC3GLSLUniformOverride.class];
	[_uniformsByName setObject: newUniform forKey: newUniform.name];
	[_uniforms addObject: newUniform];
	return newUniform;
}

-(void)	removeUniformOverride: (CC3GLSLUniform*) uniform {
	[_uniforms removeObjectIdenticalTo: uniform];
	[_uniformsByName removeObjectForKey: uniform.name];
	CC3Assert(_uniforms.count == _uniformsByName.count,
			  @"%@ was not completely removed from %@", uniform, self);
	if (_uniforms.count == 0) [self removeAllOverrides];	// Remove empty collections
}

-(void) removeAllOverrides {
	_uniformsByName = nil;
	_uniforms = nil;
}


#pragma mark Drawing

// Match based on location
-(BOOL) populateUniform: (CC3GLSLUniform*) uniform withVisitor: (CC3NodeDrawingVisitor*) visitor {
	
	// If the program is not the mine, don't look up the override.
	CC3ShaderProgram* uProg = uniform.program;
	if ( !(uProg == _program || uProg == _pureColorProgram) ) return NO;

	// Find the matching uniform override by comparing locations
	// and set the value of the incoming uniform from it
	for (CC3GLSLUniform* var in _uniforms) {
		if (var.location == uniform.location) {
			[uniform setValueFromUniform: var];
			return YES;
		}
	}

	// If the semantic is unknown, and no override was found, return whether a default is okay
	if (uniform.semantic == kCC3SemanticNone) return !_shouldEnforceCustomOverrides;
	
	return NO;
}


#pragma mark Allocation and initialization

-(id) init {
	if ( (self = [super init]) ) {
		_program = nil;
		_pureColorProgram = nil;
		_uniforms = nil;
		_uniformsByName = nil;
		_shouldEnforceCustomOverrides = YES;
		_shouldEnforceVertexAttributes = YES;
	}
	return self;
}

-(id) initForProgram: (CC3ShaderProgram*) program {
	if ( (self = [self init]) ) {
		self.program = program;			// will clear overrides
	}
	return self;
}

+(id) context { return [[self alloc] init]; }

+(id) contextForProgram: (CC3ShaderProgram*) program {
	return [[self alloc] initForProgram: program];
}

-(NSString*) description {
	return [NSString stringWithFormat: @"%@ for program %@", self.class, _program];
}

-(NSString*) fullDescription {
	return [NSString stringWithFormat: @"%@ for program %@", self.class, _program.fullDescription];
}

@end