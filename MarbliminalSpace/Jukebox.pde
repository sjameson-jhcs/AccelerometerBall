import processing.sound.*;
import java.util.*;
//The jukebox is a sound/music player
//It loads the various sound files and can be called to play clips/music when needed
class Jukebox {
  int music_tracks = 9;
  int track_to_load = 0;
  int current_track = 0;
  //Music files will usually play in order so they are just going to be indexed 0 to 8
  SoundFile[] music = new SoundFile[music_tracks];
  //Sound effects will be played repeatedly so they will be in a dictionary where they can be played by name
  Hashtable<String, SoundFile> clips = new Hashtable<String, SoundFile>();
  //Constructor will load the smaller sound effect files
  Jukebox() {
    clips.put("success", new SoundFile(game, "success_clip.wav"));
    clips.put("failure", new SoundFile(game, "failure_clip.wav"));
    clips.put("high_score", new SoundFile(game, "high_score_clip.wav"));
  }
  //This method will allow us to load one audio file at a time. Originally this process was slow while using mp3 files.
  //This is mostly unneeded now since the .wav files are loading much faster.
  boolean load_next() {
    //Load a music file using the .wav file name in the projects folder. All music files are formaatted as music_#.wav
    if (music[track_to_load] == null) music[track_to_load] = new SoundFile(game, "music_"+track_to_load+".wav", false);
    //Once the first track is loaded we can start playing music
    if (track_to_load == 0) reset();
    //Increment so the next file loaded will be one number higher
    track_to_load++;
    //If the last audio file is loaded then return false so the game will progress past the loading screen.
    if (track_to_load == music_tracks) return false;
    return true;
  }
  //Stop the current music and play the next one on the list. Triggered by scoring 2 points or pressing enter.
  void next_track() {
    //Make sure we are not at the end of the track list. The last song cannot be skipped.
    if (current_track + 1 < music_tracks) {
      if (music[current_track].isPlaying()) music[current_track].stop();
      current_track++;
      music[current_track].loop();
    }
  }
  //Start playing the first track again
  void reset() {
    stop_music();
    current_track = 0;
    if (music[current_track] != null) music[current_track].loop();
  }
  //Play a sound effect by passing in its name
  //Options are "success", "failure", and "high_score"
  void play_clip(String clip) {
    clips.get(clip).play();
  }
  //Stop the currently playing song
  void stop_music() {
    if (music[current_track] != null && music[current_track].isPlaying()) music[current_track].stop();
  }
}
