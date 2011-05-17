#include <winsock2.h>
#include <GdiPlus.h>

// - - -

/*#include <ddraw.h>
#include <gdipluspixelformats.h>
#include <gdiplusenums.h>
#include <GdiplusTypes.h>
#include <GdiplusGpStubs.h>
#include <gdiplusimaging.h>
#include <gdiplusmetaheader.h>
#include <gdipluscolor.h>
#include <gdipluscolormatrix.h>
#include <GdiPlusFlat.h>
#include <GdiPlusInit.h>*/

// - - - 

#include <XnOpenNI.h>
#include <XnCodecIDs.h>
#include <XnCppWrapper.h>
#include <XnFPSCalculator.h>
#include <pthread\pthread.h>
#include "as3Network.h"
#include <iostream>
#include <stdio.h>

using namespace Gdiplus;
using namespace std;

#pragma comment (lib, "gdiplus")

//---------------------------------------------------------------------------
// Globals
//---------------------------------------------------------------------------
xn::Context g_Context;
xn::DepthGenerator g_DepthGenerator;
xn::UserGenerator g_UserGenerator;
xn::GestureGenerator g_GestureGenerator;
xn::HandsGenerator g_HandsGenerator;

//xn::Codec g_Codec;

#define GL_WIN_SIZE_X 1024
#define GL_WIN_SIZE_Y 768

as3Network server;

CLSID   encoderClsid;

//Stream
IStream *stream;
IStream *compressStream;

Image	*imageBuffer;

BITMAPINFO bitmapInfo;

const unsigned int IMG_BUFFER_SIZE = 3*640*480;
unsigned char img_buffer[IMG_BUFFER_SIZE]; // array
unsigned char compress_buffer[IMG_BUFFER_SIZE]; // array

unsigned int writtenBytesSize = IMG_BUFFER_SIZE;

// - - - colors

#define MAX_DEPTH 10000
#define MAX_USERS 15
float g_pDepthHist[MAX_DEPTH];

unsigned char Colors[][3] =
{
	{0x00,0x00,0xFF},
	{0x00,0xFF,0x00},
	{0xFF,0x00,0x00},
	{0x00,0x80,0xFF},
	{0x00,0xFF,0xFF},
	{0xFF,0xFF,0x00},
	{0xFF,0x80,0x00},
	{0xFF,0x00,0xFF}
};

XnUInt32 nColors = 8;

#define MAX_USERS 15

pthread_t server_thread;
int _die = 0;
int _connected = 0;

XnChar currentUsers = 0;

//---------------------------------------------------------------------------
// Code
//---------------------------------------------------------------------------

void CleanupExit()
{
	g_Context.Shutdown();
	server.close_connection();
	_die = 1;	
	exit (1);
}

void getUsersPixels(unsigned char* buffer)
{
	// vars
	xn::SceneMetaData smd;
	xn::DepthMetaData dmd;
	
	g_DepthGenerator.GetMetaData(dmd); // get depth data
	g_UserGenerator.GetUserPixels(0, smd); // get users	data
		
	unsigned int nValue = 0;
	float nHistValue = 0;
	unsigned int nIndex = 0;
	
	unsigned int nX = 0;
	unsigned int nY = 0;
	unsigned int nNumberOfPoints = 0;
	
	XnUInt16 g_nXRes = dmd.XRes();
	XnUInt16 g_nYRes = dmd.YRes();

	const XnDepthPixel* pDepth = dmd.Data();
	const XnLabel* pLabels = smd.Data();

	// Calculate the accumulative histogram
	memset(g_pDepthHist, 0, MAX_DEPTH*sizeof(float));
	
	for (nY=0; nY<g_nYRes; nY++)
	{
		for (nX=0; nX<g_nXRes; nX++)
		{
			nValue = *pDepth;

			if (nValue != 0)
			{
				g_pDepthHist[nValue]++;
				nNumberOfPoints++;
			}

			pDepth++;
		}
	}

	// - - - create statistic

	for (nIndex=1; nIndex<MAX_DEPTH; nIndex++)
	{
		g_pDepthHist[nIndex] += g_pDepthHist[nIndex-1];
	}

	// - - - linear spectrum

	if (nNumberOfPoints)
	{
		for (nIndex=1; nIndex<MAX_DEPTH; nIndex++)
		{
			g_pDepthHist[nIndex] = 1.0f - (g_pDepthHist[nIndex] / nNumberOfPoints);
		}
	}
	
	pDepth = dmd.Data();
	
	// drawing depth

	for (nY=0; nY<g_nYRes; nY++)
	{
		for (nX=0; nX < g_nXRes; nX++)
		{
			buffer[0] = 0x00;
			buffer[1] = 0x00;
			buffer[2] = 0x00;

			if (*pLabels != 0)
			{
				nValue = *pDepth;				
				XnLabel label = *pLabels;
				XnUInt32 nColorID = (label-1) % nColors;
				nHistValue = g_pDepthHist[nValue];

				buffer[0] = (unsigned char) (nHistValue * Colors[nColorID][0]);
				buffer[1] = (unsigned char) (nHistValue * Colors[nColorID][1]); 
				buffer[2] = (unsigned char) (nHistValue * Colors[nColorID][2]);
			}

			pLabels++;
			pDepth++;
			buffer += 3; // next 3 bytes of array
		}
	}	
}

