This folder contains two "hello world" projects that demonstrate the two main
ways of drawing in Marmalade.

s3eHelloWorld demonstrates addressing the software surface using the s3eSurface
API. This API exposes a (more or less) direct pointer to the surface buffer so
applications can push pixel values directly. Note that more recent devices with
GPUs tend to expect applications to use hardware rendering and this surface
pointer tends to be much less direct and much slower (this is especially
true on iOS). 

IwGxHelloWorld demonstrates using Marmalade Studio's IwGx API to draw the hello
world string. This API will be hardware rendered on devices with GPUs.

Marmalade applications can also use OpenGL ES directly, but that hello world is
excluded due to the lack of a text drawing API. The normal GL equivalent is a
spinning cube. You can find that example in examples/s3e/s3eGLES1 or
examples/IwGL/IwGLES1 for a version running through Marmalade's OpenGL ES 
helper module, IwGL.
