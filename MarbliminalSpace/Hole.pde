//A hole object is what the player is trying to avoid
//Holes can be real (black) or a preview of where the next hole will be (red circle)
class Hole {
  PVector position;
  PVector lower_bounds;
  PVector upper_bounds;
  boolean is_preview = true;
  //Constructor
  Hole(ArrayList<Hole> other_holes) {
    lower_bounds = new PVector(-FIELD_WIDTH/2+HOLE_RADIUS, -FIELD_HEIGHT/2+HOLE_RADIUS);
    upper_bounds = new PVector(FIELD_WIDTH/2-HOLE_RADIUS, FIELD_HEIGHT/2-HOLE_RADIUS);
    randomize_position(other_holes);
  }
  //The run method will be called once per frame
  void run() {
    draw_self();
  }
  //Draw just a circle to represent the hole
  //Note: processing doesn't have a cylinder object but a black circle looks good enough for now
  void draw_self() {
    pushMatrix();
    //Preview circles are not filled in with black. They represent where the "next" hole will pop up.
    if(is_preview) noFill();
    else fill(BLACK);
    stroke(RED);
    //Rotate to match the field's tilt
    rotateY(field.tilt_angle.x);
    rotateX(-1*field.tilt_angle.y);
    //Move the circles slightly towards the screen. This prevents overlaps with the field underneath which would "hide" the holes.
    translate(0,0,2);
    //Actually draw it. Just a circle.
    ellipse(position.x, position.y, HOLE_RADIUS*2, HOLE_RADIUS*2);
    popMatrix();
  }
  //Keep looking for random positions until a spot is found that does not overlap the player or another hole
  void randomize_position(ArrayList<Hole> other_holes) {
    boolean is_invalid_position = true;
    while (is_invalid_position) {
      is_invalid_position = false;
      //Generate a random position
      position = new PVector(random(lower_bounds.x, upper_bounds.x), random(lower_bounds.y, upper_bounds.y));
      //Make sure it is not touching the player already
      if (are_circles_overlapping(position, HOLE_RADIUS, ball.position, BALL_RADIUS)) {
        is_invalid_position = true;
        continue;
      }
      //Make sure it is not overlapping another hole
      for (int i = 0; i < other_holes.size(); i++) {
        Hole temp_hole = other_holes.get(i);
        if (are_circles_overlapping(position, HOLE_RADIUS, temp_hole.position, HOLE_RADIUS)) {
          is_invalid_position = true;
          break;
        }
      }
    }
  }
}