void compress(unsigned char* buffer, unsigned char* compress_buffer)
{
	// - - - converting img_buffer to JPEG stream -----------------------------------

	ULARGE_INTEGER ulnSize;
	ULONG ulBytes;
	LARGE_INTEGER lnOffset;
    lnOffset.QuadPart = 0;

	
	imageBuffer = (Image*) new Bitmap(&bitmapInfo, buffer);
	
	compressStream->Revert(); // clear compressStream
	compressStream->Seek(lnOffset, STREAM_SEEK_SET, NULL); // seek do begin of compressStream
	Status stat = imageBuffer->Save(compressStream, &encoderClsid, NULL); // save image to compressStream with encoder
	compressStream->Seek(lnOffset, STREAM_SEEK_END, &ulnSize); // seek to end of compressStream
	compressStream->Seek(lnOffset, STREAM_SEEK_SET, NULL); // seek to begin
	writtenBytesSize = (unsigned int)ulnSize.QuadPart; // get writtenBytesSize
	compressStream->Read(compress_buffer, (ULONG)ulnSize.QuadPart, &ulBytes); // read to img_buffer

	delete imageBuffer;
}

void getUsers()
{
	XnUserID aUsers[MAX_USERS];
	XnUInt16 nUsers = MAX_USERS;

	g_UserGenerator.GetUsers(aUsers, nUsers);
	
	currentUsers = (XnChar) nUsers;

	if (nUsers == 0) return;

	XnPoint3D centerOffMass[1];
	XnUserID _id;
	float _x, _y, _z;
	unsigned char * buffer;
	
	buffer = new unsigned char [16]; // id + x + y + z
	
	for (int i = 0; i < currentUsers; ++i)
	{
		_id = aUsers[i];

		g_UserGenerator.GetCoM(_id, centerOffMass[0]);
				
		if (centerOffMass[0].X || centerOffMass[0].Y || centerOffMass[0].Z)
		{
			g_DepthGenerator.ConvertRealWorldToProjective(1, centerOffMass, centerOffMass);

			_x = centerOffMass[0].X;
			_y = centerOffMass[0].Y;
			_z = centerOffMass[0].Z;
			
			memcpy(buffer, &_id, 4);
			memcpy(buffer + 4, &_x, 4);
			memcpy(buffer + 8, &_y, 4);
			memcpy(buffer + 12, &_z, 4);
			
			//printf("User update: %d @ %s\n", _id, (char*) buffer);
			server.sendMessage(3, 12, buffer, 16);
		}
	}

	delete [] buffer;
}

void addGestures()
{
	//g_GestureGenerator.AddGesture("Wave", NULL);
	g_GestureGenerator.AddGesture("MovingHand", NULL);
}

void XN_CALLBACK_TYPE Gesture_Recognized(xn::GestureGenerator &generator, const XnChar *strGesture, const XnPoint3D *pIDPosition, const XnPoint3D *pEndPosition, void *pCookie)
{
		//printf("Gesture recognized: %s @ (%f,%f,%f)\n", strGesture, pIDPosition->X, pIDPosition->Y, pIDPosition->Z);
		
		g_HandsGenerator.StartTracking(*pIDPosition);

		// - - - start prepare

		XnPoint3D position[2] = {*pIDPosition, *pEndPosition};
		float _x, _y, _z;
		
		std::string stringGesture = strGesture;
		const unsigned int bufflen = sizeof(stringGesture) + 2*3*sizeof(float); // stringGesture + 3*4 + 3*4
		
		unsigned char * buffer;		
		buffer = new unsigned char [bufflen];
		
		g_DepthGenerator.ConvertRealWorldToProjective(2, position, position);
		
		memcpy(buffer, strGesture, sizeof(stringGesture));
		
		// - - - 

		_x = position[0].X;
		_y = position[0].Y;
		_z = position[0].Z;

		memcpy(buffer + sizeof(stringGesture), &_x, sizeof(float));
		memcpy(buffer + sizeof(stringGesture) + sizeof(float), &_y, sizeof(float));
		memcpy(buffer + sizeof(stringGesture) + 2*sizeof(float), &_z, sizeof(float));

		// - - - 

		_x = position[1].X;
		_y = position[1].Y;
		_z = position[1].Z;
		
		memcpy(buffer + sizeof(stringGesture) + 3*sizeof(float), &_x, sizeof(float));
		memcpy(buffer + sizeof(stringGesture) + 4*sizeof(float), &_y, sizeof(float));
		memcpy(buffer + sizeof(stringGesture) + 5*sizeof(float), &_z, sizeof(float));

		// - - - end prepare

		server.sendMessage(3, 7, buffer, bufflen);

		delete [] buffer;
}

