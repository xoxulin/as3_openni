package ru.rian.kinect.strategies.double
{
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	import org.as3kinect.as3kinect;
	import org.as3kinect.events.KinectHandEvent;
	import ru.rian.kinect.strategies.KinectHandStrategy;
	import ru.rian.kinect.object3d.IObject3D;
	import ru.rian.kinect.utils.Vector3DUtil;
	
	public class ThreeAngleRotatorStrategy extends KinectHandStrategy
	{
		private var _leftHandKey:uint = 0;
		private var _rightHandKey:uint = 0;
		
		private var _defaultMatrix:Matrix3D = new Matrix3D();
		
		private var semiPI:Number = 0.5 * Math.PI;
		private var DEG:Number = 180/Math.PI;
		
		private var horizontalDelta:Number = Math.PI/2;
		private var verticalDelta:Number = Math.PI/2;
		
		public function ThreeAngleRotatorStrategy()
		{
			
		}
		
		override public function set handSet(value:Dictionary):void
		{
			super.handSet = value;
			
			if (value)
			{
				var keys:Array = []
				
				for (var key:* in value)
				{
					keys.push(key);					
				}
				
				_leftHandKey = keys[0];
				_rightHandKey = keys[1];
				
				if ((_handSet[_leftHandKey] as Vector3D).x > (_handSet[_rightHandKey] as Vector3D).x)
				{
					_leftHandKey = keys[1];
					_rightHandKey = keys[0];
				}
			}
			else
			{
				_leftHandKey = _rightHandKey = 0;
			}
		}
		
		override public function set object3d(value:IObject3D):void
		{
			super.object3d = value;
			_defaultMatrix = _currentMatrix;
		}
		
		override public function updateHand(event:KinectHandEvent):void
		{
			if (!_handSet[event.id]) return;
			
			_handSet[event.id] = event.position;
			
			animate();
		}
		
		private function animate():void
		{
			// - - - hands get
			
			var lefttHand:Vector3D = _handSet[_leftHandKey] as Vector3D;
			var rightHand:Vector3D = _handSet[_rightHandKey] as Vector3D;
			
			// - - - hands diff
				
			var delta:Point = new Point(rightHand.x - lefttHand.x, rightHand.y - lefttHand.y);
			var angleAxis:Number = - Math.atan2(delta.y, delta.x); 
			_scale = (delta.length + as3kinect.IMG_WIDTH/2)/as3kinect.IMG_WIDTH;
			
			// - - - hands middle
			
			var middle:Point = new Point((lefttHand.x + rightHand.x)/2 - _centerPoint.x, (lefttHand.y + rightHand.y)/2 - _centerPoint.y);
			
			var angleX:Number = verticalDelta * middle.y/_centerPoint.y;
			var angleZ:Number = horizontalDelta * middle.x/_centerPoint.x;
			
			var teta:Number = semiPI - angleX;
			var phi:Number = angleZ - semiPI;
			var axis:Vector3D = Vector3DUtil.sphericalVector3D(1, teta, phi);
			axis.normalize();
			
			// - - - - apply
			
			_currentMatrix = _defaultMatrix.clone();
			
			
			
			_currentMatrix.appendRotation(DEG*angleZ, Vector3D.Z_AXIS);
			//_currentMatrix.appendRotation(-DEG*angleAxis, axis);
			_currentMatrix.appendRotation(-DEG*angleAxis, Vector3D.Y_AXIS);
			_currentMatrix.appendRotation(DEG*angleX, Vector3D.X_AXIS);
			
			/*// - - - rotation X and Z
			
			var rotationAtX:Vector3D = new Vector3D(1, 0, 0, Math.cos(angleX/2));
			rotationAtX.scaleBy(Math.sin(angleX/2));
			
			var rotationAtZ:Vector3D = new Vector3D(0, 0, 1, Math.cos(angleZ/2));
			rotationAtZ.scaleBy(Math.sin(angleZ/2));
			
			// - - - quaternion ZX
			
			var quaternionXScaled:Vector3D = rotationAtX.clone();
			quaternionXScaled.scaleBy(rotationAtZ.w);
			
			var quaternionZScaled:Vector3D = rotationAtZ.clone();
			quaternionZScaled.scaleBy(rotationAtX.w);
			
			var quaternionXZ:Vector3D = rotationAtZ.crossProduct(rotationAtX).add(quaternionXScaled).add(quaternionZScaled);
			quaternionXZ.w = rotationAtX.w * rotationAtZ.w;
			
			var normalSquare:Number = Math.sqrt(quaternionXZ.lengthSquared + quaternionXZ.w * quaternionXZ.w);
			quaternionXZ.scaleBy(1/normalSquare);
			quaternionXZ.w /= normalSquare;
			
			// - - - quaternion axis
			
			var quaternionAxis:Vector3D = axis.clone();
			quaternionAxis.w = Math.cos(angleAxis/2);
			quaternionAxis.scaleBy(Math.sin(angleAxis/2));
			
			// - - - composition of quaternions
			
			var quaternionXZScaled:Vector3D = quaternionXZ.clone();
			quaternionXZScaled.scaleBy(quaternionAxis.w);
			
			var quaternionAxisScaled:Vector3D = quaternionAxis.clone();
			quaternionAxisScaled.scaleBy(quaternionXZ.w);
			
			var compositionQuaternion:Vector3D = quaternionAxis.crossProduct(quaternionXZ).add(quaternionAxisScaled).add(quaternionXZScaled);
			compositionQuaternion.w = quaternionAxis.w * quaternionXZ.w;
			
			normalSquare = Math.sqrt(compositionQuaternion.lengthSquared + compositionQuaternion.w * compositionQuaternion.w);
			compositionQuaternion.scaleBy(1/normalSquare);
			compositionQuaternion.w /= normalSquare;
			
			// - - - set to matrix
			
			var qQ:Vector.<Vector3D> = _currentMatrix.decompose(Orientation3D.QUATERNION);
			qQ[1] = compositionQuaternion;
			_currentMatrix.recompose(qQ, Orientation3D.QUATERNION);*/
			
		}
	}
}