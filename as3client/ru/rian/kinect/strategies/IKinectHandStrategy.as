package ru.rian.kinect.strategies
{
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import org.as3kinect.events.KinectHandEvent;
	import ru.rian.kinect.object3d.IObject3D;

	public interface IKinectHandStrategy
	{
		function updateHand(event:KinectHandEvent):void;
		function enterFrameHandler(event:Event):void;
		function set object3d(value:IObject3D):void;
		function set handSet(value:Dictionary):void;		
	}
}