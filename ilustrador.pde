import oscP5.*;
import netP5.*;

OscP5 osc;
NetAddress pd;

Table games;
ArrayList<GameBubble> gameList = new ArrayList<GameBubble>();

int spawnIndex = 0;
int spawnRate = 8;

void setup() {
  size(1000, 700);
  pixelDensity(1);
  frameRate(60);
  
  games = loadTable("data.csv", "header");

  osc = new OscP5(this, 11111);
  pd = new NetAddress("127.0.0.1", 11111);
}

void draw() {
  background(18);

  if (frameCount % spawnRate == 0 && spawnIndex < games.getRowCount()) {
    gameList.add(new GameBubble(games.getRow(spawnIndex)));
    spawnIndex++;
  }

  for (int i = gameList.size()-1; i >= 0; i--) {
    GameBubble g = gameList.get(i);
    g.update();
    g.display();
    if (g.remove) gameList.remove(i);
  }
}

class GameBubble {

  float x, y;
  float vx, vy;
  float sizeB;

  float metaScore;
  float userScore;
  String title;
  String[] genres;

  boolean remove = false;

  GameBubble(TableRow row) {

    // Fix missing values
    metaScore = row.getFloat("meta_score");
    if (Float.isNaN(metaScore)) metaScore = 50;

    userScore = row.getFloat("user_score");
    if (Float.isNaN(userScore)) userScore = 5;

    title = row.getString("title");
    if (title == null || title.trim().length() == 0) title = "Unknown";

    // genre cleanup
    String raw = row.getString("genres");
    if (raw == null) raw = "Other";
    String clean = raw.replace("[","").replace("]","").replace("'","").trim();
    genres = split(clean, ",");

    // position
    x = random(80, width - 80);
    y = height + 40;

    // bubble size -> meta score
    sizeB = map(metaScore, 0, 100, 25, 140);

    // bubble speed -> user score inverted
    float norm = 1 - (userScore / 10.0);
    float speed = map(norm, 0, 1, 1.2, 6.0);
    if (Float.isNaN(speed)) speed = 2;

    vy = -speed;
    vx = random(-0.8, 0.8);

    // SEND SOUND HERE
    sendSound();
  }

  void update() {
    x += vx;
    y += vy;

    if (x < sizeB/2 || x > width - sizeB/2) vx *= -1;
    if (y < -200) remove = true;
  }

  void display() {
    noStroke();

    // color by genre
    String g = trim(genres[0]);
    color col;

    if (g.equals("Action")) col = color(231, 76, 60);       // red
    else if (g.equals("Miscellaneous")) col = color(52, 152, 219); // blue
    else if (g.equals("Role-Playing")) col = color(243, 156, 18);  // orange
    else if (g.equals("Strategy")) col = color(46, 204, 113);      // green
    else if (g.equals("Racing")) col = color(155, 89, 182);        // purple
    else col = color(149, 165, 166);                              // gray

    fill(col, 200);
    ellipse(x, y, sizeB, sizeB);

    // title inside bubble
    textAlign(CENTER, CENTER);

    float fs = map(sizeB, 20, 140, 8, 22);
    if (Float.isNaN(fs)) fs = 12;

    textSize(fs);
    fill(255, 240);
    text(title, x, y);
  }

  // ✔ NEW SOUND METHOD
  void sendSound() {
    OscMessage m = new OscMessage("/gameData");

    m.add(metaScore);           // bubble size info
    m.add(userScore);           // speed info
    m.add(sizeB);               // visual size
    m.add(vy);                  // speed value
    m.add(trim(genres[0]));     // main genre

    osc.send(m, pd);
  }
}
