library model;
import 'dart:math';
import 'playing_cards.dart';
//import 'package:samplemvc/playing_cards.dart';
//import 'playing_cards.dart';
var _app;

App get app{
  if(_app == null){
    _app = new App();
  }
  return _app;
}

class App {
  List<Card> cards;
  Map<String,Deck> decks;
  List<String> positions = ['south','west', 'north', 'east'];
  num dealer;
  num nextToPlay;
  App(){
    cards = createDeck();
    decks = new Map<String,Deck>();
    decks['dealer'] = new Deck('dealer',shuffle(cards));
    decks['north'] = new Deck('north', new List<Card>());
    decks['south'] = new Deck('south', new List<Card>());
    decks['east'] = new Deck('east', new List<Card>());
    decks['west'] = new Deck('west', new List<Card>());
    decks['discard'] = new Deck('discard', new List<Card>());
    decks['round'] = new Deck('round', new List<Card>());
    dealer = new Random().nextInt(positions.length);
    nextToPlay = (dealer + 1) % 4;
    decks[positions[dealer]].isDealer = true;
    decks[positions[nextToPlay]].isNextToPlay = true;
    //cards = shuffle(cards);
  }
  void dealCards(){
    num nextPlayer = dealer + 1;
    List cardsToDeal = decks['dealer'].cards;
    num numberOfCards = cardsToDeal.length;
    //print('there are ${numberOfCards} cards to deal.');
    Card currentCard;
    for(num i = 0; i < numberOfCards ; i++){
      currentCard = cardsToDeal.removeLast();
      num temp = nextPlayer % 4;
      //print(temp);
      decks[positions[temp]].addCard(currentCard);
      nextPlayer++;
    }
  }
}

List createDeck() {
  List<Card> result = new List<Card>();
  for (final currentRank in ranks){
    if(['5','4','3','2'].indexOf(currentRank.letter) != -1){
      continue;
    }
    for(final currentSuit in suits){
      result.add(new Card(currentRank, currentSuit));
    }
  }
  return result;
}
List ranks = [
              new Rank(0),
              new Rank(1),
              new Rank(2),
              new Rank(3),
              new Rank(4),
              new Rank(5),
              new Rank(6),
              new Rank(7),
              new Rank(8),
              new Rank(9),
              new Rank(10),
              new Rank(11),
              new Rank(12),
              ];
class Rank {
  var rankValue;
  Rank(this.rankValue){
    letter = rankValue == 8 ? '10' :'23456789TJQKA'[rankValue];
  }
  
  var letter;
  var nextLower;
  var nextHigher;
 
  
}
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

List shuffle(List myArray) {
  var m = myArray.length - 1, t, i, random;
  random = new Random();
  // While there remain elements to shuffle…
  //print('_____');
  while (m > 0) {
    // Pick a remaining element…
    i = random.nextInt(m);
    //print('i is $i');
    // And swap it with the current element.
    t = myArray[m];
    myArray[m] = myArray[i];
    myArray[i] = t;
    //print(
        m--;
        //);
  }

  return myArray;
}
