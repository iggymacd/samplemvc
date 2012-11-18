part of playing_cards;

class Card {
  static var nextId = 0;
  var id;
  Rank rank;
  Suit suit;
  List<String> classList = ['card', 'deck', 'back'];
  bool isFaceUp;
  bool isPlayable;
  Card(this.rank, this.suit){
    id = 'id#${nextId++}';
    isFaceUp = false;
    isPlayable = false;
  }
  String toString(){
    return '${rank.letter} of ${suit.name}';
  }
}