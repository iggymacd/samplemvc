// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Common utility functions used by code generated by the dwc compiler. */
library templating;

import 'dart:html';
import 'package:web_components/safe_html.dart';
import 'package:web_components/watcher.dart';

/** 
 * Removes all sibling nodes from `start.nextNode` until [end] (inclusive). For
 * convinience, this function returns [start].
 */
Node removeNodes(Node start, Node end) {
  while (start != end) {
    var prev = end.previousNode;
    end.remove();
    end = prev;
  }
  return start;
}

/**
 * Take the value of a bound expression and creates an HTML node with its value.
 * Normaly bindings are associated with text nodes, unless [binding] has the
 * [SafeHtml] type, in which case an html element is created for it.
 */
Node nodeForBinding(binding) => binding is SafeHtml
    ? new Element.html(binding.toString()) : new Text(binding.toString());

/**
 * Updates a data-bound [node] to a new [value]. If the new value is not
 * [SafeHtml] and the node is a [Text] node, then we update the node in place.
 * Otherwise, the node is replaced in the DOM tree and the new node is returned.
 */
Node updateBinding(value, Node node) {
  var isSafeHtml = value is SafeHtml;
  var stringValue = value.toString();
  if (!isSafeHtml && node is Text) {
    node.text = stringValue;
  } else {
    var old = node;
    node = isSafeHtml ? new Element.html(stringValue) : new Text(stringValue);
    old.replaceWith(node);
  }
  return node;
}

/**
 * Insert every node in [nodes] under [parent] before [reference]. [reference]
 * should be a child of [parent] or `null` if inserting at the end.
 */
void insertAllBefore(Node parent, Node reference, List<Node> nodes) {
  nodes.forEach((n) => parent.insertBefore(n, reference));
}

/**
 * Bind the result of [exp] to the class attribute in [elem]. [exp] is a closure
 * that can return a string, a list of strings, an string with spaces, or null.
 *
 * You can bind a single class attribute by binding a getter to the property
 * defining your class.  For example,
 *
 *     var class1 = 'pretty';
 *     bindCssClasses(e, () => class1);
 *
 * In this example, if you update class1 to null or an empty string, the
 * previous value ('pretty') is removed from the element.
 *
 * You can bind multiple class attributes in several ways: by returning a list
 * of values in [exp], by returning in [exp] a string with multiple classes
 * separated by spaces, or by calling this function several times. For example,
 * suppose you want to bind 2 classes on an element,
 *
 *     var class1 = 'pretty';
 *     var class2 = 'selected';
 *
 * and you want to independently change class1 and class2. For instance, If you
 * set `class1` to null, you'd like `pretty` will be removed from `e.classes`,
 * but `selected` to be kept.  The tree alternatives mentioned earlier look as
 * follows:
 *
 *   * binding classes with a list:
 *
 *         bindCssClasses(e, () => [class1, class2]);
 *
 *   * binding classes with a string:
 *
 *         bindCssClasses(e, () => "${class1 != null ? class1 : ''} "
 *                                 "${class2 != null ? class2 : ''}");
 *
 *   * binding classes separately:
 *
 *         bindCssClasses(e, () => class1);
 *         bindCssClasses(e, () => class2);
 */
WatcherDisposer bindCssClasses(Element elem, dynamic exp()) {
  return watchAndInvoke(exp, (e) {
    var toRemove = e.oldValue;
    if (toRemove is String && toRemove != '') {
      if (toRemove.contains(' ')) {
        elem.classes.removeAll(toRemove.split(' '));
      } else {
        elem.classes.remove(toRemove);
      }
    } else if (toRemove is List<String>) {
      elem.classes.removeAll(toRemove.filter((e) => e != null && e != ''));
    }

    var toAdd = e.newValue;
    if (toAdd is String && toAdd != '') {
      if (toAdd.contains(' ')) {
        elem.classes.addAll(toAdd.split(' '));
      } else {
        elem.classes.add(toAdd);
      }
    } else if (toAdd is List<String>) {
      elem.classes.addAll(toAdd.filter((e) => e != null && e != ''));
    }
  });
}

/** Bind the result of [exp] to the style attribute in [elem]. */
WatcherDisposer bindStyle(Element elem, Map<String, String> exp()) {
  return watchAndInvoke(exp, (e) {
    if (e.oldValue is Map<String, String>) {
      var props = e.newValue;
      if (props is! Map<String, String>) props = const {};
      for (var property in e.oldValue.keys) {
        if (!props.containsKey(property)) {
          // Value will not be overwritten with new setting. Remove.
          elem.style.removeProperty(property);
        }
      }
    }
    if (e.newValue is! Map<String, String>) {
      throw new DataBindingError("Expected Map<String, String> value "
        "to data-style binding.");
    }
    e.newValue.forEach(elem.style.setProperty);
  });
}

/** An error thrown when data bindings are set up with incorrect data. */
class DataBindingError implements Error {
  final message;
  DataBindingError(this.message);
  toString() => "Data binding error: $message";
}