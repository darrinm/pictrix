// Copyright 2011 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS-IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
package imagine.imageOperations
{
	import flash.display.BlendMode;

	// This is a nested image operation that first desaturates, then applies a color tint.
	// Set _bAutoLevels to true and the tint will expand to fill the range.
	// Tint works like a Color overlay in photoshop - it tries to maintain the
	// same distance between R,G,and B components, while maintaining luminosity.
	// At the upper and lower ends, clipping will occur.
	[RemoteClass]
	public class LocalContrastImageOperation extends NestedImageOperation
	{
		protected var _opBlur:BlurImageOperation;
		protected var _opMult1:MultiplyColorMatrixImageOperation;
		protected var _opMult2:MultiplyColorMatrixImageOperation;
		
		public function set Radius(nRadius:Number): void {
			_opBlur.xblur = nRadius;
			_opBlur.yblur = nRadius;
		}
		
		public function set dynamicRadiusCachePriority(n:Number): void {
			_opBlur.dynamicParamsCachePriority = n;
		}

		public function set Strength(nStrength:Number): void {
			_opMult1.Multiplier = nStrength;
			_opMult2.Multiplier = nStrength;
		}

		public function set dynamicStrengthCachePriority(n:Number): void {
			_opMult2.dynamicParamsCachePriority = n;
		}

		public function LocalContrastImageOperation(nRadius:Number=1, nStrength:Number=1)
		{
			var opNested:NestedImageOperation;
			
			children = new Array();
			
			// Remember the original
			children.push(new imagine.imageOperations.SetVar("orig"));

			// Blur it
			_opBlur = new BlurImageOperation(NaN, nRadius, nRadius, 3);
			children.push(_opBlur);

			// Remember the blurred version
			children.push(new imagine.imageOperations.SetVar("blur"));

			// Now set output = orig + ((orig - blur) * mult)
			children.push(new GetVarImageOperation("orig"));
			{
				// Create a nested op to calculate ((orig - blur) * mult)
				opNested = new NestedImageOperation();
				opNested.children = new Array();
				// Start with orig (coming in)
				// Subtract blur
				opNested.children.push(new GetVarImageOperation("blur", flash.display.BlendMode.SUBTRACT));
				// Multiply by strength
				_opMult1 = new MultiplyColorMatrixImageOperation(nStrength);
				opNested.children.push(_opMult1); // UNDONE: Consider using a colortransform to simplify (modify BlendedImageOp to suppor this)
				
				// Subtract from the output
				opNested.BlendMode = flash.display.BlendMode.ADD;
			}
			children.push(opNested);
			
			// Now set output = output - ((blur - orig) * mult)
			{
				// Create a nested op to calculate ((blur - orig) * mult)
				opNested = new NestedImageOperation();
				opNested.children = new Array();
				// Start with blur
				opNested.children.push(new GetVarImageOperation("blur"));
				// Subtract orig
				opNested.children.push(new GetVarImageOperation("orig", flash.display.BlendMode.SUBTRACT));
				// Multiply by strength
				_opMult2 = new MultiplyColorMatrixImageOperation(nStrength);
				opNested.children.push(_opMult2); // UNDONE: Consider using a colortransform to simplify (modify BlendedImageOp to suppor this)
				
				// add to the output
				opNested.BlendMode = flash.display.BlendMode.SUBTRACT;
			}
			children.push(opNested);
		}
	}
}