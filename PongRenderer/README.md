## Directory Info

This is all of the VHDL source (and constraints and such) needed to properly create the Vivado project that
is able to compile and upload the bitstream necessary to run the pong renderer. By itself you cannot just open
this in Vivado (thanks by the way, nice use of absolute paths), instead you have to properly create a Vivado project
and place all of these files into the source directories and such.

The directories inside of 'sources' can be directly added as directories when importing sources, and the constraint file
can be directly selected when importing the constraint files. This handles the IP sources (generated when generating the bitstream)
and properly places everything where it is needed to create a working project.

Ensure that the generated projects name is 'PongRendererProject' so that it is properly ignored by git.