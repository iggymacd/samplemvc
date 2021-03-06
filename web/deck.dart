part of playing_cards;

class Deck{
  String name;
  Map<String,Card> cards;
  Deck(this.name,this.cards);
  bool isDealer = false;
  bool isNextToPlay = false;
  
  void addCard(Card card){
    if(card == null){
      return;
    }
    if(card.classList != null){
      card.classList.clear();
    }
    
    card.classList.add('card');
    if(name == 'south'){
      card.isFaceUp = true;
      card.isPlayable = true;
      card.classList.add(card.suit.name);
      //card.clickAction = 'playCard';
    }
    else if(name == 'east' || name == 'north' || name == 'west' ){
      card.isFaceUp = false;
      card.isPlayable = true;
      card.classList.add('back');
    }
    else if(name == 'round'){
      card.isFaceUp = true;
      card.isPlayable = false;
      card.classList.add(card.suit.name);
    }else{
      card.isFaceUp = false;
      card.isPlayable = false;
      card.classList.add('back');
    }
    cards[card.toString()] = card;
  }
  Card removeCard(String name){
    return cards.remove(name);
  }

  Card removeLast() {
    Card result;
    Collection currentKeys = cards.keys;
    if(currentKeys.length > 0){
      return cards.remove((currentKeys as List)[0]);
    }
    return result;
  }
}