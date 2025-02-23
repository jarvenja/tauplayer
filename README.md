# tauplayer

tauplayer alias Terminal Audio Player 

## Getting Started

### Dependencies

- Linux based operating system, where required commands (dependencies) are installed.
- Must be run only in bash shell.

### Installing

0) Check and download the latest version.
1) Start tauplayer application by typing bash tauplayer.sh in terminal.
2) When launched very first time tauplayer checks your configuration is complete.
3) If tauplayer reported missing command dependencies in your system, please install them by running given command one liner as authorized user.

### Configutation

This section will be updated later.

## Authors

Please send bug reports to jarvenja@gmail.com.

## License

This project is licensed under GPL License v3 - see the LICENSE.md file for details.

## Usage

tauplayer is used via Text-based User Interface (TUI). When launched it opens the Options menu, where you can select the action of your choice.

When using you should be somewhat familiar with these terms:
- Cache is a memory buffer, which Player reserves for audio playback.
- Collection is a group of named streams, which are stored in .cvs file in its name and /collections sub directory under installation directory.
- Player is audio player application, which tauplayer uses for playback.
- Playlist is a formatted list of links to audio files. tauplayer supports currently playlists only in .m3u format.
- Playlist Directory is a parent directory under which tauplayer scans available playlists.
- (Radio) Stream URL is a direct link to radio station's online stream. Same radio stream can be stored in many Collection files.
- tauplayer is abbreviation for words Terminal Audio Player. At its most concrete minimum it is one Bash shell script file (tauplayer.sh).
- (Text) terminal is a text input and output environment, where you can start and run commands.

The following is some of main activities presented.

### Change Collection

There is always one collection active and selected. At very first time, tauplayer creates a default collection named as 'favorites' for you.

You can change collection this way:
- Select Change Collection from Options menu and press Enter when Select is highlighted.
- You see the is changed and displayed on titlebar on the top right.
- Now you can Listen, Add and Remove streams of active collection.

### Change Playlist Directory

- Select Change Playlist Directory from Options menu.
- When typing new Playlist Directory you need to remember it correctly. 
- tauplayer keeps asking it until you type a valid name for existing new or current one.
- You can still cancel the action. Just leave the old directory as it is and press Enter.

### Play local audio files randomly via playlist

- Select Play list in order from Options menu.
- After a moment, tauplayer shows playlist files founded in Playlist Directory.
- Select a playlist file to Play, and tauplayer starts playing the list of songs in random order.

### Play local audio files in order via playlist

- Select Play shuffled list from Options menu.
- After a moment, tauplayer shows playlist files founded in Playlist Directory.
- Select a playlist file to Play, and tauplayer starts playing the list of songs in order.

### Play a radio stream from active collection

- Select Play Radio Stream from Options menu.
- Select Stream to Listen from opening Stream menu.
- If reached, tauplayer starts a playback session where it tries to play the stream with audio player.
- If the Stream is not reached for some reason tauplayer displays Stream Not Available screen with related information.

### Playback via mplayer

- During playback tauplayer displays the most relevant key set, which you can dynamically control the parameters of the Player.
- Please note that all of the other keys are still enabled. Therefore, please avoid pressing any unlisted keys since they can confuse the Player in some situations.

