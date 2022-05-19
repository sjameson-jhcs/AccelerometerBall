//A Goal object is the target of the player's ball.
//The player tries to collide with it to score points.
class Goal {
  PVector position;
  PVector lower_bounds;
  PVector upper_bounds;
  //Constructor
  Goal(ArrayList<Hole> holes) {
    lower_bounds = new PVector(-FIELD_WIDTH/2+GOAL_RADIUS, -FIELD_HEIGHT/2+GOAL_RADIUS);
    upper_bounds = new PVector(FIELD_WIDTH/2-GOAL_RADIUS, FIELD_HEIGHT/2-GOAL_RADIUS);
    randomize_position(holes);
  }
  //The run method is called once per frame
  void run() {
    draw_self();
  }
  //Draw the sphere that the player is trying to collide with
  void draw_self() {
    pushMatrix();
    fill(WHITE);
    stroke(BLUE);
    //Rotate to match the fields rotation
    rotateY(field.tilt_angle.x);
    rotateX(-1*field.tilt_angle.y);
    //Move to the spot on the field where the goal should be
    translate(position.x, position.y, GOAL_RADIUS);
    //Actually draw it
    sphere(GOAL_RADIUS);
    popMatrix();
  }
  //Choose a new position for the goal
  //Note: it will keep picking new spots until the new spot is not on the player ball or a hole
  void randomize_position(ArrayList<Hole> holes) {
    boolean is_invalid_position = true;
    //While loop will continue until a valid spot is found
    while (is_invalid_position) {
      is_invalid_position = false;
      //Choose a random x and y within the predefined boundaries
      position = new PVector(random(lower_bounds.x, upper_bounds.x), random(lower_bounds.y, upper_bounds.y));
      //Check if the new position is already touching the ball
      if (are_circles_overlapping(position, GOAL_RADIUS, ball.position, BALL_RADIUS)) {
        is_invalid_position = true;
        continue;
      }
      //Check if the new position is on top of a hole
      for (int i = 0; i < holes.size(); i++) {
        Hole temp_hole = holes.get(i);
        if (are_circles_overlapping(position, GOAL_RADIUS, temp_hole.position, HOLE_RADIUS)) {
          is_invalid_position = true;
          break;
        }
      }
    }
  }
  //Reseting the goal just means finding a new random, but valid, location
  void reset(){
    randomize_position(field.holes);
  }
}
