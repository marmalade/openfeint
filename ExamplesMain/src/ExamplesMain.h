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

#include "s3e.h"
#include <string.h>
#include <stdio.h>



/**
 * Prints a text message on the current surface.
 * Functions exactly like @ref s3eDebugPrint but takes printf-style
 * arguments.
 */
S3E_EAPI void s3eDebugPrintf(int x, int y, s3eBool wrap, const char* fmt, ...);

/**
 * Write to the trace output.
 * Functions exactly like @ref s3eDebugTraceLine but takes printf-style
 * arguments.
 */
S3E_EAPI int s3eDebugTracePrintf(const char* fmt, ...);

typedef void (*ButtonCallback)(struct Button* button);

/**
 * Structure to represent an on-screen button which can be
 * "pressed" using either touch or keyboard controls.
 * Position values are updated each time the button
 * is rendered.
 */
struct Button
{
    Button* m_Next;
    char*   m_Name;
    bool    m_Enabled;
    bool    m_Display;
    s3eKey  m_Key;
    int     m_Index;
    int     m_XPos;
    int     m_YPos;
    int     m_Width;
    int     m_Height;
    ButtonCallback m_Callback;
};

extern bool g_DeviceHasKeyboard;
extern bool g_HideDisabledButtons;
extern bool g_doRender1;

void ExamplesMainInit();
bool ExamplesMainUpdate();
void ExamplesMainTerm();

// Functions which examples must implement
void ExampleInit();
void ExampleTerm();
void ExampleRender();
bool ExampleUpdate();
bool ExampleCheckQuit();
void ButtonsRender();
void DontClearScreen();
void DontDrawCursor();

/**
 * Create and new button and return a pointer to it.
 */
Button* NewButton(const char *name, ButtonCallback callback=NULL);

/**
 * Delete all buttons and free memory allocated for them.
 */
void DeleteButtons();

/**
 * Return a pointer to whichever button is currently pressed, or NULL
 * if no button is pressed.
 */
Button *GetSelectedButton();

/**
 * Get the first Y coordinate below the bottom of the last button.
 */
int GetYBelowButtons();

/**
 * Set the scale factor for the display of all buttons.
 */
void SetButtonScale(uint scale);

/**
 * Get the scale factor for the display of all buttons.
 */
uint GetButtonScale();

/**
 * Set button name safely.
 * Frees old string and re-allocates memory for the new one.
 */
void SetButtonName(Button* button, const char *name);

/**
 * Returns true if the touch-screen version of buttons is being used.
 * This is determined automatically based on the device hardware:
 * touch screen buttons are used if the device supports them.
 */
bool IsUsingPointerButtons();

/**
 * Initialise message printing system. Display last numMessages messages, each of max length
 * messageLen (including null terminator).
 */
void InitMessages(int numMessages, int messageLen);

/**
 * Clear all messsages in the queue.
 */
void ClearMessages();

/**
 * Add a message to the list of messages to be displayed by PrintMessages().
 */
void AppendMessage(const char* src, ...);

typedef enum Colour
{
    WHITE,
    BLACK,
    BLUE,
    GREEN,
    RED,
} Colour;

void AppendMessageColour(Colour colour, const char* src, ...);

/**
 * Print all messages in list, newest at top.
 * x and y specify location to print first message at.
 * Returns y position of last message printed.
 */
int PrintMessages(int x, int y);

/**
 * Free memory allocated by InitMessages().
 */
void TerminateMessages();

/**
 * Draw a rectangle on the screen.
 */
void DrawRect(int x, int y, int width, int height, uint8 r, uint8 g, uint8 b);
