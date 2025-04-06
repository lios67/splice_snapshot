Splice Snapshot
=====================

A simple tool to extract frames from video files and export them as a ZIP.

How to Use
----------
1. Windows(64-bit):
   - Extract the ZIP file (VideoFrameExtractor_Win.zip).
   - Double-click "splice_snapshot.exe" to launch the app.
   - Click the video icon to select a video file.
   - You will see the selected video showing 1 frame for every second. 
   - Set the extraction interval (e.g., "1", "0.4", etc.) and click "Refresh" to extract new frames.
   - Use arrow keys or scroll to browse frames, and click "Export ZIP" to save them as a collection of png files.

Requirements
------------
- No additional software needed! FFmpeg is included for frame extraction.
- Supported on Windows 64-bit and Linux 64-bit only.

Notes
-----
- Frames are saved temporarily and cleared when you pick a new video.
- Ensure your video file is in a supported format (e.g., MP4, AVI).
- Make sure the video is not to big. (GB<1.5 for faster loading times)
- Make sure to check on the amount of frames extracted, too much and it will eat all of your ram.(In my testing I have 32GM of ram and it took all of it when the frames was too much for memory)

License
-------
- This app uses Flutter and FFmpeg. FFmpeg is under the GPL (v3 or later). See LICENSE.txt for details.

Support
-------
- For issues, contact oscar.lin9675@gmail.com or https://github.com/lios67.