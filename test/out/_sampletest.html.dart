// Auto-generated from sampletest.html.
// DO NOT EDIT.

library sampletest_html;

import 'dart:html' as autogenerated;
import 'package:web_components/watcher.dart' as autogenerated;

import 'dart:html';

import 'package:web_components/web_components.dart';


// Original code
main() {
      }
    

// Additional generated code

autogenerated.DivElement _container;


/** Create the views and bind them to models. */
void init_autogenerated() {
  // Create view.
  var _root = new autogenerated.DocumentFragment.html(_INITIAL_PAGE);

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