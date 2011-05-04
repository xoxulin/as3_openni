package ru.rian.kinect.controls
{
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.InterpolationMethod;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	public class UserLabel extends Sprite {
		
		private var _textField:TextField; 
		
		public function UserLabel()
		{
			super();
			
			drawBody();
			
			blendMode = BlendMode.ADD;
		}
		
		protected function drawBody():void
		{
			_textField = new TextField();
			_textField.defaultTextFormat = new TextFormat("_sans", 48, 0xFFFFFF);
			_textField.alpha = 0.2;
			_textField.autoSize = TextFieldAutoSize.LEFT;
			_textField.selectable = false;
			
			addChild(_textField);
		}
		
		public function set text(value:String):void
		{
			_textField.text = value;
			
			_textField.x = -_textField.width/2;
			_textField.y = -_textField.height/2;
		}
	}
}