// Code largely based on work by Daniel Shiffman.
// Retrieved from https://processing.org/examples/flocking.html

String messages[] = {
  "Dear cousin Philip, A warm and a thousand hellos, We have arrived in this country and thank God, political management, important and non-important work, and family are all okay. All the family send their hellos. Dr. Yusuf had a baby girl and is very happy with her and I have told him about the book and he says the most important thing is to finish printing it and that if you want anything from this holy country let me know and I shall get it soon. Your mother’s health is very good. The thing that I am asking from you now is that our friend, Mr. Charles Karam, owner of the court inspiring mountain in France, has asked me to get your permission to translate your book “The Syrians in the United States” into the French language and to print it at his expense and he wants to change the name to “The Lebanese in America” and not “The Syrians.” If he could do that and adjust a few things in the book and if you had any terms and conditions for him, tell me and I will let him know. My regards to Mary and Viola with kisses, A.K Hitti P.O. Box 511 Beirut, Lebanon",
  "Dear Mr. Demetrios\nHere that I was worth to receive your letter, and on the one hand I was pleased thinking for a moment that I could hear you talking, and on the other hand I was sad because I will not be able to reciprocate in writing the warmth and full delicacy of feelings, and I am considered in part unfortunate, especially now that I am not able to describe what I feel, and how highly it was demanded both by my mind and my heart, because you know that well, I am confined to these few lines, but know that everything is mutual.\n\nSo, dearest Lambrini, suddenly Athenian, so that you do not pride yourself, please write to us because you are going to see us again.\n\nNow I will also ask something of you, and you will oblige me or not. If you don’t want to, do not make us this favor.\n\nI am enclosing a prescription of Magchakis as you find him the easiest. When I was there I went with my husband and myself and asked him what we should do so that the tonsils of the little girl are treated. He told us with electricity. We wrote to Paris, and electro-cautery came to us, so please him from my side so that he writes what type of machine etc. is needed for the cleaning.\n\nI received the hats and I owe Mrs. Lilian 93 drachmas 40, should I give them to your family or not.\n\nI kiss you brotherly your friend Eleni"
};

Flock flock;
PVector expPos = null;
float expSpeed = 0;

PImage bg;
void setup() {
  size(1280, 720);
  bg = loadImage("map.png");
  background(bg);
  flock = new Flock();
  // Add an initial set of boids into the system
  for (int i = 0; i < 200; i++) {
    flock.addBoid(new Boid(random(width),random(height),2+random(4)));
  }
  expPos = new PVector(mouseX, mouseY);
}

void draw() {
  mouseStats();
  background(bg);
  flock.run();
}

// Add a new boid into the System
void mousePressed() {
  //flock.addBoid(new Boid(mouseX,mouseY,50+random(4)));
}

void keyPressed() {
  if (key == ' ') {
    println(messages[(int)random(messages.length)]);
  }
}

void mouseStats(){
  PVector mousePos = new PVector(mouseX, mouseY);
  PVector pmousePos = new PVector(pmouseX, pmouseY);
  float dist = PVector.dist(mousePos, pmousePos);
  
  expPos.mult(19);
  expPos.add(mousePos);
  expPos.div(20);
  
  expSpeed = expSpeed*0.9 + dist*0.1;
}


// The Flock (a list of Boid objects)

class Flock {
  ArrayList<Boid> boids; // An ArrayList for all the boids

  Flock() {
    boids = new ArrayList<Boid>(); // Initialize the ArrayList
  }

  void run() {
    for (Boid b : boids) {
      b.run(boids);  // Passing the entire list of boids to each boid individually
    }
  }

  void addBoid(Boid b) {
    boids.add(b);
  }

}




// The Boid class

class Boid {

  PVector position;
  PVector velocity;
  PVector acceleration;
  float r;
  float maxforce;    // Maximum steering force
  float maxspeed;    // Maximum speed
  PImage img = loadImage("paper airplane.png");

  Boid(float x, float y, float mass) {
    acceleration = new PVector(0, 0);

    // This is a new PVector method not yet implemented in JS
    // velocity = PVector.random2D();

    // Leaving the code temporarily this way so that this example runs in JS
    float angle = random(TWO_PI);
    velocity = new PVector(cos(angle), sin(angle));

    position = new PVector(x, y);
    r = mass;
    maxspeed = 8-mass;
    maxforce = 0.03;
  }

  void run(ArrayList<Boid> boids) {
    flock(boids);
    update();
    borders();
    render();
  }

  void applyForce(PVector force) {
    // We could add mass here if we want A = F / M
    force.mult(4/r);
    acceleration.add(force);
  }

