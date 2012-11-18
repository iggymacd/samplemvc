part of model;
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
  static final int REGISTER_LOGGER = 12;
  static final int PLAY_CARD = 13;
  static final List<String> _typeName =
      const [ "join", "message", "leave", "timeout", "start", "stop", 
              "starting", "stopping", "waiting", "started", "profile", "uiReady", "registerLogger", "playCard"];

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
  Message.register(this._from)
  : _received = new Date.now(), _type = REGISTER_LOGGER;
  Message.playCard(this._from, this._card)
  : _received = new Date.now(), _type = PLAY_CARD;
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
  //void set messageNumber(int n) => _messageNumber = n;

  Map toMap() {
    Map map = new Map();
    map["from"] = _from;
    map["received"] = _received.toString();
    map["type"] = _type;
    map["typeName"] = _typeName[_type];
    if (_type == MESSAGE) map["message"] = _message;
    if (_type == PLAY_CARD) map["card"] = _card.toMap();
    //map["number"] = _messageNumber;
    return map;
  }

  static Message fromJson(String jsonSource) {
    Map jsonObject = JSON.parse(jsonSource);
    Message result = new Message.fromMap(jsonObject);
//    Map map = new Map();
//    map["from"] = _from;
//    map["received"] = _received.toString();
//    map["type"] = _type;
//    map["typeName"] = _typeName[_type];
//    if (_type == MESSAGE) map["message"] = _message;
//    if (_type == PLAY_CARD) map["card"] = _card;
    //map["number"] = _messageNumber;
    return result;
  }
  
  String toString(){
    return toMap().toString();
  }

  String _from;
  Date _received;
  int _type;
  String _message;
  Card _card;
  //String _handle;
  //int _messageNumber;
}
