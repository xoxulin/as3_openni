/*
 * This file is part of the as3kinect Project. http://www.as3kinect.org
 *
 * Copyright (c) 2010 individual as3server contributors. See the CONTRIB file
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

#include <pthread/pthread.h>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <signal.h>
#include <math.h>

#pragma comment(lib, "Ws2_32.lib")
#pragma comment(lib, "pthreadVC2.lib")

typedef void (*callback)(void);

class as3Network {
  	public:
		int init(callback cb);
		void close_connection();
		int sendData(unsigned char *buffer, int length);
		int getData(unsigned char *buffer, int length);
		
		void sendMessage(const char *message);
		void sendMessage(unsigned char first, unsigned char second, unsigned int value);
		void sendMessage(unsigned char first, unsigned char second, unsigned char *message, const unsigned int len);
		
		void wait_client();
	private:
		//void send_policy_file();
		int initServer(addrinfo si_type, PCSTR conf_port, SOCKET *the_socket, PCSTR label);
};