package ru.rian.kinect.object3d
{
	import flash.geom.Matrix3D;

	public interface IObject3D
	{
		function set matrix(value:Matrix3D):void;
		function get matrix():Matrix3D;
	}
}