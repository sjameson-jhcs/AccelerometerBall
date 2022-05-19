//The Field class includes the rectangle playing surface and all interactable objects on it
//The field acts as a reference for drawing and moving all other objects
class Field {
  //tilt_angle is controlled by the accelerometer. It is used to rotate every object as it is drawn.
  PVector tilt_angle;
  //tilt_increment is only used for keyboard controls during testing
  float tilt_increment = 0.04;
  ArrayList<Hole> holes;
  Goal goal;
  //Constructor
  Field() {
    reset();
  }
  //The run method is called every frame
  void run() {
    draw_self();
    if (is_running) {
      draw_holes();
      goal.run();
    }
  }
  //Draw a 3D box that is the field and put an image on the box to give it texture
  void draw_self() {
    pushMatrix();
    fill(GREY);
    stroke(RED);
    //Moving the box down into the screen so it doesn't cover objects at z-height 0
    translate(0, 0, -1*FIELD_THICKNESS);
    rotateY(tilt_angle.x);
    rotateX(-1*tilt_angle.y);
    //Draw the 3D box that the texture sits on. Mostly this doesn't matter unless the player rotates the field to near 90 degrees.
    box(FIELD_WIDTH, FIELD_HEIGHT, FIELD_THICKNESS);
    translate(0,0,FIELD_THICKNESS);
    //The image is the texture that the player normally sees
    image(background, -1*FIELD_WIDTH/2, -1*FIELD_HEIGHT/2, FIELD_WIDTH, FIELD_HEIGHT);
    popMatrix();
  }
  //Call every hole to do its tasks on each frame
  void draw_holes() {
    for (int i = 0; i < holes.size(); i++) {
      Hole temp_hole = holes.get(i);
      temp_hole.run();
    }
  }
  //Start the game with predefined number of hole objects
  void generate_random_holes() {
    holes = new ArrayList<Hole>();
    for (int i = 0; i < HOLE_COUNT; i++) {
      add_hole();
    }
  }
  //Add an additional hole to the list. Set the previous preview hole to be a real hole now.
  void add_hole() {
    //The last hole in the list should be a preview that is a red circle only. So make it real before adding the new hole.
    if(holes.size() > 0) holes.get(holes.size() - 1).is_preview = false;
    holes.add(new Hole(holes));
  }
  //After a game over reset the field to zero position and with starting holes and goal
  void reset() {
    tilt_angle = new PVector(0, 0);
    generate_random_holes();
    goal = new Goal(holes);
  }
}
