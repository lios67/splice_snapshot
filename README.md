# Splice Snapshot

A simple tool to *extract frames* from video files and export them as a ZIP of png image files.

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

## Use Cases
- **Video Analysis**: Extract frames every x seconds to study motion in wildlife footage.
- **Motion Analysis**: Extract frames every x seconds to study motion in realworld footage or animations.
- **Thumbnails**: Grab frames every x seconds to pick the perfect YouTube thumbnail.
- **GIF Creation**: Pull frames every x seconds from a funny clip for a quick GIF.
- **Education**: Use frames every x seconds to teach physics with a dropping ball video.
- **Art**: Collect frames every x seconds for a nature-inspired collage.

## Notes
- Frames are saved temporarily and cleared when you pick a new video.
- Ensure your video file is in a supported format (e.g., MP4, AVI).
- Make sure the video is not to big. (GB<1.5 for faster loading times)
- Make sure to check on the amount of frames extracted, too much and it will eat all of your ram.(In my testing I have 32GM of ram and it took all of it when the frames was too much for memory)

## License
- This app uses Flutter and FFmpeg. FFmpeg is under the GPL (v3 or later). See LICENSE.txt for details.

## Support
- For issues, contact oscar.lin9675@gmail.com or https://github.com/lios67.

## Links
| Resource          | Link                                                                 |
|-------------------|----------------------------------------------------------------------|
| 📥 Releases       | [Download](https://github.com/lios67/splice_snapshot/releases/tag/v1.0.0) |
| 📜 Source Code    | [GitHub](https://github.com/lios67/splice_snapshot)    |
| 🎥 FFmpeg (Win)   | [Windows Builds](https://www.gyan.dev/ffmpeg/builds/)               |
| 🎥 FFmpeg (Linux) | [Linux Builds](https://johnvansickle.com/ffmpeg/)
