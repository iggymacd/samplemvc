// Auto-generated from sampletest.html.
// DO NOT EDIT.

library sampletest_html;

import 'dart:html' as autogenerated;
import 'package:web_components/web_components.dart' as autogenerated;

import 'dart:html';

import 'dart:json';

import '../../web/model.dart';

import 'package:web_components/web_components.dart';


// Original code
main() {
        Message m = new Message('al', 'myMessage');
        print(m.toMap());
        String jsonSample =  JSON.stringify(m.toMap());
        print(jsonSample);
        Message messageFromJson = Message.fromJson(jsonSample);
        print(messageFromJson);
        print(messageFromJson is Message);
      }
    

// Additional generated code
/** Create the views and bind them to models. */
void init_autogenerated() {
  // Create view.
  var _root = new autogenerated.DocumentFragment.html(_INITIAL_PAGE);

  autogenerated.DivElement _container;
  


  // Initialize fields.
  _container = _root.query('#container');
  

  // Attach model to views.


  // Attach view to the document.
  autogenerated.document.body.nodes.add(_root);
  _root = autogenerated.document.body;
}

final String _INITIAL_PAGE = '''

    <h1>Samplemvc</h1>    
    <p>Hello Dartisans!</p>    
    <div id="container"> 
      <p> 
      </p>
    </div>
    
  

''';
