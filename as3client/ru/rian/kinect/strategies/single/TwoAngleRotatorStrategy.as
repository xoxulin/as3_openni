package ru.rian.kinect.strategies.single
{
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
	import org.as3kinect.as3kinect;
	import org.as3kinect.events.KinectHandEvent;
	
	import ru.rian.kinect.object3d.IObject3D;
	import ru.rian.kinect.strategies.KinectHandStrategy;
	
	public class TwoAngleRotatorStrategy extends KinectHandStrategy
	{
		private var horizontalDelta:Number = 90;
		private var verticalDelta:Number = 45;
		
		private var _defaultMatrix:Matrix3D = new Matrix3D();
		
		public function TwoAngleRotatorStrategy()
		{
		}
		
		override public function set object3d(value:IObject3D):void
		{
			super.object3d = value;
			_defaultMatrix = _currentMatrix;
		}
		
		override public function updateHand(event:KinectHandEvent):void
		{
			if (!_handSet[event.id]) return;
			
			var deltaPoint:Point = new Point(event.position.x / _centerPoint.x - 1, event.position.y / _centerPoint.y - 1);
			
			var angleX:Number = verticalDelta * deltaPoint.y;
			var angleZ:Number = horizontalDelta * deltaPoint.x;
			
			// - - - - apply
			_currentMatrix = _defaultMatrix.clone();
			_currentMatrix.appendRotation(angleZ, Vector3D.Z_AXIS);
			_currentMatrix.appendRotation(angleX, Vector3D.X_AXIS);
		}
	}
}