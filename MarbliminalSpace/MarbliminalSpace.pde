// Serial library used for serial communication
import processing.serial.*;
Serial controller_serial_port;

//Media content to be loaded (music, pictures, fonts, etc.)
Jukebox jukebox;               //Jukebox is a custom class for playing sounds/music
MarbliminalSpace game = this;  //Parent object "game" needed when loading audio files in the jukebox
PImage background;             //Background is an image used as a texture on the playing field. Looks like a hex grid.
PFont title_font;              //Font for the main game title. Looks like large hand drawn capital letters.
PFont standard_font;           //Font to be used for score and instruction information
PImage icon;                   //Icon to be used by the application in the toolbar

//Constants that can only be adjusted in code
final int BALL_RADIUS = 30;                            //Size of the ball the player moves
final int HOLE_COUNT = 1;                              //Starting number of holes. Needs to be at least 1 so there is a "preview" at the start
final int HOLE_RADIUS = 50;                            //Size the holes. Needs to be bigger the player or else it will look funny.
final int GOAL_RADIUS = 20;                            //Size of the target objects. Should be smaller than the player.
final int WINDOW_WIDTH = 1000;                         //Width of the window
final int WINDOW_HEIGHT = 700;                         //Height of the window
final int EDGE_PADDING = 50;                           //Space between the playing field and the window edge
final int FIELD_WIDTH = WINDOW_WIDTH - EDGE_PADDING;   //Field width is what is left over after removing the padding area
final int FIELD_HEIGHT = WINDOW_HEIGHT - EDGE_PADDING; //Field height
final int FIELD_THICKNESS = 2;                         //z-thickness of the field. Not really seen unless the player over rotates the field. Makes things weird if the number is big.
final float GRAVITY_CONSTANT = 0.3;                    //Controls how drastic the tilt affects the balls motion. Big = twitchy, small = floaty
final color RED = color(150, 60, 60);                  //Standard colors to be reused in various places
final color GREEN = color(60, 150, 60);
final color BLUE = color(60, 60, 150);
final color GREY = color(150);
final color BLACK = color(0);
final color WHITE = color(255);
final int DATA_HISTORY_QUANTITY = 20;                  //How many recent data points will be stored and averaged to smooth out the controls. More = smoother but slower response rate.

//Globals to be used in controlling the game
int high_score = 0;                  //Number loads from text file and is compared when there is a game over
String high_scorer = "n/a";          //Name is pulled from text file. Can be replaced when a new high score is recorded
boolean is_running = false;          //Boolean to track if the game is running (meaning the ball is actively moving)
boolean is_entering_name = false;    //Boolean to track if the player is currently typing a high scoring name. Freezes other events from happening.
boolean is_jukebox_loading = true;   //Boolean to track if audio files are loading. Forces a brief loading screen at the start of the game.
boolean is_first_frame = true;       //Boolean to track if the very first visual frame is being built. Prevents audio loading during that frame to speed up visual response time.
String instructions = "";            //Text instructions to be modified as needed and displayed between games.
Ball ball;                           //The main ball object
Field field;                         //The main field object
ArrayList<Float> data_history_x;     //Recent data points that will be averaged to smooth out the control reponse
ArrayList<Float> data_history_y;

//Setup runs once on game load
void setup() {
  //Make the serial connection to the designated port
  find_and_connect_to_usb_controller("usbserial");
  //Get the window ready and load some media content (pictures, fonts, etc.)
  surface.setTitle("MARBLIMINAL SPACE");
  size(1000, 700, P3D);
  jukebox = new Jukebox();
  background = loadImage("background.png");
  title_font = createFont("title.ttf", 60);
  standard_font = createFont("standard.ttf", 15);
  instructions = "Press ENTER to start";
  data_history_x = new ArrayList<Float>();
  data_history_y = new ArrayList<Float>();

  //Initialize the game objects
  ball = new Ball();
  field = new Field();

  //Get the high score data from a text file
  read_stored_high_score();
}

