#include "as3Network.h"
#include <iostream>
#include <string>
#include <fstream>

using namespace std;

struct addrinfo si_depth, si_rgb, si_data;

pthread_t data_thread, data_in_thread, data_out_thread;

SOCKET data_socket = INVALID_SOCKET;
SOCKET data_client_socket = INVALID_SOCKET;

PCSTR conf_port_data = "6001";

int die = 0;
int data_child;
int psent = 0;

callback net_callback;

/* 
 * sendMessage (Debug message)
 * sending: 3 0 msg
 * 3 -> Server message
 * 0 -> Debug message
 */
void as3Network::sendMessage(const char *message)
{
	std::string stringMessage = message;
	const unsigned int bufflen = 2 + sizeof(int) + sizeof(stringMessage);
	unsigned char *buff = new unsigned char[bufflen];

	unsigned char first = 3;
	unsigned char second = 0;
	unsigned int messageLen = sizeof(stringMessage);

	memcpy(buff, &first, 1);
	memcpy(buff + 1, &second, 1);
	memcpy(buff + 2, &messageLen, sizeof(int));
	memcpy(buff + 2 + sizeof(int), message, sizeof(stringMessage));
	
	sendData(buff, bufflen);
	
	delete [] buff;
}

/* 
 * sendMessage
 * sending: first second value
 * first -> Ex: 3 (Server message)
 * second -> Ex: 1 (User detected)
 * value -> Ex: 1 (User id)
 */
void as3Network::sendMessage(unsigned char first, unsigned char second, unsigned int value)
{
	const unsigned int bufflen = 2 + sizeof(int)*2;
	unsigned char *buff = new unsigned char[bufflen]; // char, char, int, int
	
	unsigned int size = sizeof(int);
	
	memcpy(buff, &first, 1);
	memcpy(buff + 1, &second, 1);
	memcpy(buff + 2, &size, sizeof(int));
	memcpy(buff + 2 + sizeof(int), &value, sizeof(int));
	
	sendData(buff, bufflen);

	delete [] buff;
}

/* 
 * sendMessage
 * sending: first second data
 * first -> Ex: 0 (Camera message)
 * second -> Ex: 0 (Depth data)
 */
void as3Network::sendMessage(unsigned char first, unsigned char second, unsigned char *data, unsigned int len)
{
	const unsigned int bufflen = 2 + sizeof(int) + len;
	unsigned char *buff = new unsigned char[bufflen]; // char, char, int, char[len]

	memcpy(buff, &first, 1); // first byte
	memcpy(buff + 1, &second, 1); // second byte
	memcpy(buff + 2, &len, sizeof(int)); // packet size
	memcpy(buff + 2 + sizeof(int), data, len); // packet
	
	sendData(buff, bufflen); // send to socket
	
	delete [] buff;
}

/* 
 * sendData
 */
int as3Network::sendData(unsigned char *buffer, int length)
{
	if(data_client_socket != INVALID_SOCKET)
	{
		return send(data_client_socket, (char*)buffer, length, 0);
	}
	return 0;
}

/* 
 * getData
 */
int as3Network::getData(unsigned char *buffer, int length)
{
	int result = 0; 
	
	if(data_client_socket != INVALID_SOCKET)
	{
		result = recv(data_client_socket, (char*)buffer, 1024, 0);

		/*string str = (char*) buffer;

		if (str.find("policy-file-request") != -1)
		{
			this->send_policy_file();
		}*/
	}

	return result;	
}

/*void as3Network::send_policy_file()
{
	ifstream myReadFile;
	myReadFile.open("crossdomain.xml");
	
	std::string content;
	std::string oneline;
	
	if (myReadFile.is_open())
	{
		while (!myReadFile.eof())
		{
		    getline(myReadFile, oneline);
			content = content + oneline;
		}
	}
	
	myReadFile.close();

	char * message = new char[content.size() + 1];
	std::copy(content.begin(), content.end(), message);
	message[content.size()] = '\0';
	
	printf("%s\n", message);

	this->sendMessage(message);
	
	delete [] message;
}*/

void as3Network::wait_client()
{
	printf("Wait data client\n");
	data_client_socket = accept(data_socket, NULL, NULL);
	
	if (data_client_socket == INVALID_SOCKET && !die)
	{
		printf("Error on accept() for data, exit data thread. %d\n", WSAGetLastError());
		closesocket(data_socket);
		WSACleanup();
	}

	printf("Got data client\n");
	net_callback();
}

int as3Network::init(callback cb) {
	net_callback = cb;
	die = 0;
	initServer(si_data, conf_port_data, &data_socket, "DATA");

	wait_client();
	return 0;
}

int as3Network::initServer(addrinfo si_type, PCSTR conf_port, SOCKET *the_socket, PCSTR label)
{
	ZeroMemory(&si_type, sizeof (si_type));

	si_type.ai_family = AF_INET;
	si_type.ai_socktype = SOCK_STREAM;
	si_type.ai_protocol = IPPROTO_TCP;
	si_type.ai_flags = AI_PASSIVE;
	
   // Resolve the local address and port to be used by the server
	struct addrinfo *result = NULL;	

	int iResult = getaddrinfo(NULL, conf_port, &si_type, &result);
	if (iResult != 0) {
		printf("%s: getaddrinfo failed: %d\n", label, iResult);
		WSACleanup();
		return 1;
	}

	*the_socket = socket(result->ai_family, result->ai_socktype, result->ai_protocol);

	if (*the_socket == INVALID_SOCKET) {
		printf("%s: socket failed [%ld]\n", label, WSAGetLastError());
		freeaddrinfo(result);
		WSACleanup();
		return 1;
	}

	iResult = bind(*the_socket, result->ai_addr, (int)result->ai_addrlen);
	if (iResult == SOCKET_ERROR) {
		printf("%s: bind failed: %d\n", label, WSAGetLastError());
		freeaddrinfo(result);
		closesocket(*the_socket);
		WSACleanup();
		return 1;
	}

	freeaddrinfo(result);

	if ( listen(*the_socket, SOMAXCONN ) == SOCKET_ERROR ) {
		printf( "%s: listen failed [%ld]\n", label, WSAGetLastError() );
		closesocket(*the_socket);
		WSACleanup();
		return 1;
	}

	return 0;
}

void as3Network::close_connection() {
	die = 1;
	if ( data_socket != INVALID_SOCKET )
		closesocket(data_socket);
}
