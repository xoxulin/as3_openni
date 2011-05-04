package ru.rian.kinect.utils
{
	import flash.geom.Vector3D;

	public class Vector3DUtil
	{
		public static function sphericalVector3D(ro:Number, teta:Number, phi:Number):Vector3D
		{
			var xy:Number = ro * Math.sin(teta);
			var x:Number = xy * Math.cos(phi);
			var y:Number = xy * Math.sin(phi);
			var z:Number = ro * Math.cos(teta);
			
			return new Vector3D(x, y, z);
		}
		
		public static function scaleVector3D(vector:Vector3D, scale:Number):Vector3D
		{
			return new Vector3D(scale * vector.x, scale * vector.y, scale * vector.z);
		}
	}
}