// Search the list of available usb devices to find one with the name that passed
// This name will vary from device to device. You can change the hard coded name in the setup method
// Only part of the name is needed. It does not need to be a full match
void find_and_connect_to_usb_controller(String controller_serial_name) {
  int serial_port = -1;
  // Loop through all available usb devices
  for (int i = 0; i < Serial.list().length; i++) {
    // If the desired name is present then store the port number and stop looking
    if (Serial.list()[i].indexOf(controller_serial_name) >= 0) {
      serial_port = i;
      break;
    }
  }
  // If the named device is found then establish a connection
  if (serial_port >= 0) {
    controller_serial_port = new Serial(this, Serial.list()[serial_port], 9600);
  }
  // If the named device is not found then print an error message to console and exit the program
  else {
    println("Unable to find device named " + controller_serial_name + " in this list of available devices. Check the name of your device in the list below and adjust the code in the [setup] method.");
    printArray(Serial.list());
    exit();
  }
}

//Draw will run once per frame
void draw() {
  background(BLACK);
  //Set the origin to the middle of the screen
  translate(width/2, height/2);
  //Delay the game while loading audio files
  if (is_jukebox_loading) {
    //Draw a loading dialog on during load. This is very brief. Only visible less than a second.
    draw_jukebox_loading();
  } else {
    lights();
    //Draw the field (including holes and goals)
    field.run();
    //Draw information text on the field (title, instructions, score, etc.)
    draw_score();
    //Do all the ball stuff if the game is running
    if (is_running) {
      ball.run();
    }
  }
}
//Draw a loading screen with a progress bar showing how many audio files have loaded
//This goes very fast now that audio files are .wav instead of .mp3
void draw_jukebox_loading() {
  pushMatrix();
  fill(WHITE);
  translate(-50, 0, BALL_RADIUS);
  //Prevent an audio file from loading on the first pass so that at least something is shown to the user
  if (is_first_frame) is_first_frame = false;
  else is_jukebox_loading = jukebox.load_next();
  String progress_bar = "";
  //The progress bar is just a number of x's equal to how many audio files have already loaded
  for (int i = 0; i < jukebox.music_tracks; i++) {
    if (jukebox.track_to_load > i) progress_bar += "x";
    else progress_bar += "_";
  }
  text("loading: "+progress_bar, 0, 20);
  popMatrix();
}
//Draw the text on the playing field
//Once the game starts all but the score is hidden
void draw_score() {
  pushMatrix();
  //Rotate the drawing surface to match the tilted playing field
  rotateY(field.tilt_angle.x);
  rotateX(-1*field.tilt_angle.y);
  //Lift the text away from the field so it doesnt get hidden by the field itself or the holes
  translate(0, 0, BALL_RADIUS);
  textAlign(CENTER);
  //Draw the game title if the game hasn't started yet
  if (!is_running) {
    textFont(title_font);
    fill(GREEN);
    text("MARBLIMINAL SPACE", 0, -1*FIELD_HEIGHT/2+100);
  }
  textFont(standard_font);
  fill(RED);
  //Draw the instructions if the game hasn't started yet
  text(instructions, 0, -20);
  textAlign(LEFT);
  fill(WHITE);
  //Move the following text left because we are left aligning to get the numbers to be in a straight-ish column
  translate(-60, 0);
  //Draw the score always
  text("SCORE: " + ball.score, 0, 0);
  //Draw the high score only if the game isn't running
  if (!is_running) {
    text("BEST:    " + high_score, 0, 20);
    text("SET BY: " + high_scorer, 0, 40);
  }
  popMatrix();
}
//A helper method used to determine if any two objects are touching
//Used by various objects (balls, goals, holes, etc.)
boolean are_circles_overlapping(PVector p1, int r1, PVector p2, int r2) {
  if (PVector.dist(p1, p2) <= r1+r2) {
    return true;
  }
  return false;
}
//A method to pull text from a .txt file in the project folder
void read_stored_high_score() {
  BufferedReader text_file_reader = createReader("high_score.txt");
  String line = null;
  int line_number = 0;
  try {
    while ((line = text_file_reader.readLine()) != null) {
      //The text file holds two lines of data. The high score number and a name of the player who scored it.
      if (line_number == 0) high_score =  Integer.parseInt(line);
      if (line_number == 1 && line.length() > 0) high_scorer = line;
      line_number++;
    }
    text_file_reader.close();
  }
  catch (IOException e) {
    e.printStackTrace();
  }
}

//Listener method that triggers when a serial event occurs
void serialEvent(Serial port) {
  // Grab any incoming controller data and send it off to be processed
  String raw_data = port.readStringUntil(']');
  if (raw_data != null && raw_data.length() > 0) handle_control_data(raw_data);
}

