package ru.rian.kinect.strategies.single
{
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
	import org.as3kinect.as3kinect;
	import org.as3kinect.events.KinectHandEvent;
	import ru.rian.kinect.strategies.KinectHandStrategy;
	
	public class JoystickStrategy extends KinectHandStrategy
	{
		private var _speed:Number = 10;
		private var _window:Number = 2*25/as3kinect.IMG_WIDTH;
		private var _aspectRatio:Number = as3kinect.IMG_HEIGHT/as3kinect.IMG_WIDTH;
		
		public function JoystickStrategy()
		{
		}
		
		override public function updateHand(event:KinectHandEvent):void
		{
			if (!_handSet[event.id]) return;
			
			var deltaPoint:Point = new Point(event.position.x / _centerPoint.x - 1, event.position.y / _centerPoint.y - 1);
			
			deltaPoint.x = scaleValue(deltaPoint.x);
			deltaPoint.y = scaleValue(deltaPoint.y);
			
			_currentMatrix = _object3D.matrix;
			_currentMatrix.appendRotation(_speed*deltaPoint.x, Vector3D.Z_AXIS);
			_currentMatrix.appendRotation(_speed*_aspectRatio*deltaPoint.y, Vector3D.X_AXIS);
		}
		
		private function scaleValue(value:Number):Number
		{
			return (value < _window && value > -_window)?(0):((value > _window)?((value - _window)/(1 - _window)):((value + _window)/(1 - _window)));
		}
	}
}