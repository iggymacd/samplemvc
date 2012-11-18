part of playing_cards;

class Card {
  static int nextId = 0;
  int id;
  Rank rank;
  Suit suit;
  List<String> classList = ['card', 'deck', 'back'];
  bool isFaceUp;
  bool isPlayable;
  Card(this.rank, this.suit){
    id = nextId++;
    isFaceUp = false;
    isPlayable = false;
  }
  String toString(){
    return '${rank.letter} of ${suit.name}';
  }
  Map toMap() {
    Map map = new Map();
    map["id"] = id;
    map["rank"] = rank.letter;
    map["suit"] = suit.name;
    map["isFaceUp"] = isFaceUp;
    map["isPlayable"] = isPlayable;
    return map;
  }
}