// Check for a data stream that is incomplete or out of order
// This is most likely to occur when the program first starts and picks up data mid-transmission
String scrub_data(String data) {
  if (data == null) return "";
  // Look for data that is in the format "[a,b,c,]"
  int opening_brace_index = data.lastIndexOf("[");
  int closing_brace_index = data.lastIndexOf("]");
  // If either brace is missing or out of order then abort by returning an empty string
  if (opening_brace_index < 0 || closing_brace_index < 0 || opening_brace_index > closing_brace_index) return "";
  // Only return the LAST data in that is in proper braces. In case 2 data sets are present we want to use only the newest set.
  return data.substring(opening_brace_index+1, closing_brace_index);
}

// Parse the data stream and use the values as needed
void handle_control_data(String data) {
  String scrubbed_data = scrub_data(data);
  // Ideally the processing code will run much faster than data is streaming in via usb
  // So we will only take action when data is available
  int data_index = 0;
  String data_string = "";
  int data_value = 0;
  while (scrubbed_data.length() > 1) {
    try {
      data_string = scrubbed_data.substring(0, scrubbed_data.indexOf(","));
      scrubbed_data = scrubbed_data.substring(scrubbed_data.indexOf(",")+1, scrubbed_data.length());
      data_value = Integer.parseInt(data_string);
    }
    catch (NumberFormatException ex) {
      println("WARNING: Bad Data - data is expected to be a number. Non-number data has been ignored.");
    }
    if (data_index == 0) {
      float tilt = map(data_value, 255, -255, -PI/2, PI/2);
      if(field != null && field.tilt_angle != null){
        if(data_history_y.size() >= DATA_HISTORY_QUANTITY) data_history_y.remove(0);
        data_history_y.add(tilt);
        field.tilt_angle.y = get_arraylist_mean(data_history_y);
      }
    }
    if (data_index == 1) {
      float tilt = map(data_value, -255, 255, -PI/2, PI/2);
      if(field != null && field.tilt_angle != null){
        if(data_history_x.size() >= DATA_HISTORY_QUANTITY) data_history_x.remove(0);
        data_history_x.add(tilt);
        field.tilt_angle.x = get_arraylist_mean(data_history_x);
      }
    }
    if (data_index == 2) {
      //Nothing yet
    }
    data_index++;
  }
}

float get_arraylist_mean(ArrayList<Float> list){
  float answer = 0;
  for(int i = 0; i < list.size(); i++){
    answer += list.get(i);
  }
  answer = answer/list.size();
  return answer;
}

//Keyboard controls are mostly for development purposes until a controller is attached
//The ENTER keypresses could be replaced with a physical button the controller in the future
void keyPressed() {
  //Check if the player is supposed to be typing their name at the moment
  //Used to enter a name when they get a high score
  if (is_entering_name) {
    //Once the name is entered, write it to the text file and reset the game to the start screen
    if (keyCode == ENTER) {
      PrintWriter text_file_writer = createWriter("high_score.txt");
      text_file_writer.println(""+high_score);
      text_file_writer.println(high_scorer);
      text_file_writer.flush();
      text_file_writer.close();
      instructions = "Press ENTER to start";
      is_entering_name = false;
      jukebox.reset();
    } else if (keyCode >= 32 && keyCode <= 126) {
      //Allow all typable characters to be in their name
      high_scorer += key;
    } else if (keyCode == 8 || keyCode == 127) {
      //If they press backspace or delete then drop the last character in the string
      //Make sure there is at least one character to drop
      if (high_scorer.length() > 0)high_scorer = high_scorer.substring(0, high_scorer.length()-1);
    }
  } else {
    //WASD controls to be used in lieu of a controller during development
    if (key == 'w') {
      field.tilt_angle.y -= field.tilt_increment;
    }
    if (key == 's') {
      field.tilt_angle.y += field.tilt_increment;
    }
    if (key == 'a') {
      field.tilt_angle.x -= field.tilt_increment;
    }
    if (key == 'd') {
      field.tilt_angle.x += field.tilt_increment;
    }
    //ENTER key to start the game. Could be replaced with a physical button in the future
    //Should recalibrate sensor to zero position when this is pressed. Or maybe use another key.
    if (keyCode == ENTER) {
      is_running = true;
      instructions = "";
      jukebox.next_track();
    }
  }
}
