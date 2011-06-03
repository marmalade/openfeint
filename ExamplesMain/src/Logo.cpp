/*
 * This file is part of the Airplay SDK Code Samples.
 *
 * Copyright (C) 2001-2010 Ideaworks3D Ltd.
 * All Rights Reserved.
 *
 * This source code is intended only as a supplement to Ideaworks Labs
 * Development Tools and/or on-line documentation.
 *
 * THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
 * KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
 * PARTICULAR PURPOSE.
 */
#include "Logo.h"

#define LOGOWIDTH  128
#define LOGOHEIGHT 21
#define LOGO_Y_OFFSET 10

static void* g_LogoData; // pointer to image data

/*
 * Loads image data for displaying
 */
void LogoInit()
{
	// Load raw image data from file
	s3eFile* NewFile = s3eFileOpen("logo.raw", "rb");

	// Reserve memory for image data
	int32 FileSize = s3eFileGetSize(NewFile);
	g_LogoData = s3eMallocBase(FileSize);

	// Clear memory
	memset(g_LogoData, 0, FileSize);

	// Fill data area with image data
	s3eFileRead(g_LogoData, FileSize, 1, NewFile);

	// Reading finished the image data file can now be closed
	s3eFileClose(NewFile);
}

/*
 * Frees the image data
 */
void LogoShutDown()
{
	s3eFreeBase(g_LogoData);
}

/*
 * Displays the Airplay logo centered on the top of the screen
 */
void LogoRender()
{
	// Pointer to screen
	uint16* screen = (uint16*)s3eSurfacePtr();
	int height = s3eSurfaceGetInt(S3E_SURFACE_HEIGHT);
	int width = s3eSurfaceGetInt(S3E_SURFACE_WIDTH);
	int pitch = s3eSurfaceGetInt(S3E_SURFACE_PITCH);

	// Clear screen
	for (int i=0;i < height; i++)
	{
		memset((char*)screen + pitch * i, 255, (width * 2));
	}

	// Calculate center position of logo
	int32 xPos = (width-LOGOWIDTH)/2;

	// Generate pointer to image data
	uint16* logoPtr = (uint16*) g_LogoData;

	// Calculate the first row of the logo
	uint16* row = screen+(LOGO_Y_OFFSET*pitch/2);

	// Blit image data onto the screen area
	for (int y = 0; y < LOGOHEIGHT; y++)
	{
		for (int x = 0; x < LOGOWIDTH; x++)
		{
			row[x + xPos] = *logoPtr++;
		}
		row += pitch/2;
	}
}