  // We accumulate a new acceleration each time based on three rules
  void flock(ArrayList<Boid> boids) {
    PVector sep = separate(boids);   // Separation
    PVector ali = align(boids);      // Alignment
    PVector coh = cohesion(boids);   // Cohesion
    PVector pre = predate(boids);   // Cohesion
    PVector att = cursorAttract(boids); // Attract to pressed cursor
    PVector cal = cursorAlign(boids); // Align to moving cursor
    // Arbitrarily weight these forces
    sep.mult(1.5);
    ali.mult(1.0);
    coh.mult(1.0);
    pre.mult(30.0);
    att.mult(10.0);
    cal.mult(10.0);
    // Add the force vectors to acceleration
    applyForce(sep);
    applyForce(ali);
    applyForce(coh);
    applyForce(pre);
    applyForce(att);
    applyForce(cal);
  }

  // Method to update position
  void update() {
    // Update velocity
    velocity.add(acceleration);
    // Limit speed
    velocity.limit(maxspeed);
    position.add(velocity);
    // Reset accelertion to 0 each cycle
    acceleration.mult(0);
  }

  // A method that calculates and applies a steering force towards a target
  // STEER = DESIRED MINUS VELOCITY
  PVector seek(PVector target) {
    PVector desired = PVector.sub(target, position);  // A vector pointing from the position to the target
    // Scale to maximum speed
    desired.normalize();
    desired.mult(maxspeed);

    // Above two lines of code below could be condensed with new PVector setMag() method
    // Not using this method until Processing.js catches up
    // desired.setMag(maxspeed);

    // Steering = Desired minus Velocity
    PVector steer = PVector.sub(desired, velocity);
    steer.limit(maxforce);  // Limit to maximum steering force
    return steer;
  }

