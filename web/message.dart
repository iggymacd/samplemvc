part of model;
const JOIN = 0;
const MESSAGE = 1;
const LEAVE = 2;
const TIMEOUT = 3;
const START = 4;
const STOP = 5;
const STARTING = 6;
const STOPPING = 7;
const WAITING = 8;
const STARTED = 9;
const PROFILE = 10;
const UI_READY = 11;
const REGISTER = 12;
const PLAY_CARD = 13;
const SET_DEALER = 14;
class Message {
  static final List<String> _typeName =
      const [ "join", "message", "leave", "timeout", "start", "stop", 
              "starting", "stopping", "waiting", "started", "profile", 
              "uiReady", "register", "playCard", "setDealer"];

  Message.start(this._from)
  : _received = new Date.now(){ _type = START;}
  Message.starting(this._from)
  : _received = new Date.now(){ _type = STARTING;}
  Message.started(this._from)
  : _received = new Date.now(){ _type = STARTED;}
  Message.stop(this._from)
  : _received = new Date.now(){ _type = STOP;}
  Message.stopping(this._from)
  : _received = new Date.now(){ _type = STOPPING;}
  Message.join(this._from)
      : _received = new Date.now(){ _type = JOIN;}
  Message(this._from, this._message)
  : _received = new Date.now(){ _type = MESSAGE;}
//  Message.profile(this._from, this._handle)
//      : _received = new Date.now(){ _type = PROFILE;
  Message.leave(this._from)
      : _received = new Date.now(){ _type = LEAVE;}
  Message.timeout(this._from)
  : _received = new Date.now(){ _type = TIMEOUT;}
  Message.waiting(this._from)
  : _received = new Date.now(){ _type = WAITING;}
  Message.uiReady(this._from)
  : _received = new Date.now(){ _type = UI_READY;}
  Message.register(this._from)
  : _received = new Date.now(){ _type = REGISTER;}
  Message.playCard(this._from, this._card)
  : _received = new Date.now(){ _type = PLAY_CARD;}
  Message.setDealer(this._from, this._dealer)
  : _received = new Date.now(){ 
    _type = SET_DEALER;
    _message = 'Setting Dealer to $_dealer';
  }
  Message.fromMap(Map sourceMap){
    _from = sourceMap['from'];
    _received = new Date.fromString(sourceMap['received']);
    _type = sourceMap['type'];
    _message = sourceMap['message'] == null ? null : sourceMap['message'];
  }

  String get from => _from;
  Date get received => _received;
  String get message => _message;
  int get type => _type;
  String get dealer => _dealer;
  //void set messageNumber(int n) => _messageNumber = n;

  Map toMap() {
    Map map = new Map();
    map["from"] = _from;
    map["received"] = _received.toString();
    map["type"] = _type;
    map["typeName"] = _typeName[_type];
    if (_type == MESSAGE) map["message"] = _message;
    if (_type == PLAY_CARD) map["card"] = _card.toMap();
    if (_type == SET_DEALER) map["dealer"] = _dealer;
    //map["number"] = _messageNumber;
    return map;
  }

  static Message fromJson(String jsonSource) {
    Map jsonObject = JSON.parse(jsonSource);
    Message result = new Message.fromMap(jsonObject);
    return result;
  }
  
  String toString(){
    return toMap().toString();
  }

  String _from;
  Date _received;
  int _type;
  String _message;
  String _dealer;
  Card _card;
  //String _handle;
  //int _messageNumber;
}
