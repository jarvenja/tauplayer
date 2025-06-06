## Why tauplayer?

1. It's an unique application. You can play music files or listen radio streams around the world and manage them by collections.
2. It's easy usable and minimal. You don't need to remember anything beforehand.
3. It doesn't have a complex GUI at all. Just a simple user interface with a keyboard.
4. It's non-commercial and almost ad-free. Perfect for relaxing.
5. It's totally free and you can start using it in a minute.
6. It's ligthweight, and can be also run directly from a server.
7. It's targeted to work on countless GNU/Linux based OSes.
8. It's very customizable so programmers could easily add their personal extra features into the code.
9. It also supports marginal and alternative music for creative and intellectual minds.

You can find the **Download** link at top of the [Getting Started](https://github.com/jarvenja/tauplayer/) guidelines.

## Basic Terms

If the technical things are not very familiar to you, these things terms may help:

**Cache** is a memory buffer, which player reserves for audio playback. \
**Collection** is a group of named streams, which are stored in _.cvs_ file in its name and _/collections_ subdirectory under installation directory. \
**Player** is audio player application, which tauplayer uses for playback. \
**Playlist** is a formatted list of links to audio files. _tauplayer_ supports currently playlists only in _.m3u_ format. \
**Playlist Directory** is a parent directory under which _tauplayer_ scans available playlists. \
**(Radio) Stream URL** is a direct link to radio station's online stream. Same radio stream can be stored in many _collection_ files. \
**tauplayer** is abbreviation for words _Terminal Audio Player_. At its most concrete minimum it is only one _Bash_ shell script file _(tauplayer.sh)_. \
**(Text) terminal** is a text input and output environment, where you can start and run commands.

## Usage

_tauplayer_ is used via Text-based User Interface (TUI).

When launched it opens the _Main_ menu, where you can select the action of your choice.

![main-menu](https://github.com/user-attachments/assets/6a774460-fa64-4534-94c8-8c6bf5dfe45a)

The following are some of functions described step by step.

### Change Active Collection

There is always one collection active or selected (as retrogames in the picture below).

![change-collection](https://github.com/user-attachments/assets/6fee6519-5925-41aa-9e5c-358c3ae6ac8b)

At very first time, tauplayer creates a default collection named as _'favorites'_ for you.

You can change the active collection this way:
- Select _Change Active Collection_ from _Main_ menu and press _Enter_ when _Select_ is highlighted.
- You can see the collection name at the end of the titlebar line on the top.
- Now you can _Listen_, _Add_ and _Remove_ streams of that collection.

### Play local audio files from playlist

- Select _Play List_ from _Main_ menu.
- _tauplayer_ asks the _Playlist Directory_ where to find the alternatives to play until you type a valid directory.
- After you commit the _Playlist Directory_ _tauplayer_ shows playlist files found (as picture below).

![playlists-found](https://github.com/user-attachments/assets/cf64dc8f-567d-43d5-8fc7-1da7d619e87d)

- Select a playlist file to Play, and _tauplayer_ starts playing the list of songs.
  - If Shuffle is **checked** in _Playback preferences_ the list of songs are played in **random** order.
  - If Shuffle is **not** checked the list of songs are played in order they **appear** in current playlist.

### Play a radio stream from active collection

- Select _Play Radio Stream_ from _Main_ menu.
- Select stream to _Listen_ from opening _Stream_ menu.

![play-streams](https://github.com/user-attachments/assets/a89c55ec-5e40-4673-a096-1ecd2fe67257)

- If reached, _tauplayer_ starts a playback session where it tries to play the stream with audio player.
- If the Stream is not reached for some reason _tauplayer_ displays _Stream Not Available_ screen with related information.

### Playback via audio player (mplayer)

- During playback _tauplayer_ displays the most relevant key set, which you can dynamically control the parameters of the player.
- Please note that all of the other keys are still enabled. Therefore, please avoid pressing any unlisted keys since they can confuse the player in some situations.

![play-stream](https://github.com/user-attachments/assets/cbffcbb7-355d-4e8f-afa0-989c1e6978f0)

_The picture above shows tauplayer playing a radio stream in Linux Mint._
