
part of model;

Map<String,SendPort> ports;
String dealer;
String nextToPlay;
gameIsolate() {
  port.receive((msg, replyTo) {
    //print('doing some work ${app.cards.length}');
    if (replyTo != null){
      if(msg is Map){
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
      ports['logger'] = sendPort;
      ports['logger'].send(msg);
      break;
    case START :
      ports['logger'].send(msg);
      break;
    default:
      //sendPort.send(msg);
  }
}