void XN_CALLBACK_TYPE Gesture_Progress(xn::GestureGenerator &generator, const XnChar *strGesture, const XnPoint3D *pPosition, XnFloat fProgress, void *pCookie)
{
	//printf("Gesture progress: %s @ (%f,%f,%f)\n", strGesture, pPosition->X, pPosition->Y, pPosition->Z);

	g_GestureGenerator.RemoveGesture("MovingHand");
	g_HandsGenerator.StartTracking(*pPosition);

	// - - - start prepare

	XnPoint3D position[1] = {*pPosition};
	float _x, _y, _z;
		
	std::string stringGesture = strGesture;
	const unsigned int bufflen = sizeof(stringGesture) + 3*sizeof(float); // stringGesture + 3*4
		
	unsigned char * buffer;		
	buffer = new unsigned char [bufflen];
		
	g_DepthGenerator.ConvertRealWorldToProjective(1, position, position);
		
	memcpy(buffer, strGesture, sizeof(stringGesture));
		
	// - - - 

	_x = position[0].X;
	_y = position[0].Y;
	_z = position[0].Z;

	memcpy(buffer + sizeof(stringGesture), &_x, sizeof(float));
	memcpy(buffer + sizeof(stringGesture) + sizeof(float), &_y, sizeof(float));
	memcpy(buffer + sizeof(stringGesture) + 2*sizeof(float), &_z, sizeof(float));

	// - - - end prepare

	server.sendMessage(3, 8, buffer, bufflen);

	delete [] buffer;
}

void XN_CALLBACK_TYPE  Hand_Create(xn::HandsGenerator& generator, XnUserID nId, const XnPoint3D* pPosition, XnFloat fTime, void* pCookie)
{ 
	//printf("New Hand: %d @ (%f,%f,%f)\n", nId, pPosition->X, pPosition->Y, pPosition->Z); 

	// - - - start prepare

	XnPoint3D position[1] = {*pPosition};
	float _x, _y, _z;
		
	const unsigned int bufflen = sizeof(int) + 3*sizeof(float); // stringGesture + 3*4
		
	unsigned char * buffer;		
	buffer = new unsigned char [bufflen];
		
	g_DepthGenerator.ConvertRealWorldToProjective(1, position, position);
		
	memcpy(buffer, &nId, sizeof(int));
		
	// - - - 

	_x = position[0].X;
	_y = position[0].Y;
	_z = position[0].Z;

	memcpy(buffer + sizeof(int), &_x, sizeof(float));
	memcpy(buffer + sizeof(int) + sizeof(float), &_y, sizeof(float));
	memcpy(buffer + sizeof(int) + 2*sizeof(float), &_z, sizeof(float));

	// - - - end prepare

	server.sendMessage(3, 9, buffer, bufflen);

	delete [] buffer;
} 

void XN_CALLBACK_TYPE Hand_Update(xn::HandsGenerator& generator, XnUserID nId, const XnPoint3D* pPosition, XnFloat fTime, void* pCookie)
{ 
	//printf("Hand_Update: %d @ (%f,%f,%f)\n", nId, pPosition->X, pPosition->Y, pPosition->Z); 
	
	// - - - start prepare

	XnPoint3D position[1] = {*pPosition};
	float _x, _y, _z;
		
	const unsigned int bufflen = sizeof(int) + 3*sizeof(float); // stringGesture + 3*4
		
	unsigned char * buffer;		
	buffer = new unsigned char [bufflen];
		
	g_DepthGenerator.ConvertRealWorldToProjective(1, position, position);
		
	memcpy(buffer, &nId, sizeof(int));
		
	// - - - 

	_x = position[0].X;
	_y = position[0].Y;
	_z = position[0].Z;

	memcpy(buffer + sizeof(int), &_x, sizeof(float));
	memcpy(buffer + sizeof(int) + sizeof(float), &_y, sizeof(float));
	memcpy(buffer + sizeof(int) + 2*sizeof(float), &_z, sizeof(float));

	// - - - end prepare

	server.sendMessage(3, 10, buffer, bufflen);
} 

