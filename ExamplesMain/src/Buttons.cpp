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
/*
 * Simple button interface supporting selection by pointer or number keys
 */
#include "ExamplesMain.h"
#include <malloc.h>

static Button* g_SelectedButton = 0;
static Button* g_ButtonsHead = 0;
static Button* g_ButtonsTail = 0;
static int     g_NumButtons = 0;
static uint    g_ButtonScale = 1;
static int     g_YBelowButtons = 50;

Button* NewButton(const char *name, ButtonCallback callback)
{
    Button* button = (Button*)malloc(sizeof(Button));

    button->m_Next = 0;
    button->m_Name = strdup(name);
    button->m_Enabled = true;
    button->m_Display = true;
    button->m_Index = g_NumButtons;
    button->m_Callback = callback;
    button->m_Key = S3E_KEY_INVALID;
    button->m_XPos = 0;
    button->m_YPos = 0;
    button->m_Width = 0;
    button->m_Height = 0;

    if (g_NumButtons < 10)
    {
        if (s3eKeyboardGetInt(S3E_KEYBOARD_HAS_NUMPAD))
            button->m_Key = (s3eKey)((int)s3eKey1 + (g_NumButtons==9?-1:g_NumButtons));
        else if (!s3ePointerGetInt(S3E_POINTER_AVAILABLE))
            button->m_Key = (s3eKey)((int)s3eKeyAbsGameA + g_NumButtons);        
    }
    g_NumButtons++;

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
    g_NumButtons = 0;
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

void SetButtonName(Button* button, const char *name)
{
    free(button->m_Name);
    button->m_Name = strdup(name);
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

        // Store button's position and size
        iter->m_XPos = _x0;
        iter->m_YPos = _y0;
        iter->m_Width = _w;
        iter->m_Height = _h;

        y = y + textHeight * 2;
    }

    if (g_SelectedButton && g_SelectedButton->m_Callback)
        g_SelectedButton->m_Callback(g_SelectedButton);

    if (previousDebugTextSize != fontScale)
        s3eDebugSetInt(S3E_DEBUG_FONT_SCALE, previousDebugTextSize);

    g_YBelowButtons = y;
}
