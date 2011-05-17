package ru.rian.kinect.strategies
{
	import com.greensock.TweenMax;
	
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import org.as3kinect.as3kinect;
	import org.as3kinect.events.KinectHandEvent;
	
	import ru.rian.kinect.object3d.IObject3D;
	
	public class KinectHandStrategy implements IKinectHandStrategy
	{
		private static const TIMEOUT:uint = 1000;
		
		protected var _object3D:IObject3D;
		
		protected var _centerPoint:Point = new Point(as3kinect.IMG_WIDTH/2, as3kinect.IMG_HEIGHT/2);
		protected var _currentMatrix:Matrix3D;
		
		protected var _handSet:Dictionary;
		protected var _scale:Number = 1;
		protected var _time:uint = 0;
		protected var _progress:Number;
		
		public function KinectHandStrategy()
		{
		}
		
		public function updateHand(event:KinectHandEvent):void
		{
			// - - - empty
		}
		
		public function enterFrameHandler(event:Event):void
		{
			if (_progress < 1) geometryFix();
			_object3D.matrix = _currentMatrix;
		}
		
		public function set object3d(value:IObject3D):void
		{
			_object3D = value;
			_time = getTimer();
			_progress = 0;
			if (_object3D) _currentMatrix = _object3D.matrix;
		}
		
		public function set handSet(value:Dictionary):void
		{
			_handSet = value;
		}
		
		protected function geometryFix():void
		{
			_progress = (getTimer() - _time)/TIMEOUT;
			
			var vector:Vector.<Vector3D> = _currentMatrix.decompose();
			
			var scale:Number = vector[2].x;
			var rotationX:Number = vector[1].x;
			var rotationY:Number = vector[1].y;
			
			if (0 != rotationX)
			{
				rotationX = rotationX * (1 - _progress);				
			}
			
			if (0 != rotationY)
			{
				rotationY = rotationY * (1 - _progress);				
			}
			
			if (_scale != scale)
			{
				scale = vector[2].x * (1 - _progress) + _scale*_progress;				
			}
			
			vector[1].x = rotationX;
			vector[1].y = rotationY;
			vector[2].x = vector[2].y = vector[2].z = scale;
			
			_currentMatrix.recompose(vector); 
		}
	}
}