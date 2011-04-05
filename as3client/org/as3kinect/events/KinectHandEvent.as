package org.as3kinect.events
{
	import flash.events.Event;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	
	public class KinectHandEvent extends Event
	{
		public static const HAND_CREATE:String = "handCreate";
		public static const HAND_UPDATE:String = "handUpdate";
		public static const HAND_DELETE:String = "handDelete";
		
		public var id:uint;
		public var position:Vector3D;
		
		public function KinectHandEvent(type:String, byteArray:ByteArray)
		{
			super(type);
			
			id = byteArray.readUnsignedInt();
			if (type != HAND_DELETE) position = new Vector3D(byteArray.readFloat(), byteArray.readFloat(), byteArray.readFloat());
		}
	}
}