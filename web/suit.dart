part of playing_cards;

List suits = [
              new Suit(0),
              new Suit(1),
              new Suit(2),
              new Suit(3)
              ];
class Suit {
  Suit(this.suitValue){
    letter = 'DCHS'[suitValue];
    back = 'nbsp';
    color = (letter == 'C' || letter == 'S' ? 'black' : 'red' );
    if(letter == 'C'){
      name = 'clubs';
    }else if(letter == 'D'){
      name = 'diams';
    }else if(letter == 'H'){
      name = 'hearts';
    }else{
      name = 'spades';
    }
  }
  String get entityName{
    return '&${name};';
  }
  var suitValue;
  var letter;
  var color;
  var name;
  var back;
}
