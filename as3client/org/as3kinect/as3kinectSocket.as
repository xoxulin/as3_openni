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
	 
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import mx.core.Singleton;
	
	import org.as3kinect.as3kinect;
	import org.as3kinect.events.as3kinectSocketEvent;

	/**
	 * as3kinectSocket class recieves Kinect data from the as3kinect driver.
	 */
	public class as3kinectSocket extends EventDispatcher
	{
		private static var _instance:as3kinectSocket;
		
		private var _firstByte:uint;
		private var _secondByte:uint;
		private var _packetSize:uint;
		private var _socket:Socket;
		private var _port:Number;

		public function as3kinectSocket(singleton:Singleton)
		{		
			_socket = new Socket();						
			
			_socket.addEventListener(ProgressEvent.SOCKET_DATA, onSocketData);
			_socket.addEventListener(IOErrorEvent.IO_ERROR, onSocketError);
			_socket.addEventListener(Event.CONNECT, onSocketConnect);
			
			_socket.endian = Endian.LITTLE_ENDIAN; 
		}
		
		public function connect(host:String = 'localhost', port:uint = 6001):void
		{
			_port = port;
			
			if (!this.connected)
			{
				_socket.connect(host, port);
			}
			else
			{
				dispatchEvent(new as3kinectSocketEvent(as3kinectSocketEvent.ONCONNECT, null));
			}
		}
		
		public function get connected():Boolean
		{
			return _socket.connected;
		}
		
		public function close():void
		{
			if (this.connected) _socket.close();
		}
		
		public function sendCommand(data:ByteArray):int
		{
			if(data.length == as3kinect.COMMAND_SIZE)
			{
				_socket.writeBytes(data, 0, as3kinect.COMMAND_SIZE);
				_socket.flush();
				return as3kinect.SUCCESS;
			}
			else
			{
				throw new Error( 'Incorrect data size (' + data.length + '). Expected: ' + as3kinect.COMMAND_SIZE);
				return as3kinect.ERROR;
			}
		}
		
		private function onSocketData(event:ProgressEvent):void
		{
			while (_socket.bytesAvailable > 0)
			{
				if(_socket.bytesAvailable > 6 && _packetSize == 0)
				{
					_firstByte = _socket.readUnsignedByte();
					_secondByte = _socket.readUnsignedByte();
					_packetSize = _socket.readUnsignedInt();					
				}
				
				if(_packetSize != 0 && _socket.bytesAvailable >= _packetSize)
				{
					var buffer:ByteArray = new ByteArray();
					buffer.endian = Endian.LITTLE_ENDIAN;
					
					_socket.readBytes(buffer, 0, _packetSize);
					
					buffer.position = 0;
					
					var dataObject:Object = {};
					
					dataObject.first = _firstByte;
					dataObject.second = _secondByte;
					dataObject.buffer = buffer;
					
					dispatchEvent(new as3kinectSocketEvent(as3kinectSocketEvent.ONDATA, dataObject));
					_packetSize = 0;
				}
				else
				{
					return;
				}
			}			
		}
		
		private function onSocketError(event:IOErrorEvent):void
		{
			dispatchEvent(new as3kinectSocketEvent(as3kinectSocketEvent.ONERROR, null));
		}
		
		private function onSocketConnect(event:Event):void
		{
			dispatchEvent(new as3kinectSocketEvent(as3kinectSocketEvent.ONCONNECT, null));
		}

		public static function get instance():as3kinectSocket 
		{
			if ( _instance == null )
			{
				_instance = new as3kinectSocket(new Singleton());
			}
			return _instance;
		}
	}
}

class Singleton {}