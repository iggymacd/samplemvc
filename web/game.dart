
part of model;

SendPort logger;

gameIsolate() {
  port.receive((msg, replyTo) {
    //print('doing some work ${app.cards.length}');
    if (replyTo != null){
      if(msg is Message){
        process(msg, replyTo);
      }else{
        //replyTo.send(msg);
      }
      //replyTo.send(msg);
    }
  });
}

process(msg, sendPort) {
  switch (msg.type) {
    case 13:
      //logger = sendPort;
      logger.send(msg);
      sendPort.send(msg);
      break;
    case 12:
      logger = sendPort;
      logger.send(msg);
      break;
    case 4 :
      logger.send(msg);
      break;
    default:
      //sendPort.send(msg);
  }
}

