//This is the primary player object.
//The class defines the balls movement and all its interactions with other objects.
class Ball {
  PVector position;
  PVector velocity;
  PVector acceleration;
  PVector rotation;
  PVector angular_velocity;
  int score = 0;
  PVector lower_bounds;
  PVector upper_bounds;
  //Constructor defines the playable area that the ball can move around around
  Ball() {
    lower_bounds = new PVector(-1*FIELD_WIDTH/2 + BALL_RADIUS, -1*FIELD_HEIGHT/2 + BALL_RADIUS);
    upper_bounds = new PVector(FIELD_WIDTH/2-BALL_RADIUS, FIELD_HEIGHT/2-BALL_RADIUS);
    reset();
  }
  //The run method will be called once per frame
  void run() {
    move();
    handle_walls();
    calculate_rotation();
    draw_self();
    fall_in_hole();
    collect_points();
  }
  //Motion is defined by a standard acceleration model
  void move() {
    //Acceleration is determined by the current tilt of the playing field
    acceleration.x = (float)sin(field.tilt_angle.x)*GRAVITY_CONSTANT;
    acceleration.y = (float)sin(field.tilt_angle.y)*GRAVITY_CONSTANT;
    velocity = PVector.add(velocity, acceleration);
    position = PVector.add(position, velocity);
  }
  //Cause a game over if the ball leaves the defined boundaries
  void handle_walls() {
    if (position.x <= lower_bounds.x ||
      position.x >= upper_bounds.x ||
      position.y <= lower_bounds.y ||
      position.y >= upper_bounds.y) {
      jukebox.play_clip("failure");
      reset();
    }
  }
  //Determine rotation based on the tangential velocity and radius
  //This effect is purely visual. It does not affect the actual motion of the ball.
  //This just rotates the sphere frame so it looks like it is rolling
  void calculate_rotation() {
    // v = (omega)*r   so we can divide v by r to get omega
    angular_velocity = PVector.div(velocity, BALL_RADIUS);
    rotation = PVector.add(rotation, angular_velocity);
  }
  //Draw the ball's sphere on the screen
  void draw_self() {
    //Pushing and popping the matrix lets us translate/rotate without messing up future shapes
    pushMatrix();
    //Rotate the drawing surface to be in line with the field
    rotateX(-1*field.tilt_angle.y);
    rotateY(field.tilt_angle.x);
    //Move to where the ball is on the field and move it up off the field so it does not sit half way inside the field
    translate(position.x, position.y, BALL_RADIUS);
    //Rotate the ball to give the illusion that it is "rolling"
    rotateY(rotation.x);
    rotateX(rotation.y);
    fill(BLACK);
    stroke(GREEN);
    //Actually draw it
    sphere(BALL_RADIUS);
    popMatrix();
  }
  //Check each hole to see if the center of the sphere is over the hole. If so, game over.
  void fall_in_hole() {
    //Loop through all holes
    for (int i = 0; i < field.holes.size(); i++) {
      Hole temp_hole = field.holes.get(i);
      //Make sure the hole isn't a preview (red circle only)
      //Using 1 for ball radius because a sphere sits on a tiny point (the ball can overhang a hole).
      if (!temp_hole.is_preview && are_circles_overlapping(position, 1, temp_hole.position, HOLE_RADIUS)) {
        //Reset the game if they fall in a hole
        jukebox.play_clip("failure");
        reset();
        break;
      }
    }
  }
  //Gather points by colliding with the goal sphere
  void collect_points() {
    if (are_circles_overlapping(position, BALL_RADIUS, field.goal.position, GOAL_RADIUS)) {
      //Getting a point creates another hole and moves the goal sphere to a new spot
      field.add_hole();
      field.goal.reset();
      score++;
      jukebox.play_clip("success");
      //Change the music every 2 points scored
      if (score % 2 == 0) jukebox.next_track();
    }
  }
  //Handle all the steps necessary when a game over happens
  void reset() {
    jukebox.stop_music();
    is_running = false;
    //Check if this is a new high score and if so, handle it
    if (score > high_score) {
      high_score = score;
      high_scorer = "";
      instructions = "High Score! Type your name and press ENTER";
      is_entering_name = true;
      jukebox.play_clip("high_score");
    } else {
      //It wasn't a high score so just reset the music and instructions
      jukebox.reset();
      instructions = "Press ENTER to start";
    }
    //Set the ball and field back to initial positions
    score = 0;
    position = new PVector(0, 0, 0);
    velocity = new PVector(0, 0, 0);
    acceleration = new PVector(0, 0, 0);
    rotation = new PVector(0, 0, 0);
    angular_velocity = new PVector(0, 0, 0);
    if (field != null) field.reset();
  }
}
