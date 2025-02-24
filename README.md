# tauplayer

_tauplayer_ alias Terminal Audio Player 

## Getting Started

### Dependencies

1) Linux based operating system.
2) Must be run only in _bash shell_.
3) You can install the missing command dependencies into your system now or later guided by _tauplayer_ as authorized user.

  ```
  sudo apt-get install curl dialog lsb-release mplayer
  ```
  
### Installing

1) Download the latest available version from https://github.com/jarvenja/tauplayer/tags.
2) Extract package into e.g. /HOME/user/tauplayer

There is no installer. You can now execute the program.
  
### Executing the program

You can just start using _tauplayer_ application by typing __bash tauplayer.sh__ in terminal.
```
bash tauplayer.sh
```
_tauplayer_ will create one or two data files in its parent directory.

## Authors

Please send bug reports to jarvenja@gmail.com.

## License

This project is licensed under _GPL License v3_ - see the _LICENSE.md_ file for details.

## Usage

_tauplayer_ is used via Text-based User Interface (TUI). When launched it opens the _Options_ menu, where you can select the action of your choice.

Understanding these terms makes using a bit easier:
- **Cache** is a memory buffer, which player reserves for audio playback.
- **Collection** is a group of named streams, which are stored in _.cvs_ file in its name and _/collections_ subdirectory under installation directory.
- **Player** is audio player application, which tauplayer uses for playback.
- **Playlist** is a formatted list of links to audio files. _tauplayer_ supports currently playlists only in _.m3u_ format.
- **Playlist Directory** is a parent directory under which _tauplayer_ scans available playlists.
- **(Radio) Stream URL** is a direct link to radio station's online stream. Same radio stream can be stored in many _collection_ files.
- **tauplayer** is abbreviation for words _Terminal Audio Player_. At its most concrete minimum it is only one _Bash_ shell script file _(tauplayer.sh)_.
- **(Text) terminal** is a text input and output environment, where you can start and run commands.

The following are some of functions described step by step.

### Change Collection

There is always one collection active or selected. At very first time, tauplayer creates a default collection named as _'favorites'_ for you.

You can change the active collection this way:
- Select _Change Active Collection_ from _Options_ menu and press _Enter_ when _Select_ is highlighted.
- You can see the collection name at the end of the titlebar line on the top.
- Now you can _Listen_, _Add_ and _Remove_ streams of the active collection.

### Change Playlist Directory

- Select _Change Playlist Directory_ from _Options_ menu.
- When typing new _Playlist Directory_ you need to remember it correctly. 
- _tauplayer_ keeps asking it until you type a valid name for existing new or current one.
- You can still cancel the action. Just leave the old directory as it is and press _Enter_.

### Play local audio files from playlist

- Select _Play List_ from _Options_ menu.
- After a moment, _tauplayer_ shows playlist files founded in _Playlist Directory_.
- Select a playlist file to Play, and _tauplayer_ starts playing the list of songs.
  - If Shuffle is set OFF the list of songs are played in order they **appear** in current playlist.
  - If Shuffle is set ON the list of songs are played in **random** order.

### Play a radio stream from active collection

- Select _Play Radio Stream_ from _Options_ menu.
- Select stream to _Listen_ from opening _Stream_ menu.
- If reached, _tauplayer_ starts a playback session where it tries to play the stream with audio player.
- If the Stream is not reached for some reason _tauplayer_ displays _Stream Not Available_ screen with related information.

### Playback via audio player (mplayer)

- During playback _tauplayer_ displays the most relevant key set, which you can dynamically control the parameters of the player.
- Please note that all of the other keys are still enabled. Therefore, please avoid pressing any unlisted keys since they can confuse the player in some situations.

## Improving playback quality

This section will be updated later.