void XN_CALLBACK_TYPE Hand_Destroy(xn::HandsGenerator& generator, XnUserID nId, XnFloat fTime, void* pCookie)
{ 
	//printf("Lost Hand: %d\n", nId);
	server.sendMessage(3, 11, nId);
	g_GestureGenerator.AddGesture("MovingHand", NULL);
} 

// Callback: New user was detected
void XN_CALLBACK_TYPE User_NewUser(xn::UserGenerator& generator, XnUserID nId, void* pCookie)
{
	//printf("User_NewUser: %d\n", nId);
	server.sendMessage(3, 1, nId);
}
// Callback: An existing user was lost
void XN_CALLBACK_TYPE User_LostUser(xn::UserGenerator& generator, XnUserID nId, void* pCookie)
{
	//printf("User_LostUser: %d\n", nId);
	server.sendMessage(3, 2, nId);
}

int value;


void *server_data(void *arg)
{
	int len = 8*10;
	unsigned char *buff = (unsigned char*) malloc(len); //Command buffer
	
	while(_connected)
	{
		len = server.getData(buff, 1024);
		
		if(len > 0 && len % 6 == 0)
		{
			//Get the number of commands received
			int max = len / 6;
			int i;
			//For each command received
			for(i = 0; i < max; i++)
			{
				switch(buff[0 + (i*6)])
				{
					case 0: //CAMERA
						switch(buff[1 + (i*6)])
						{
							case 0: //GET USERMAP
								server.sendMessage(0, 0, compress_buffer, writtenBytesSize);
								//printf("Image size : %d bytes\n", writtenBytesSize);
							break;
						}
					break;					
				}
			}
		}
		else {
			printf("Client disconnected\n");
			_connected = 0;			
			server.wait_client();
		}
	}

	return NULL;
}

void server_connected()
{
	printf("Client connected\n");
	_connected = 1;
	if (pthread_create(&server_thread, NULL, &server_data, NULL))
	{
		fprintf(stderr, "Error on pthread_create() for SERVER\n");
	}
}

#define SAMPLE_XML_PATH "SamplesConfig.xml"

// - - - define error checking makros

#define CHECK_RC(nRetVal, what)										\
	if (nRetVal != XN_STATUS_OK)									\
	{																\
		printf("%s failed: %s\n", what, xnGetStatusString(nRetVal));\
		return nRetVal;												\
	}

int GetEncoderClsid(const WCHAR* format, CLSID* pClsid)
{
   UINT  num = 0;          // number of image encoders
   UINT  size = 0;         // size of the image encoder array in bytes

   ImageCodecInfo* pImageCodecInfo = NULL;

   GetImageEncodersSize(&num, &size);
   if(size == 0)
      return -1;  // Failure

   pImageCodecInfo = (ImageCodecInfo*)(malloc(size));
   if(pImageCodecInfo == NULL)
      return -1;  // Failure

   GetImageEncoders(num, size, pImageCodecInfo);

   for(UINT j = 0; j < num; ++j)
   {
      if( wcscmp(pImageCodecInfo[j].MimeType, format) == 0 )
      {
         *pClsid = pImageCodecInfo[j].Clsid;
         free(pImageCodecInfo);
         return j;  // Success
      }    
   }

   free(pImageCodecInfo);
   return -1;  // Failure
}


