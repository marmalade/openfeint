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

 /**
 * @page ExampleIwGxHelloWorld IwGx Hello World Example
 *
 * The following example, in typical Hello World style, displays the phrase
 * "Hello, World!" on screen.
 *
 * The functions required to achieve this are:
 * Printing the text to screen:
 * <ul>
 *   <li>IwGxPrintString()
 * </ul
 *
 * Standard IwGx API:
 * <ul>
 *   <li>IwGxInit()
 *   <li>IwGxTerminate()
 *   <li>IwGxSetColClear()
 *   <li>IwGxFlush()
 *   <li>IwGxSwapBuffers()
 * </ul>
 *
 * Device interoperability through the s3e API:
 *
 * <ul>
 *   <li>s3eDeviceCheckQuitRequest()
 *   <li>s3eDeviceYield()
 * </ul>
 *
 * All examples will follow this basic pattern; a brief description of what
 * the example does will be given followed by a list of all the important
 * functions and, perhaps, classes.
 *
 * Should the example be more complex, a more detailed explanation of what the
 * example does and how it does it will be added. Note that most examples
 * use an example framework to remove boilerplate code and allow the projects
 * to be made up of a single source file for easy viewing. This framework can
 * be found in the examples/s3e/ExamplesMain directory.
 *
 * @include IwGxHelloWorld.cpp
 */
 
// Include the single header file for the IwGx module
#include "IwGx.h"

// Standard C-style entry point. This can take args if required.
int main()
{
    // Initialise the IwGx drawing module
    IwGxInit();

    // Set the background colour to (opaque) blue
    IwGxSetColClear(0, 0, 0xff, 0xff);

    // Loop forever, until the user or the OS performs some action to quit the app
    while(!s3eDeviceCheckQuitRequest())
    {
        // Clear the surface
        IwGxClear();

        // Use the built-in font to display a string at coordinate (120, 150)
        IwGxPrintString(120, 150, "Hello, World!");

        // Standard EGL-style flush of drawing to the surface
        IwGxFlush();

        // Standard EGL-style flipping of double-buffers
        IwGxSwapBuffers();
        
        // Sleep for 0ms to allow the OS to process events etc.
        s3eDeviceYield(0);
    }
    
    // Shut down the IwGx drawing module
    IwGxTerminate();

    // Return
    return 0;
}





