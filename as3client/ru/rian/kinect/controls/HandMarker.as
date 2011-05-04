package ru.rian.kinect.controls
{
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.InterpolationMethod;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	
	public class HandMarker extends Sprite {
		
		private static const RADIUS:Number = 75;
		
		public function HandMarker()
		{
			super();
			
			drawBody();
			
			blendMode = BlendMode.ADD;
		}
		
		protected function drawBody():void
		{
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(2*RADIUS,2*RADIUS,Math.PI/4,-RADIUS,-RADIUS);
			
			graphics.beginGradientFill(GradientType.LINEAR, [0x80FF80, 0x80FF80], [0.75, 0.5], [0x00, 0xFF], matrix, null, InterpolationMethod.LINEAR_RGB);
			graphics.drawCircle(0, 0, RADIUS+5);
			graphics.drawCircle(0, 0, RADIUS-5);
			graphics.endFill();
		}
	}
}