  void render() {
    // Draw a triangle rotated in the direction of velocity
    float theta = velocity.heading2D() + radians(90);
    // heading2D() above is now heading() but leaving old syntax until Processing.js catches up
    
    fill(#3fa9f5, 200);
    noStroke();
    //stroke(0);
    pushMatrix();
    translate(position.x, position.y);
    rotate(theta);
    image(this.img, -r*5, -r*5, r*5, r*5);
    /*
    beginShape();
    //vertex(0, -r*2);
    //vertex(-r, r*2);
    //vertex(r, r*2);
    vertex(-r, -r);
    vertex( r, -r);
    vertex( r,  r);
    vertex(-r,  r);
    vertex(-r, -r);
    endShape();
    */
    popMatrix();
  }

  // Wraparound
  void borders() {
    if (position.x < -r) position.x = width+r;
    if (position.y < -r) position.y = height+r;
    if (position.x > width+r) position.x = -r;
    if (position.y > height+r) position.y = -r;
  }

  // Separation
  // Method checks for nearby boids and steers away
  PVector separate (ArrayList<Boid> boids) {
    float desiredseparation = 25.00f;
    PVector steer = new PVector(0, 0, 0);
    int count = 0;
    // For every boid in the system, check if it's too close
    for (Boid other : boids) {
      float d = PVector.dist(position, other.position);
      // If the distance is greater than 0 and less than an arbitrary amount (0 when you are yourself)
      if ((d > 0) && (d < desiredseparation)) {
        // Calculate vector pointing away from neighbor
        PVector diff = PVector.sub(position, other.position);
        diff.normalize();
        diff.div(d); // Weight by distance
        diff.mult(other.r);
        steer.add(diff);
        count++;            // Keep track of how many
      }
    }
    // Average -- divide by how many
    if (count > 0) {
      steer.div((float)count);
    }

    // As long as the vector is greater than 0
    if (steer.mag() > 0) {
      // First two lines of code below could be condensed with new PVector setMag() method
      // Not using this method until Processing.js catches up
      // steer.setMag(maxspeed);

      // Implement Reynolds: Steering = Desired - Velocity
      steer.normalize();
      steer.mult(maxspeed);
      steer.sub(velocity);
      steer.limit(maxforce);
    }
    return steer;
  }

  // Alignment
  // For every nearby boid in the system, calculate the average velocity
  PVector align (ArrayList<Boid> boids) {
    float neighbordist = 50;
    PVector sum = new PVector(0, 0);
    float count = 0;
    for (Boid other : boids) {
      float d = PVector.dist(position, other.position);
      if ((d > 0) && (d < neighbordist)) {
        PVector cpv = new PVector(0,0);
        cpv.add(other.velocity);
        cpv.mult(other.r/4);
        sum.add(cpv);
        count += other.r;
      }
    }
    if (count > 0) {
      sum.div((float)count);
      // First two lines of code below could be condensed with new PVector setMag() method
      // Not using this method until Processing.js catches up
      // sum.setMag(maxspeed);

      // Implement Reynolds: Steering = Desired - Velocity
      sum.normalize();
      sum.mult(maxspeed);
      PVector steer = PVector.sub(sum, velocity);
      steer.limit(maxforce);
      return steer;
    } 
    else {
      return new PVector(0, 0);
    }
  }

  // Cohesion
  // For the average position (i.e. center) of all nearby boids, calculate steering vector towards that position
  PVector cohesion (ArrayList<Boid> boids) {
    float neighbordist = 50;
    PVector sum = new PVector(0, 0);   // Start with empty vector to accumulate all positions
    int count = 0;
    for (Boid other : boids) {
      float d = PVector.dist(position, other.position);
      if ((d > 0) && (d < neighbordist)) {
        PVector cpv = new PVector(0,0);
        cpv.add(other.position);
        cpv.mult(other.r/4);
        sum.add(cpv); // Add position
        count += other.r/4;
      }
    }
    if (count > 0) {
      sum.div(count);
      return seek(sum);  // Steer towards the position
    } 
    else {
      return new PVector(0, 0);
    }
  }
  
  boolean inPredatorMode() {
    PVector mousePos = new PVector(mouseX, mouseY);
    float smoothDist = PVector.dist(expPos, mousePos);
    
    return expSpeed > 6.5 && smoothDist < 80;
  }
  
  PVector predate (ArrayList<Boid> boids) {
    PVector pred = new PVector(mouseX, mouseY);
    float neighbordist = 100;
    PVector steer = new PVector(0, 0, 0);
    float count = 0;
    
    float d = PVector.dist(position, pred);
    if (d < neighbordist && inPredatorMode()) {
        PVector diff = PVector.sub(position, pred);
        diff.normalize();
        diff.div(d); // Weight by distance
        steer.add(diff);
        count++;            // Keep track of how many
    }
        if (count > 0) {
      steer.div((float)count);
    }

    // As long as the vector is greater than 0
    if (steer.mag() > 0) {
      // First two lines of code below could be condensed with new PVector setMag() method
      // Not using this method until Processing.js catches up
      // steer.setMag(maxspeed);

      // Implement Reynolds: Steering = Desired - Velocity
      steer.normalize();
      steer.mult(maxspeed);
      steer.sub(velocity);
      steer.limit(maxforce);
    }
    return steer;
  }
  
  
  PVector cursorAttract (ArrayList<Boid> boids) {
    PVector attractor = new PVector(mouseX, mouseY);
    PVector steer = new PVector(0, 0, 0);
    float count = 0;
    
    float d = PVector.dist(position, attractor);
    if (mousePressed) {
        PVector diff = PVector.sub(attractor, position);
        diff.normalize();
        //diff.div(d); // Weight by distance
        steer.add(diff);
        count++;            // Keep track of how many
    }
    if (count > 0) {
      steer.div((float)count);
    }

    // As long as the vector is greater than 0
    if (steer.mag() > 0) {
      // First two lines of code below could be condensed with new PVector setMag() method
      // Not using this method until Processing.js catches up
      // steer.setMag(maxspeed);

      // Implement Reynolds: Steering = Desired - Velocity
      steer.normalize();
      steer.mult(maxspeed);
      steer.sub(velocity);
      steer.limit(maxforce);
    }
    return steer;
  }
  
  PVector cursorAlign (ArrayList<Boid> boids) {
    PVector mousePos = new PVector(mouseX, mouseY);
    // Direction we want the points to go in
    float smoothDist = PVector.dist(expPos, mousePos);
    
    PVector steer = new PVector(0, 0, 0);
    float count = 0;
    
    if (smoothDist > 100 && expSpeed > 20) {
        PVector diff = PVector.sub(mousePos, expPos);
        diff.normalize();
        //diff.div(d); // Weight by distance
        steer.add(diff);
        count++;            // Keep track of how many
    }
    if (count > 0) {
      steer.div((float)count);
    }

    // As long as the vector is greater than 0
    if (steer.mag() > 0) {
      // First two lines of code below could be condensed with new PVector setMag() method
      // Not using this method until Processing.js catches up
      // steer.setMag(maxspeed);

      // Implement Reynolds: Steering = Desired - Velocity
      steer.normalize();
      steer.mult(maxspeed);
      steer.sub(velocity);
      steer.limit(maxforce);
    }
    return steer;
  }
}
