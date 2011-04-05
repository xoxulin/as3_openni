package org.as3kinect.events
{
	import flash.events.Event;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	
	public class KinectUserEvent extends Event
	{
		public static const USER_CREATE:String = "userCreate";
		public static const USER_UPDATE:String = "userUpdate";
		public static const USER_DELETE:String = "userDelete";
		
		public var id:uint;
		public var position:Vector3D;
		
		public function KinectUserEvent(type:String, byteArray:ByteArray)
		{
			super(type);
			
			id = byteArray.readUnsignedInt();
			if (type == USER_UPDATE) position = new Vector3D(byteArray.readFloat(), byteArray.readFloat(), byteArray.readFloat());
		}
	}
}