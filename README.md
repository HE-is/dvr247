# dvr247

Hey! This is my sloppy linux screen snapshot recorder dvr247 thing-o.

You should be able to figure out by my comments in the perl script, but here's an overview:

Try running `xinput list`.
Attempt to find your keyboard by trying different IDs from the list through issuing this ccommand, `xinput test <id>`.
So through xinput, we can watch the keyboard for our desired keys to either quit/save cut/refresh buffer.

Quit will stop the script.
The "saving a cut" just stops the buffer and saves a cut of the last n seconds of the video buffer.
"Refresh buffer" will stop, delete and then start the buffer again. (This is just if you're worried about disk space, and it's manual because I didn't want it to "refresh" automatically every like 3min or so because it may refresh in the middle of a desired clip/cut.

Xinput is threaded into it's own virtual pty, loops to check for the quit/refresh/save keys.

You may need to change the ffmpeg command to match your pulseaudio/alsa settings... as you are 4k res I think, and the loopback for recording sound will be different.

Oh and I'm using pkill to stop the ffmpeg video buffer... I tried messing around with echoing the "q" key to ffmpeg, but I stopped as I wasn't getting anywhere. (example: `echo "s" > /dev/pts/11`)

Hopefully this is useful for you!
