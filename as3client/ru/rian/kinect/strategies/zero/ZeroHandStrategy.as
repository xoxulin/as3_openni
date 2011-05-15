package ru.rian.kinect.strategies.zero
{
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
	import org.as3kinect.as3kinect;
	import org.as3kinect.events.KinectHandEvent;
	import ru.rian.kinect.strategies.KinectHandStrategy;
	
	public class ZeroHandStrategy extends KinectHandStrategy
	{
		private var _speed:Number = 10;
		private var _window:Number = 2*50/as3kinect.IMG_WIDTH;
		private var _aspectRatio:Number = as3kinect.IMG_HEIGHT/as3kinect.IMG_WIDTH;
		
		public function ZeroHandStrategy()
		{
		}
		
		override public function enterFrameHandler(event:Event):void
		{
			_currentMatrix.appendRotation(0.25, Vector3D.Z_AXIS);
			
			super.enterFrameHandler(event);
		}
	}
}