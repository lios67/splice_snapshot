# Video Frame Extractor

A simple tool to *extract frames* from video files and export them as a ZIP.

## How to Use

### Windows (64-bit)
- Extract `VideoFrameExtractor_Win.zip`.
- Double-click `video_frame_extractor.exe`.
- Click the video icon, pick a video, set an interval (e.g., "1"), and click "Refresh".
- You will see the selected video showing 1 frame for every second.
- Set the extraction interval (e.g., "1", "0.4", etc.) and click "Refresh" to extract new frames.
- Browse frames with arrow keys or scroll wheel.
- Delete any fames that are not needed.
- Then click "Export ZIP".

### Linux (64-bit)
- Extract: `tar -xzf VideoFrameExtractor_Linux.tar.gz`.
- In a terminal: `cd VideoFrameExtractor_Linux`.
- Run the app: `./splice_snapshot` or Double-click "splice_snapshot.exe" to launch the app.
- Follow the same steps as above.

## Requirements
- FFmpeg is included—no extra install needed!
- Supported on Windows 64-bit and Linux 64-bit only.

## Notes
- Frames are saved temporarily and cleared when you pick a new video.
- Ensure your video file is in a supported format (e.g., MP4, AVI).
- Make sure the video is not to big. (GB<1.5 for faster loading times)
- Make sure to check on the amount of frames extracted, too much and it will eat all of your ram.(In my testing I have 32GM of ram and it took all of it when the frames was too much for memory)

##License
- This app uses Flutter and FFmpeg. FFmpeg is under the GPL (v3 or later). See LICENSE.txt for details.

##Support
- For issues, contact oscar.lin9675@gmail.com or https://github.com/lios67.