int main(int argc, char **argv)
{
	// Initialize GDI+.
   
	GdiplusStartupInput gdiplusStartupInput;
	ULONG_PTR gdiplusToken;
	GdiplusStartup(&gdiplusToken, &gdiplusStartupInput, NULL);

	// Get the CLSID of the PNG encoder.
	//GetEncoderClsid(L"image/jpeg", &encoderClsid);
	GetEncoderClsid(L"image/gif", &encoderClsid);

	//pNewMem = (LPVOID)GlobalAlloc(GMEM_FIXED, COMPRESS_BUFFER_SIZE);
	HRESULT result = CreateStreamOnHGlobal(NULL, TRUE, (LPSTREAM*)&stream);
	result = CreateStreamOnHGlobal(NULL, TRUE, (LPSTREAM*)&compressStream);	
	
	// - - - first compress

	ULARGE_INTEGER ulnSize;
	ULONG ulBytes;
	LARGE_INTEGER lnOffset;
    lnOffset.QuadPart = 0;

	//stream->Revert(); // clear stream
	imageBuffer = (Image*) new Bitmap(640, 480, PixelFormat24bppRGB); // load Image from stream

	//compressStream->Revert(); // clear compressStream
	compressStream->Seek(lnOffset, STREAM_SEEK_SET, NULL); // seek do begin of compressStream
	Status stat = imageBuffer->Save(compressStream, &encoderClsid, NULL); // save image to compressStream with encoder
	compressStream->Seek(lnOffset, STREAM_SEEK_END, &ulnSize); // seek to end of compressStream
	compressStream->Seek(lnOffset, STREAM_SEEK_SET, NULL); // seek to begin
	writtenBytesSize = (unsigned int)ulnSize.QuadPart; // get writtenBytesSize
	compressStream->Read(compress_buffer, (ULONG)ulnSize.QuadPart, &ulBytes); // read to img_buffer

	memset(&bitmapInfo, 0, sizeof(bitmapInfo));
	bitmapInfo.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
	bitmapInfo.bmiHeader.biWidth = 640;
	bitmapInfo.bmiHeader.biHeight = -480;
	bitmapInfo.bmiHeader.biPlanes = 1;
	bitmapInfo.bmiHeader.biCompression = BI_RGB;
	bitmapInfo.bmiHeader.biBitCount = 24;	

	// ------------------------------------------------
	
	// - - - OpenNI init

	XnStatus nRetVal = XN_STATUS_OK;

	// - - - init from args or xml-file

	if (argc > 1)
	{
		nRetVal = g_Context.Init();
		CHECK_RC(nRetVal, "Init");
		nRetVal = g_Context.OpenFileRecording(argv[1]);
		if (nRetVal != XN_STATUS_OK)
		{
			printf("Can't open recording %s: %s\n", argv[1], xnGetStatusString(nRetVal));
			return 1;
		}
	}
	else
	{
		nRetVal = g_Context.InitFromXmlFile(SAMPLE_XML_PATH);
		CHECK_RC(nRetVal, "InitFromXml");
	}

	// - - - find args and preset

	nRetVal = g_Context.FindExistingNode(XN_NODE_TYPE_DEPTH, g_DepthGenerator);

	CHECK_RC(nRetVal, "Find depth generator");

	nRetVal = g_Context.FindExistingNode(XN_NODE_TYPE_GESTURE, g_GestureGenerator);
	CHECK_RC(nRetVal, "Find gesture generator");

	nRetVal = g_Context.FindExistingNode(XN_NODE_TYPE_HANDS, g_UserGenerator);
	CHECK_RC(nRetVal, "Find hands generator");

	nRetVal = g_Context.FindExistingNode(XN_NODE_TYPE_USER, g_UserGenerator);
	CHECK_RC(nRetVal, "Find user generator");

	// - - - description callBacks
	XnCallbackHandle hHandsCallbacks, hGestureCallbacks, hUserCallbacks;
	
	// - - - create generators
	
	nRetVal = g_GestureGenerator.Create(g_Context); 
	nRetVal = g_HandsGenerator.Create(g_Context);
	
	// - - - register calbacks in generators
	g_GestureGenerator.RegisterGestureCallbacks(Gesture_Recognized, Gesture_Progress, NULL, hGestureCallbacks);
	g_HandsGenerator.RegisterHandCallbacks(Hand_Create, Hand_Update, Hand_Destroy, NULL, hHandsCallbacks); 
	g_UserGenerator.RegisterUserCallbacks(User_NewUser, User_LostUser, NULL, hUserCallbacks);

	// - - - start generating all
	nRetVal = g_Context.StartGeneratingAll();
	CHECK_RC(nRetVal, "StartGenerating");

	// - - - add gestures
	addGestures();

	// - - - set smothing

	g_HandsGenerator.SetSmoothing(0.1);

	// - - - create server
	server = as3Network();
	server.init(server_connected);

	// - - - while _die == 0
	while(!_die)
	{
		if (_connected != 0)
		{
			// - - - update all
			g_Context.WaitAndUpdateAll();
			
			//getUsers();
			getUsersPixels(img_buffer);
			compress(img_buffer, compress_buffer);
		}
	}

	delete stream;
	delete compressStream;
	delete imageBuffer;
	
	GdiplusShutdown(gdiplusToken);
}