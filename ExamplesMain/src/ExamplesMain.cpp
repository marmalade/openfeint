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

#include "ExamplesMain.h"
#include "Logo.h"
#include <malloc.h>

#define FRAMETIME  30

static void CursorRender();
static void SoftkeysRender();

//Will be set to true if the device has a keyboard or number pad
bool            g_DeviceHasKeyboard = false;
static Button*  g_SelectedButton = 0;
static uint     g_ButtonScale = 1;
static int      g_YBelowButtons = 50;
static Button*  g_ButtonsHead = 0;
static Button*  g_ButtonsTail = 0;
static int      g_nButtons = 0;
static bool     g_ClearScreen = true;
static bool     g_DrawCursor = true;
bool            g_HideDisabledButtons = false;

//-----------------------------------------------------------------------------
// Main global function
//-----------------------------------------------------------------------------
int main()
{
    LogoInit();

    // Determine if the device has a keyboard
    if (s3eKeyboardGetInt(S3E_KEYBOARD_HAS_KEYPAD) || s3eKeyboardGetInt(S3E_KEYBOARD_HAS_ALPHA))
        g_DeviceHasKeyboard = true;

    // Set default button size relative to screen resolution
    if (s3eSurfaceGetInt(S3E_SURFACE_WIDTH) < 320 || s3eSurfaceGetInt(S3E_SURFACE_HEIGHT) < 320)
        g_ButtonScale = 1;
    else if (s3eSurfaceGetInt(S3E_SURFACE_WIDTH) < 480 || s3eSurfaceGetInt(S3E_SURFACE_HEIGHT) < 480)
        g_ButtonScale = 2;
    else
        g_ButtonScale = 3;

    // Scale font up to be easier to read
    int fontScale = g_ButtonScale > 1 ? g_ButtonScale-1 : 1;
    s3eDebugSetInt(S3E_DEBUG_FONT_SCALE, fontScale);

    ExampleInit();

    // Example main loop
    while (!ExampleCheckQuit())
    {
        s3eKeyboardUpdate();
        s3ePointerUpdate();

        if (!ExampleUpdate())
        {
            s3eDebugTracePrintf("ExampleUpdate returned false, exiting..");
            break;
        }

        if (g_ClearScreen)
            LogoRender();

        ExampleRender();
        ButtonsRender();
        SoftkeysRender();

        if (g_DrawCursor)
            CursorRender();

        s3eSurfaceShow();
        s3eDeviceYield(FRAMETIME);
    }

    DeleteButtons();
    TerminateMessages();

    ExampleShutDown();
    LogoShutDown();
    return 0;
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


//-----------------------------------------------------------------------------
// Simple button interface supporting selection by pointer or number keys
//-----------------------------------------------------------------------------

Button* NewButton(const char *name, ButtonCallback callback)
{
    Button* button = (Button*)malloc(sizeof(Button));

    button->m_Next = 0;
    button->m_Name = strdup(name);
    button->m_Enabled = true;
    button->m_Display = true;
    button->m_Index = g_nButtons;
	button->m_Callback = callback;
	button->m_Key = S3E_KEY_INVALID;

    if (g_nButtons <= 10)
    {
        if (s3eKeyboardGetInt(S3E_KEYBOARD_HAS_NUMPAD))
            button->m_Key = (s3eKey)((int)s3eKey1 + g_nButtons++);
        else if (!s3ePointerGetInt(S3E_POINTER_AVAILABLE))
            button->m_Key = (s3eKey)((int)s3eKeyAbsGameA + g_nButtons++);
    }

    if (g_ButtonsTail)
        g_ButtonsTail->m_Next = button;
    else
        g_ButtonsHead = button;

    g_ButtonsTail = button;
    return button;
}

void DeleteButtons()
{
    while (g_ButtonsHead)
    {
        Button* del = g_ButtonsHead;
        g_ButtonsHead = g_ButtonsHead->m_Next;
        free(del->m_Name);
        free(del);
    }

    g_SelectedButton = 0;
    g_ButtonsHead = 0;
    g_ButtonsTail = 0;
    g_nButtons = 0;
}

void SetButtonScale(uint scale)
{
	if (scale)
		g_ButtonScale = scale;
	else
		g_ButtonScale = 1;
}

uint GetButtonScale()
{
    return g_ButtonScale;
}

Button *GetSelectedButton()
{
    return g_SelectedButton;
}

int GetYBelowButtons()
{
    return g_YBelowButtons;
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

void ButtonsRender()
{
    int previousDebugTextSize = s3eDebugGetInt(S3E_DEBUG_FONT_SCALE);
    int fontScale = g_ButtonScale;
    char buf[128];

    // select double sized text
    if (previousDebugTextSize != (int)g_ButtonScale)
        s3eDebugSetInt(S3E_DEBUG_FONT_SCALE, g_ButtonScale);

    // find out the dimensions of the font
    const int textWidthDefault = s3eDebugGetInt(S3E_DEBUG_FONT_SIZE_WIDTH);
    const int textHeight = s3eDebugGetInt(S3E_DEBUG_FONT_SIZE_HEIGHT);  

    // get the current pointer position and selection state
    int pointerX = s3ePointerGetX();
    int pointerY = s3ePointerGetY();
    s3ePointerState pointerState = s3ePointerGetState(S3E_POINTER_BUTTON_SELECT);

    int x = 10;
    int y = 50;

    g_SelectedButton = 0;

    // draw the buttons
    for (Button* iter = g_ButtonsHead; iter; iter = iter->m_Next)
    {
        if (!iter->m_Display)
            continue;

        if (g_HideDisabledButtons && !iter->m_Enabled)
            continue;

        fontScale = g_ButtonScale;
        int textWidth = textWidthDefault;
        if (s3eDebugGetInt(S3E_DEBUG_FONT_SCALE) != fontScale)
            s3eDebugSetInt(S3E_DEBUG_FONT_SCALE, fontScale);

        if (iter->m_Key != S3E_KEY_INVALID)
        {
            if (s3eKeyboardGetState(iter->m_Key) & S3E_KEY_STATE_PRESSED)
            {
                g_SelectedButton = iter;
                s3eDebugTracePrintf("button selected using key");
            }
        }

        if (iter->m_Key != S3E_KEY_INVALID)
        {
            char keyName[32];
            s3eKeyboardGetDisplayName(keyName, iter->m_Key);
            if (iter->m_Enabled)
                snprintf(buf, sizeof(buf), "`x000000%s: %s", keyName, iter->m_Name);
            else
                snprintf(buf, sizeof(buf), "`xa0a0a0%s: %s", keyName, iter->m_Name);
        }
        else
        {
            if (iter->m_Enabled)
                snprintf(buf, sizeof(buf), "`x000000%s", iter->m_Name);
            else
                snprintf(buf, sizeof(buf), "`xa0a0a0%s", iter->m_Name);
        }

        int len = strlen(buf) - 8;
        int _x0 = x - 2;
        int _y0 = y - 4;
        int _h = textHeight + 4;
        int _y1 = _y0 + _h;
        int _w;
        int _x1;
        int textOffset = 0;
        
        // Scale down font size if button contents are too long for screen
        while (true)
        {
            _w = (textWidth * len) + 8;
            _x1 = _x0 + _w;

            if (fontScale == 1 || _x1 <= s3eSurfaceGetInt(S3E_SURFACE_WIDTH))
                break;

            fontScale -= 1;
            s3eDebugSetInt(S3E_DEBUG_FONT_SCALE, fontScale);
            textWidth = s3eDebugGetInt(S3E_DEBUG_FONT_SIZE_WIDTH);
            textOffset += (textHeight-s3eDebugGetInt(S3E_DEBUG_FONT_SIZE_HEIGHT))/2;
        }

        if (pointerX >= _x0 && pointerX <= _x1 &&
            pointerY >= _y0 && pointerY <= _y1 && iter->m_Enabled)
        {
            if (pointerState & S3E_POINTER_STATE_DOWN)
                DrawRect(_x0, _y0, _w, _h, 0, 255, 0);
            else
                DrawRect(_x0, _y0, _w, _h, 255, 0, 0);

            if (pointerState & S3E_POINTER_STATE_RELEASED)
                g_SelectedButton = iter;
        }
        else
        {
            if (iter->m_Enabled)
                DrawRect(_x0, _y0, _w, _h, 255, 0, 0);
            else
                DrawRect(_x0, _y0, _w, _h, 127, 0, 0);
        }

        s3eDebugPrint(x, y+textOffset,  buf, 0);

        y = y + textHeight * 2;
    }

	if (g_SelectedButton && g_SelectedButton->m_Callback)
		g_SelectedButton->m_Callback(g_SelectedButton);

    if (previousDebugTextSize != fontScale)
        s3eDebugSetInt(S3E_DEBUG_FONT_SCALE, previousDebugTextSize);

    g_YBelowButtons = y;
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
