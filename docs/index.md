## Why tauplayer?

1. It's an unique application. You can play music files or listen radio streams around the world and manage them by groups.
2. It's easy usable and minimal. You don't need to remember anything beforehand.
3. It doesn't have a complex GUI at all. Just a simple user interface.
4. It's non-commercial and almost ad-free. Perfect for relaxing.
5. It's totally free and you can start using it in a minute.
6. It's ligthweight, and can be also run directly from a server.
7. It's targeted to work on many GNU/Linux based OSes.
8. It's very customizable so programmers could easily add their personal extra features into the code.
9. It also supports marginal and alternative music.

You can find the **Download** link at top of the [Getting Started](https://github.com/jarvenja/tauplayer/) guidelines.

<h2>Usage</h2>
<h3>User Interface</h3>

_tauplayer_ is used via Text-based User Interface (TUI). 

When launched it opens the _Main menu_, where you can select the action of your choice.

<img alt="main-menu" src="https://github.com/user-attachments/assets/d6aa8bc6-9736-4f23-9330-f48a8f8fcc1a" />

<details>
  <summary><h3>Basic Terms</h3></summary>

If the technical things are not your cup of tea, understanding these terms may help:

**Cache** is a memory buffer, which player reserves for audio playback. \
**Player** is audio player application, which tauplayer uses for playback. \
**Playlist** is a formatted list of links to audio files. _tauplayer_ supports currently playlists only in _.m3u_ format. \
**Playlist Directory** is a parent directory under which _tauplayer_ scans available playlists. \
**(Radio) Stream URL** is a direct link to radio station's online stream. Same radio stream can be stored in many _groups_. \
**Stream Group** is a group of streams with named keys, which are stored in _/streams_ subdirectory under installation directory. \
**tauplayer** is abbreviation for words _Terminal Audio Player_. At its most concrete minimum it is only one _Bash_ shell script file _(tauplayer.sh)_. \
**(Text) terminal** is a text input and output environment, where you can start and run commands.
</details>
<details>
  <summary><h3>Changing Stream Group</h3></summary>

There is always one stream group active or selected (as retrogames in the picture below).
You can change the group:
- Select _Change Stream Group_ from _Radio Streams_ menu and press _Enter_ when _Select_ is highlighted.
- The application opens the below.
 <img alt="change-stream-group" src="https://github.com/user-attachments/assets/2441c1de-7a2e-4581-a05c-e18e25be34c2" />
</details>
<details>
  <summary><h3>Playing radio streams in groups</h3></summary>

- Select _Radio Streams..._ followed by _Select Stream...

  <img alt="radio-streams" src="https://github.com/user-attachments/assets/f77b14cc-6351-4e5b-be35-03ba733b0632" />

- Select the stream you want to play and press _Enter_ when _Select_ is highlighted.
- Select the stream you want to play and press _Enter_ when _Select_ is highlighted.

</details>
<details>
  <summary><h3>Playing local audio files from playlist</h3></summary>

You can play local audio files by the following way:
- Select _Playlists..._ from _Main_ menu.
- _tauplayer_ asks the _Playlist Directory_ where to find the alternatives to play until you type a valid directory.
- After you commit the _Playlist Directory_ _tauplayer_ shows playlist files found.
- Select a playlist file to Play, and _tauplayer_ starts playing the list of songs.
</details>
<details>
  <summary><h3>Playback via audio player</h3></summary>
  
During playback _tauplayer_ displays the most relevant key set, which you can dynamically control the parameters of the player.

<img alt="stream-playback" src="https://github.com/user-attachments/assets/1c8d8280-f322-4a27-a8d9-a9eda2786334" />

_The picture above shows tauplayer playing a radio stream in Linux Mint._

Please note that all of the other keys are still enabled. Therefore, please avoid pressing any unnecessary keys since they can confuse the player in some situations.

</details>
