/*
 * This file is part of the as3kinect Project. http://www.as3kinect.org
 *
 * Copyright (c) 2010 individual as3kinect contributors. See the CONTRIB file
 * for details.
 *
 * This code is licensed to you under the terms of the Apache License, version
 * 2.0, or, at your option, the terms of the GNU General Public License,
 * version 2.0. See the APACHE20 and GPL2 files for the text of the licenses,
 * or the following URLs:
 * http://www.apache.org/licenses/LICENSE-2.0
 * http://www.gnu.org/licenses/gpl-2.0.txt
 *
 * If you redistribute this file in source form, modified or unmodified, you
 * may:
 *   1) Leave this header intact and distribute it under the same terms,
 *      accompanying it with the APACHE20 and GPL20 files, or
 *   2) Delete the Apache 2.0 clause and accompany it with the GPL2 file, or
 *   3) Delete the GPL v2 clause and accompany it with the APACHE20 file
 * In all cases you must keep the copyright notice intact and include a copy
 * of the CONTRIB file.
 *
 * Binary distributions must follow the binary distribution requirements of
 * either License.
 */

 package org.as3kinect {
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	
	import mx.core.Singleton;
	
	import org.as3kinect.as3kinect;
	import org.as3kinect.as3kinectDepth;
	import org.as3kinect.as3kinectSkeleton;
	import org.as3kinect.as3kinectSocket;
	import org.as3kinect.events.KinectGestureEvent;
	import org.as3kinect.events.KinectHandEvent;
	import org.as3kinect.events.KinectUserEvent;
	import org.as3kinect.events.as3kinectSocketEvent;
	import org.as3kinect.events.as3kinectWrapperEvent;
	
	public class as3kinectWrapper extends EventDispatcher {

		private static var _instance:as3kinectWrapper;
		
		private var _socket:as3kinectSocket;
		private var _data:ByteArray;
		private var _debugging:Boolean = true;
		private var user_id:Number;
		
		private var _startCallback:Function;
		
		public var depth:as3kinectDepth;
		public var skel:as3kinectSkeleton;

		public function as3kinectWrapper(singleton:Singleton) {
			depth = new as3kinectDepth();			
			skel = new as3kinectSkeleton();
			
			/* Init socket objects */
			_socket = as3kinectSocket.instance;
			
			_socket.addEventListener(as3kinectSocketEvent.ONDATA, dataReceived);
			_socket.addEventListener(as3kinectSocketEvent.ONCONNECT, connectedHandler);
			_socket.addEventListener(as3kinectSocketEvent.ONERROR, errorHandler);
			
			connect();
			
			
			/* Init data out buffer */
			_data = new ByteArray();
		}
		
		public function set startCallback(value:Function):void
		{
			_startCallback = value;
		}
		
		private function connect():void
		{
			_socket.connect(as3kinect.SERVER_IP, as3kinect.SOCKET_PORT);			
		}
		
		private function connectedHandler(event:as3kinectSocketEvent):void
		{
			//trace("_socket.connected");
			if (_startCallback != null) _startCallback.call(this);
		}
		
		private function errorHandler(event:as3kinectSocketEvent):void
		{
			//trace("_socket.error");
			_socket.close();
			setTimeout(connect, 5000);
		}

		/*
		 * dataReceived from socket (Protocol definition)
		 * Metadata comes in the first and second value of the data object
		 * first:
		 *	0 -> Camera data
		 * 			second:
		 *  			0 -> Depth ARGB received
		 *  			1 -> Video ARGB received		 
		 *	1 -> Motor data
		 *	2 -> Microphone data
		 *	3 -> Server data
		 * 			second:
		 *  			0 -> Debug info received
		 *  			1 -> Got user
		 *  			2 -> Lost user		 		 
		 *
		 */
		private function dataReceived(event:as3kinectSocketEvent):void
		{
			// Send ByteArray to position 0
			
			event.data.buffer.position = 0;
			
			switch (event.data.first) {
				case 0: //Camera
					switch (event.data.second) {
						case 0: //Depth received
							dispatchEvent(new as3kinectWrapperEvent(as3kinectWrapperEvent.ON_DEPTH, event.data.buffer));
							depth.busy = false;
						break;
						case 1: //Video received							
						break;
						case 2: //SKEL received							
						break;
					}
				break;
				case 1: //Motor
				break;
				case 2: //Mic
				break;
				case 3: //Server
					switch (event.data.second) {
						case 0: //Debug received
							trace(event.data.buffer.readUTFBytes(event.data.buffer.bytesAvailable)+"\n");
						break;
						case 1: //Got user
							dispatchEvent(new KinectUserEvent(KinectUserEvent.USER_CREATE, event.data.buffer));
						break;
						case 12: //User CoM update
							dispatchEvent(new KinectUserEvent(KinectUserEvent.USER_UPDATE, event.data.buffer));
						break;
						case 2: //Lost user
							dispatchEvent(new KinectUserEvent(KinectUserEvent.USER_DELETE, event.data.buffer));							
						break;
						case 3: //Pose detected							
						break;
						case 4: //Calibrating							
						break;
						case 5: //Calibration complete							
						break;
						case 6: //Calibration failed							
						break;
						
						// - - - new nodes for hand tracking
						
						case 7: //Gesture reconized
							dispatchEvent(new KinectGestureEvent(KinectGestureEvent.GESTURE_RECOGNIZED, event.data.buffer));
						break;
						case 8: //Gesture progress
							dispatchEvent(new KinectGestureEvent(KinectGestureEvent.GESTURE_PROGRESS, event.data.buffer));
						break;
						case 9: //New Hand
							dispatchEvent(new KinectHandEvent(KinectHandEvent.HAND_CREATE, event.data.buffer));
						break;
						case 10: //Hand Update
							dispatchEvent(new KinectHandEvent(KinectHandEvent.HAND_UPDATE, event.data.buffer));
						break;
						case 11: //Lost Hand
							dispatchEvent(new KinectHandEvent(KinectHandEvent.HAND_DELETE, event.data.buffer));
						break;						
					}
				break;
			}
			
			// Clear ByteArray after used
			event.data.buffer.clear();
		}
		
		public function get running():Boolean
		{
			return _socket.connected;
		}
		
		public function close():void
		{
			_socket.close();
		}
		
		public static function get instance():as3kinectWrapper 
		{
			if ( _instance == null )
			{
				_instance = new as3kinectWrapper(new Singleton());
			}
			return _instance;
		}
	}	
}

class Singleton {}