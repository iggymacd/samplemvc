
part of model;

Map<String,SendPort> ports;
String dealer;
String nextToPlay;
gameIsolate() {
  ports = new Map<String,SendPort>();
  port.receive((msg, replyTo) {
    //print('doing some work ${app.cards.length}');
    if (replyTo != null){
      if(msg is Map){
//      ports['logger'] = sendPort;
//      ports['logger'].send(msg);
        process(msg, replyTo);
      }else{
        //replyTo.send(msg);
      }
      //replyTo.send(msg);
    }
  });
}

process(msg, sendPort) {
  switch (msg['type']) {
    case PLAY_CARD:
      Message result;
      if(msg['from'] == nextToPlay){
        result = new Message('gameContoller','success');
        sendPort.send(result.toMap());
        ports['logger'].send(result.toMap());
        int currentPosition = positions.indexOf(nextToPlay);
        nextToPlay = positions[(currentPosition + 1) % 4];
      }else{
        result = new Message('gameContoller','failed');
        sendPort.send(result.toMap());
        ports['logger'].send(result.toMap());
      }
      break;
    case SET_DEALER:
      //logger = sendPort;
      dealer = msg['dealer'];
      int dealerPosition = positions.indexOf(dealer);
      nextToPlay = positions[(dealerPosition + 1) % 4];
      ports['logger'].send(msg);
      //sendPort.send(msg);
      break;
    case REGISTER:
      String registerMessage = msg['message'];
      ports[registerMessage] = sendPort;
      ports['logger'].send(msg);
      break;
    case START :
      //play hand 9 times
      //Future<Map<String,Card>> playRoundResults = playRound(nextToPlay);
      playRound(nextToPlay).then((result){
        //ports['controller'].send(new Message.transferCard(nextToPlay).toMap());
        ports['logger'].send(result);
      });
      break;
    default:
      //sendPort.send(msg);
  }
}
Future<Map<String, String>> playRound(String startPosition){
  Future result = new Future.immediate(new Map<String,String>());
  Timer t;// = new Timer(500, (Timer timer){
    
  //});
  for(int i = 0 ; i < 9 ; i++){
    //t = new Timer(500, (Timer timer){
    //});
    //result = result.chain((value) => addDelay(value, 500));
    result = result.chain((value) => playHand(value,i));
  }
  return result;
}

Future<Map<String, String>> addDelay(Map<String,String> target, int timeToWait){
  Completer c = new Completer();
  new Timer(timeToWait, (Timer timer){
    c.complete(target);
  });
  return c.future;
}

Future<Map<String, String>> playHand(Map<String,String> target, int handNumber){
  //ports['logger'].send({'test':'hand $handNumber'});
  Future result = new Future.immediate(target);
  for(int i = 0 ; i < 4 ; i++){
    //ports['logger'].send({'test':'hand $handNumber , card $i'});
    result = result.chain((value) => playCard(value, handNumber, i));
  }
  return result;
}

Future<Map<String, String>> playCard(Map<String,String> target, int handNumber, int cardNumber){
  //ports['logger'].send({'test':'hand $handNumber'});
  //Future result = new Future.immediate(target);
  String currentPositionToPlay = nextToPlay;
  Completer c = new Completer();
  ReceivePort returnPort = new ReceivePort();
  returnPort.receive((msg, _) {
    //if (replyTo != null) replyTo.send(msg);
    target['card ${counter++}'] = 'hand $handNumber :: card $cardNumber is $msg';
    advanceNextToPlay(currentPositionToPlay);
    c.complete(target);
  } );
  if(ports['controller'] != null){
    ports['controller'].send(new Message.yourTurn(currentPositionToPlay).toMap(), returnPort.toSendPort());
  }
  return c.future;
//  return result;
}

advanceNextToPlay(currentNextToPlay) {
  int currentPosition = positions.indexOf(currentNextToPlay);
  nextToPlay = positions[(currentPosition + 1) % 4];
}

num counter = 0;
