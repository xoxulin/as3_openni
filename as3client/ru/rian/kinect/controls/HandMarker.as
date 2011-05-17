package ru.rian.kinect.controls
{
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.InterpolationMethod;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	
	public class HandMarker extends Sprite {
		
		public function HandMarker()
		{
			super();
			
			var hand:HandCursor = new HandCursor(); 
			hand.scaleX = hand.scaleY = 1.5;
			addChild(hand);
			
			blendMode = BlendMode.ADD;
		}
	}
}