package org.as3kinect.events
{
	import flash.events.Event;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	
	public class KinectGestureEvent extends Event
	{
		public static const GESTURE_RECOGNIZED:String = "gestureRecognized";
		public static const GESTURE_PROGRESS:String = "gestureProgress";
		
		public var gesture:String;
		public var position:Vector3D;
		public var endPosition:Vector3D;
		
		public function KinectGestureEvent(type:String, byteArray:ByteArray)
		{
			super(type);
			
			var gestureLength:uint;
			
			if (type == GESTURE_RECOGNIZED)
			{
				gestureLength = byteArray.bytesAvailable - 24;
				
				gesture = byteArray.readUTFBytes(gestureLength);
				position = new Vector3D(byteArray.readFloat(), byteArray.readFloat(),  byteArray.readFloat());
				endPosition = new Vector3D(byteArray.readFloat(), byteArray.readFloat(),  byteArray.readFloat());
			}
			else
			{
				gestureLength = byteArray.bytesAvailable - 12;
				gesture = byteArray.readUTFBytes(gestureLength);
				position = new Vector3D(byteArray.readFloat(), byteArray.readFloat(),  byteArray.readFloat());
			}
			
		}
	}
}