library model;
import 'dart:math';
import 'dart:isolate';
import 'dart:json';
import 'playing_cards.dart';
import 'package:web_components/watcher.dart';
//import 'package:samplemvc/playing_cards.dart';
//import 'playing_cards.dart';
part 'message.dart';
part 'game.dart';
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
  Timer timer;
  //Game currentGame;
  num dealer;
  num nextToPlay;
  SendPort gamePort;
  ReceivePort loggerPort;
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
    //currentGame = new Game();
    //cards = shuffle(cards);
    loggerPort = new ReceivePort();
    loggerPort.receive((Map msg, _) {
      //if (msg.type == Message.MESSAGE) {
        //print('shutting down');
        print(msg['from']);
        //print(msg.message);
        print(msg);
        //receiver.close();
      //}
    });
    gamePort = spawnFunction(gameIsolate);
  }
  
  
  void startGame(){
    num nextPlayer = dealer + 1;
    List cardsToDeal = decks['dealer'].cards;
    num numberOfCards = cardsToDeal.length;
    //print('there are ${numberOfCards} cards to deal.');
    Card currentCard;
    //timer = new Timer.repeating(1000, (Timer timer) => runMonitor());
    for(num i = 0; i < numberOfCards ; i++){
      Card currentCard = cardsToDeal.removeLast();
      num temp = nextPlayer % 4;
//      new Timer(500, (Timer timer){
        decks[positions[temp]].addCard(currentCard);
//        dispatch();
//        print('here');
//      });
      
        nextPlayer++;
      }

    gamePort.send(new Message.register('app').toMap(), loggerPort.toSendPort());
    gamePort.send(new Message.start('app').toMap(), loggerPort.toSendPort());
    
  }
  
  Future<Map> playCard(Card card, String position){
    Completer c = new Completer();
    ReceivePort returnPort = new ReceivePort();
    returnPort.receive((msg, replyTo) {
      //if (replyTo != null) replyTo.send(msg);
      c.complete(msg);
    } );
    if(gamePort != null){
      gamePort.send(new Message.playCard(position,card).toMap(), returnPort.toSendPort());
    }
    return c.future;
  }
  
  void tranferCard(Card source, Deck target){
    target.addCard(source);
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
