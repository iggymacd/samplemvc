library model;
import 'dart:math';
import 'dart:isolate';
import 'playing_cards.dart';
import 'package:web_components/watcher.dart';
//import 'package:samplemvc/playing_cards.dart';
//import 'playing_cards.dart';
var _app;

App get app{
  if(_app == null){
    _app = new App();
  }
  return _app;
}
gameIsolate() {
  port.receive((msg, replyTo) {
    print('doing some work ${app.cards.length}');
    if (replyTo != null) replyTo.send(msg);
  });
}

class App {
  List<Card> cards;
  Map<String,Deck> decks;
  List<String> positions = ['south','west', 'north', 'east'];
  Timer timer;
  //Game currentGame;
  num dealer;
  num nextToPlay;
  var sender;
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


    sender = spawnFunction(gameIsolate);
    var receiver = new ReceivePort();
    receiver.receive((Message msg, _) {
      if (msg.type == Message.MESSAGE) {
        print('shutting down');
        print(msg.from);
        print(msg.message);
        print(msg.toMap());
        //receiver.close();
      }
    });
    sender.send(new Message('north', 'shutdown'), receiver.toSendPort());
    
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
class Message {
  static final int JOIN = 0;
  static final int MESSAGE = 1;
  static final int LEAVE = 2;
  static final int TIMEOUT = 3;
  static final int START = 4;
  static final int STOP = 5;
  static final int STARTING = 6;
  static final int STOPPING = 7;
  static final int WAITING = 8;
  static final int STARTED = 9;
  static final int PROFILE = 10;
  static final int UI_READY = 11;
  static final List<String> _typeName =
      const [ "join", "message", "leave", "timeout", "start", "stop", 
              "starting", "stopping", "waiting", "started", "profile", "uiReady"];

  Message.start(this._from)
  : _received = new Date.now(), _type = START;
  Message.starting(this._from)
  : _received = new Date.now(), _type = STARTING;
  Message.started(this._from)
  : _received = new Date.now(), _type = STARTED;
  Message.stop(this._from)
  : _received = new Date.now(), _type = STOP;
  Message.stopping(this._from)
  : _received = new Date.now(), _type = STOPPING;
  Message.join(this._from)
      : _received = new Date.now(), _type = JOIN;
  Message(this._from, this._message)
  : _received = new Date.now(), _type = MESSAGE;
//  Message.profile(this._from, this._handle)
//      : _received = new Date.now(), _type = PROFILE;
  Message.leave(this._from)
      : _received = new Date.now(), _type = LEAVE;
  Message.timeout(this._from)
  : _received = new Date.now(), _type = TIMEOUT;
  Message.waiting(this._from)
  : _received = new Date.now(), _type = WAITING;
  Message.uiReady(this._from)
      : _received = new Date.now(), _type = UI_READY;

  String get from => _from;
  Date get received => _received;
  String get message => _message;
  int get type => _type;
  //void set messageNumber(int n) => _messageNumber = n;

  Map toMap() {
    Map map = new Map();
    map["from"] = _from;
    map["received"] = _received.toString();
    map["type"] = _type;
    map["typeName"] = _typeName[_type];
    if (_type == MESSAGE) map["message"] = _message;
    //if (_type == PROFILE) map["handle"] = _handle;
    //map["number"] = _messageNumber;
    return map;
  }

  String _from;
  Date _received;
  int _type;
  String _message;
  //String _handle;
  //int _messageNumber;
}
