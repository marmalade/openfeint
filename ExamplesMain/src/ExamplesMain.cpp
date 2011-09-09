/*
 * This file is part of the Marmalade SDK Code Samples.
 *
 * Copyright (C) 2001-2011 Ideaworks3D Ltd.
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
#include "ExamplesMain.h"
#include <malloc.h>


#define FRAMETIME  30

static void CursorRender();
static void SoftkeysRender();

//Will be set to true if the device has a keyboard or number pad
bool            g_DeviceHasKeyboard = false;
static bool     g_ClearScreen = true;
static bool     g_DrawCursor = true;
bool            g_HideDisabledButtons = false;
bool g_doRender1 = false;

bool ExamplesMainUpdate()
{
    s3eKeyboardUpdate();
    s3ePointerUpdate();

	if (g_doRender1)
	{
    if (!ExampleUpdate())
    {
        s3eDebugTracePrintf("ExampleUpdate returned false, exiting..");
        return false;
    }

    if (g_ClearScreen)
        s3eSurfaceClear(0xff,0xff,0xff);

    ExampleRender();
    ButtonsRender();
    SoftkeysRender();

    if (g_DrawCursor)
        CursorRender();

    s3eSurfaceShow();
	}
	
    s3eDeviceYield(FRAMETIME);
    return true;
}

void ExamplesMainTerm()
{
    DeleteButtons();
    TerminateMessages();

    ExampleTerm();
}

void ExamplesMainInit()
{
	g_doRender1 = true;
    // Determine if the device has a keyboard
    if (s3eKeyboardGetInt(S3E_KEYBOARD_HAS_KEYPAD) || s3eKeyboardGetInt(S3E_KEYBOARD_HAS_ALPHA))
        g_DeviceHasKeyboard = true;

    int scale = 1;
    // Set default button size relative to screen resolution
    if (s3eSurfaceGetInt(S3E_SURFACE_WIDTH) < 320 || s3eSurfaceGetInt(S3E_SURFACE_HEIGHT) < 320)
        scale = 1;
    else if (s3eSurfaceGetInt(S3E_SURFACE_WIDTH) < 480 || s3eSurfaceGetInt(S3E_SURFACE_HEIGHT) < 480)
        scale = 2;
    else
        scale = 3;

    SetButtonScale(scale);

    // Scale font up to be easier to read
    int fontScale = scale > 1 ? scale-1 : 1;
    s3eDebugSetInt(S3E_DEBUG_FONT_SCALE, fontScale);

    ExampleInit();
}

bool ExampleCheckQuit()
{
    bool rtn = s3eDeviceCheckQuitRequest()
    || (s3eKeyboardGetState(s3eKeyEsc) & S3E_KEY_STATE_PRESSED)
    || (s3eKeyboardGetState(s3eKeyAbsBSK) & S3E_KEY_STATE_PRESSED);
    if (rtn)
        s3eDebugTracePrintf("quiting example");
    return rtn;
}

void DontClearScreen()
{
    g_ClearScreen = false;
}

void DontDrawCursor()
{
    g_DrawCursor = false;
}

bool IsUsingPointerButtons()
{
    return !g_DeviceHasKeyboard;
}

void DrawRect(int x, int y, int width, int height, uint8 r, uint8 g, uint8 b)
{
    int right = x + width;
    int bottom = y + height;
    int pitch = s3eSurfaceGetInt(S3E_SURFACE_PITCH);
    if (x < 0)
        x = 0;
    if (y < 0)
        y = 0;
    if (right > (int32)s3eSurfaceGetInt(S3E_SURFACE_WIDTH))
        right = s3eSurfaceGetInt(S3E_SURFACE_WIDTH);
    if (bottom > (int32)s3eSurfaceGetInt(S3E_SURFACE_HEIGHT))
        bottom = s3eSurfaceGetInt(S3E_SURFACE_HEIGHT);

    uint16* pSurface = (uint16*)s3eSurfacePtr();
    pitch /= 2;
    uint16 colour = (uint16)s3eSurfaceConvertRGB(r,g,b);

    if (((right - x) & 0x3) == 0)
    {
        for (int _y = y; _y < bottom; _y++)
        {
            uint16* p = pSurface + _y*pitch + x;
            uint16* pEnd = p + right - x;

            do
            {
                *p++ = colour;
                *p++ = colour;
                *p++ = colour;
                *p++ = colour;
            } while (p != pEnd);
        }
    }
    else
    {
        for (int _y = y; _y < bottom; _y++)
        {
            uint16* p = pSurface + _y*pitch + x;
            uint16* pEnd = p + right - x;

            do
            {
                *p++ = colour;
            } while (p != pEnd);
        }
    }
}

static void SoftkeyRender(const char* text, s3eDeviceSoftKeyPosition pos, void(*handler)())
{
    // Get area of text displayed
    int width = s3eDebugGetInt(S3E_DEBUG_FONT_SIZE_WIDTH);
    int height = s3eDebugGetInt(S3E_DEBUG_FONT_SIZE_HEIGHT);
    width *= strlen(text) - 8; //-8 to ignore colour flag (e.g. "`x666666")

    // Expand area by half text height to make easier to click
    width += height;
    height += height;

    int x = 0;
    int y = 0;
    switch (pos)
    {
        case S3E_DEVICE_SOFTKEY_BOTTOM_LEFT:
            y = s3eSurfaceGetInt(S3E_SURFACE_HEIGHT) - height;
            x = 0;
            break;
        case S3E_DEVICE_SOFTKEY_BOTTOM_RIGHT:
            y = s3eSurfaceGetInt(S3E_SURFACE_HEIGHT) - height;
            x = s3eSurfaceGetInt(S3E_SURFACE_WIDTH) - width;
            break;
        case S3E_DEVICE_SOFTKEY_TOP_RIGHT:
            y = 0;
            x = s3eSurfaceGetInt(S3E_SURFACE_WIDTH) - width;
            break;
        case S3E_DEVICE_SOFTKEY_TOP_LEFT:
            x = 0;
            y = 0;
            break;
    }
    s3eDebugPrint(x + (height/4), y + (height/4), text, 0); // place in centre of touchable area
    if (s3ePointerGetState(S3E_POINTER_BUTTON_SELECT) & S3E_POINTER_STATE_PRESSED)
    {
        int pointerx = s3ePointerGetX();
        int pointery = s3ePointerGetY();
        if (pointerx >= x && pointerx <= x+width && pointery >=y && pointery <= y+height)
            handler();
    }
}

static void SoftkeysRender()
{
    //int advance = s3eDeviceGetInt(S3E_DEVICE_ADVANCE_SOFTKEY_POSITION);
    //SoftkeyRender("`x666666ASK", (s3eDeviceSoftKeyPosition)advance);
    int back = s3eDeviceGetInt(S3E_DEVICE_BACK_SOFTKEY_POSITION);
    SoftkeyRender("`x666666Exit", (s3eDeviceSoftKeyPosition)back, s3eDeviceRequestQuit);
}

static void CursorRender()
{
    if (!s3ePointerGetInt(S3E_POINTER_AVAILABLE))
        return;

    uint16* ptr = (uint16*)s3eSurfacePtr();
    int height = s3eSurfaceGetInt(S3E_SURFACE_HEIGHT);
    int width = s3eSurfaceGetInt(S3E_SURFACE_WIDTH);
    int pitch = s3eSurfaceGetInt(S3E_SURFACE_PITCH);

    int pointerx = s3ePointerGetX();
    int pointery = s3ePointerGetY();

    pointerx = (pointerx > width)?width-1:pointerx;
    pointery = (pointery > height)?height-1:pointery;

    int cursor_size = 10;

    for (int y = pointery-cursor_size; y < pointery+cursor_size; y++)
    {
        if (y < 0 || y >= height)
            continue;
        int location = y*pitch/sizeof(uint16) + pointerx;
        ptr[location] = 0x5555;
    }

    for (int x = pointerx-cursor_size; x < pointerx+cursor_size; x++)
    {
        if (x < 0 || x >= width)
            continue;
        int location = pointery*pitch/sizeof(uint16) + x;
        ptr[location] = 0x5555;
    }
}

//-----------------------------------------------------------------------------
// Helper functions print messages to the screen
//-----------------------------------------------------------------------------

static int g_NumMessages = 0;
static int g_MessageLen = 0;
static char** g_Messages = NULL;
static int g_MessageIdx = -1;
static bool g_LoopMessages = false;

void InitMessages(int numMessages, int messageLen)
{
    if (numMessages < 1)
        return;

    g_NumMessages = numMessages;
    g_MessageLen = messageLen;
    g_MessageIdx = -1;

    g_Messages = (char**)malloc(sizeof(char*)*numMessages);

    for (int i = 0; i < numMessages; i++)
    {
        g_Messages[i] = (char*)malloc(sizeof(char)*messageLen);
        g_Messages[i][0] = '\0';
        g_Messages[i][messageLen-1] = '\0'; // Make sure string is null terminated
    }
}

void ClearMessages()
{
    g_MessageIdx = -1;

    for (int i = 0; i < g_NumMessages; i++)
        g_Messages[i][0] = '\0';
}

void TerminateMessages()
{
    if (!g_NumMessages)
        return;

    for (int i = 0; i < g_NumMessages; i++)
        free(g_Messages[i]);

    free(g_Messages);
    g_Messages = NULL;
    g_NumMessages = 0;
}

static void AppendMessageColourV(Colour colour, const char* fmt, va_list args)
{
    if (!g_NumMessages)
        return;

    // Add message to the array in a circlular manner, overwriting older messages when array is full
    g_MessageIdx += 1;

    if (g_MessageIdx == g_NumMessages)
        g_LoopMessages = true;

    g_MessageIdx = g_MessageIdx % g_NumMessages;
    char* message = g_Messages[g_MessageIdx];

    const char* colourStr;
    switch (colour)
    {
        case BLUE:
            colourStr = "`x6666ee";
            break;
        case GREEN:
            colourStr = "`x66ee66";
            break;
        case RED:
            colourStr = "`xee6666";
            break;
        case WHITE:
            colourStr = "`x000000";
            break;
        case BLACK:
        default:
            colourStr = "`x666666";
            break;
    }

    strcpy(message, colourStr);
    vsnprintf(message+8, g_MessageLen-8-1, fmt, args);
    s3eDebugTracePrintf("Append Message: %s", message+8);
}

void AppendMessageColour(Colour colour, const char* fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    AppendMessageColourV(colour, fmt, args);
    va_end(args);
}

void AppendMessage(const char* fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    AppendMessageColourV(BLACK, fmt, args);
    va_end(args);
}

int PrintMessages(int x, int y)
{
    if (!g_NumMessages || g_MessageIdx == -1)
        return -1;

    char* currentMsg;

    for (int i=0, j = g_MessageIdx; i < g_NumMessages; i++, j = (j + (g_NumMessages-1)) % g_NumMessages)
    {
        // Avoid overlapping exit button
        if (y > s3eSurfaceGetInt(S3E_SURFACE_HEIGHT) - (s3eDebugGetInt(S3E_DEBUG_FONT_HEIGHT)*2))
            break;

        if (j > g_MessageIdx && !g_LoopMessages)
            continue;

        currentMsg = g_Messages[j];
        if (currentMsg[0])
        {
            s3eDebugPrintf(x, y, 0, "%s", currentMsg);

            if (i != g_NumMessages -1)
                y += s3eDebugGetInt(S3E_DEBUG_FONT_HEIGHT)+2;
        }
    }

    return y;
}
