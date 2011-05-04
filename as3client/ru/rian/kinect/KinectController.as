package ru.rian.kinect
{
	import com.greensock.TweenMax;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.PixelSnapping;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filters.BlurFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import org.as3kinect.as3kinect;
	import org.as3kinect.as3kinectWrapper;
	import org.as3kinect.events.KinectHandEvent;
	import org.as3kinect.events.KinectUserEvent;
	import org.as3kinect.events.as3kinectWrapperEvent;
	
	import ru.rian.kinect.controls.HandMarker;
	import ru.rian.kinect.controls.UserLabel;
	import ru.rian.kinect.object3d.IObject3D;
	import ru.rian.kinect.strategies.IKinectHandStrategy;
	import ru.rian.kinect.strategies.double.ThreeAngleRotatorStrategy;
	import ru.rian.kinect.strategies.single.JoystickStrategy;
	import ru.rian.kinect.strategies.single.TwoAngleRotatorStrategy;
	import ru.rian.kinect.strategies.zero.ZeroHandStrategy;
	
	public class KinectController extends EventDispatcher
	{
		private var _debugView:Sprite;
		
		private var _bitmap:Bitmap;
		private var _loader:Loader;
		
		private var _as3wrapper:as3kinectWrapper;
		private var _object3d:IObject3D;
		private var _sourceERectangle:Rectangle = new Rectangle(0,0, as3kinect.IMG_WIDTH, as3kinect.IMG_HEIGHT)
		private var _sourcePoint:Point = new Point();
		
		private var _blurFilter:BlurFilter = new BlurFilter(32, 32, 1);
		
		private var _userCount:uint = 0;
		private var _handCount:uint = 0;
		private var _handSet:Dictionary;
		
		private var _currentStrategy:IKinectHandStrategy;
		private var _strategyVector:Vector.<IKinectHandStrategy>;
		
		public function KinectController(singleton:Singleton)
		{
			super();
			
			createDebugView();
			createStrategy();
			initKinectWrapper();
		}
		
		private function createDebugView():void
		{
			_debugView = new Sprite();
			
			_bitmap = new Bitmap(new BitmapData(as3kinect.IMG_WIDTH, as3kinect.IMG_HEIGHT, true, 0x000000), PixelSnapping.NEVER, true);
			_debugView.addChild(_bitmap);
			_bitmap.transform.colorTransform = new ColorTransform(1, 1, 1, 0.2);
						
			// - - -
			
			_loader = new Loader();
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadCompleteHandler);
		}
		
		private function createStrategy():void
		{
			_handSet = new Dictionary();
			_strategyVector = new Vector.<IKinectHandStrategy>();
			_strategyVector.push(new ZeroHandStrategy(), new TwoAngleRotatorStrategy(), new ThreeAngleRotatorStrategy());			
		}
		
		private function initKinectWrapper():void
		{
			_as3wrapper = as3kinectWrapper.instance;
			_as3wrapper.startCallback = start;
			
			_as3wrapper.addEventListener(as3kinectWrapperEvent.ON_DEPTH, depthHandler);												
			
			_as3wrapper.addEventListener(KinectHandEvent.HAND_CREATE, addHand);
			_as3wrapper.addEventListener(KinectHandEvent.HAND_UPDATE, updateHand);
			_as3wrapper.addEventListener(KinectHandEvent.HAND_DELETE, removeHand);
			
			_as3wrapper.addEventListener(KinectUserEvent.USER_CREATE, userHandler);
			_as3wrapper.addEventListener(KinectUserEvent.USER_UPDATE, userHandler);
			_as3wrapper.addEventListener(KinectUserEvent.USER_DELETE, userHandler);
		}
		
		public function set object3d(value:IObject3D):void
		{
			_object3d = value;
		}
		
		public function get debugView():Sprite
		{
			return _debugView;
		}
		
		private function start():void
		{
			_debugView.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
			checkStrategy();
		}
		
		private function addHand(event:KinectHandEvent):void
		{
			if (!_userCount || _handCount == 2) return;
			
			_handCount++;
			_handSet[event.id] = event.position;
			checkStrategy();
			
			var sprite:DisplayObject = new HandMarker();
			sprite.name = "Hand"+event.id;
			TweenMax.fromTo(sprite, 0.5, {autoAlpha: 0}, {autoAlpha: 1});
			
			sprite.x = event.position.x;
			sprite.y = event.position.y;
			sprite.scaleX = sprite.scaleY = 400/(event.position.z+200);
			
			_debugView.addChild(sprite);
		}
		
		private function updateHand(event:KinectHandEvent):void
		{
			if (!_handSet[event.id]) return;
			
			var sprite:DisplayObject = _debugView.getChildByName("Hand"+event.id);
			if (sprite)
			{
				TweenMax.to(sprite, 0.5, {autoAlpha: 1});
				sprite.x = event.position.x;
				sprite.y = event.position.y;
				sprite.scaleX = sprite.scaleY = 400/(event.position.z+200);
			}
		}
		
		private function removeHand(event:KinectHandEvent):void
		{
			if (!_handSet[event.id]) return;
			
			if (_handCount > 0) _handCount--;
			
			delete _handSet[event.id];
			
			checkStrategy();
			var sprite:DisplayObject = _debugView.getChildByName("Hand"+event.id);
			if (sprite) TweenMax.to(sprite, 0.1, {autoAlpha: 0, onComplete: function():void {_debugView.removeChild(sprite);}});
		}
		
		private function checkStrategy():void
		{
			if (_handCount > _strategyVector.length) _handCount = 0;
			currentStrategy = _strategyVector[_handCount];
		}
		
		private function set currentStrategy(value:IKinectHandStrategy):void
		{
			// un
			if (_currentStrategy) {
				
				_currentStrategy.object3d = null;
				_currentStrategy.handSet = null;
				
				_as3wrapper.removeEventListener(KinectHandEvent.HAND_UPDATE, _currentStrategy.updateHand);
				_debugView.removeEventListener(Event.ENTER_FRAME, _currentStrategy.enterFrameHandler);
			}
			
			_currentStrategy =  value;
			
			// sub
			if (_currentStrategy) {
				
				_currentStrategy.object3d = _object3d;
				_currentStrategy.handSet = _handSet;				
				
				_as3wrapper.addEventListener(KinectHandEvent.HAND_UPDATE, _currentStrategy.updateHand);
				_debugView.addEventListener(Event.ENTER_FRAME, _currentStrategy.enterFrameHandler);
			}
		}
		
		
		private function userHandler(event:KinectUserEvent):void
		{
			var sprite:DisplayObject;
			
			switch (event.type)
			{
				case KinectUserEvent. USER_CREATE:
					sprite = new UserLabel();
					(sprite as UserLabel).text = event.id.toString(); 
					sprite.name = "User" + event.id;
					_userCount++;
					_debugView.addChild(sprite);
					TweenMax.fromTo(sprite, 0.5, {autoAlpha: 0}, {autoAlpha: 1});
					break;
				case KinectUserEvent.USER_UPDATE:
					sprite = _debugView.getChildByName("User"+event.id);
					if (sprite)
					{
						sprite.x = event.position.x;
						sprite.y = event.position.y;							
					}												
					break;
				case KinectUserEvent.USER_DELETE:
					sprite = _debugView.getChildByName("User"+event.id);
					_userCount--;
					if (sprite) TweenMax.to(sprite, 0.1, {autoAlpha: 0, onComplete: function():void {_debugView.removeChild(sprite);}});
					break;
			}
		}
		
		private function enterFrameHandler(event:Event):void
		{
			_as3wrapper.depth.getBuffer();				
		}
		
		private function depthHandler(event:as3kinectWrapperEvent):void
		{
			_loader.loadBytes(event.data);
		}
		
		private function loadCompleteHandler(event:Event):void
		{
			_bitmap.bitmapData.draw(_loader);
			//_bitmap.bitmapData.copyChannel(_bitmap.bitmapData, _sourceERectangle, _sourcePoint, BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
			_bitmap.bitmapData.applyFilter(_bitmap.bitmapData, _sourceERectangle, _sourcePoint, _blurFilter);
		}
		
		public function close():void
		{
			_as3wrapper.close();
		}
		
		// -------------------------------------------------------
		
		public static function get instance():KinectController 
		{
			if ( _instance == null )
			{
				_instance = new KinectController(new Singleton());
			}
			return _instance;
		}
		
		private static var _instance:KinectController;
	}
}
class Singleton {}