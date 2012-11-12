// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Collects several code emitters for the template tool. */
// TODO(sigmund): add visitor that applies all emitters on a component
// TODO(sigmund): add support for conditionals, so context is changed at that
// point.
library emitters;

import 'package:html5lib/dom.dart';
import 'package:html5lib/dom_parsing.dart';
// TODO(jmesserly): this utility should be somewhere else.
import 'package:html5lib/src/utils.dart' show reversed;

import 'code_printer.dart';
import 'codegen.dart' as codegen;
import 'file_system/path.dart';
import 'files.dart';
import 'html5_utils.dart';
import 'info.dart';
import 'messages.dart';
import 'utils.dart';

/**
 * An emitter for a web component feature.  It collects all the logic for
 * emitting a particular feature (such as data-binding, event hookup) with
 * respect to a single HTML element.
 */
abstract class Emitter<T extends ElementInfo> {
  /** Element for which code is being emitted. */
  final Element elem;

  /** Information about the element for which code is being emitted. */
  final T elemInfo;

  Emitter(T elemInfo) : elem = elemInfo.node, elemInfo = elemInfo;

  /** Emit declarations needed by this emitter's feature. */
  void emitDeclarations(Context context) {}

  /** Emit feature-related statemetns in the `created` method. */
  void emitCreated(Context context) {}

  /** Emit feature-related statemetns in the `inserted` method. */
  void emitInserted(Context context) {}

  /** Emit feature-related statemetns in the `removed` method. */
  void emitRemoved(Context context) {}

  // The following are helper methods to make it simpler to write emitters.
  Context contextForChildren(Context context) => context;

  /** Generates a unique Dart identifier in the given [context]. */
  String newName(Context context, String prefix) =>
      '${prefix}${context.nextId()}';
}

/**
 * Context used by an emitter. Typically representing where to generate code
 * and additional information, such as total number of generated identifiers.
 */
class Context {
  final CodePrinter declarations;
  final CodePrinter createdMethod;
  final CodePrinter insertedMethod;
  final CodePrinter removedMethod;

  Context([CodePrinter declarations,
           CodePrinter createdMethod,
           CodePrinter insertedMethod,
           CodePrinter removedMethod])
      : this.declarations = getOrCreatePrinter(declarations),
        this.createdMethod = getOrCreatePrinter(createdMethod),
        this.insertedMethod = getOrCreatePrinter(insertedMethod),
        this.removedMethod = getOrCreatePrinter(removedMethod);

  // TODO(sigmund): keep separate counters for ids, listeners, watchers?
  int _totalIds = 0;
  int nextId() => ++_totalIds;

  static getOrCreatePrinter(CodePrinter p) => p != null ? p : new CodePrinter();
}

/**
 * Generates a field for any element that has either event listeners or data
 * bindings.
 */
class ElementFieldEmitter extends Emitter<ElementInfo> {
  ElementFieldEmitter(ElementInfo info) : super(info);

  void emitDeclarations(Context context) {
    var type = htmlElementNames[elem.tagName];
    // Note: this will eventually be the component's class name if it is a
    // known x-tag.
    if (type == null) type = 'UnknownElement';
    context.declarations.add('autogenerated.$type ${elemInfo.identifier};');
  }

  void emitCreated(Context context) {
    // TODO(jmesserly): there's an asymmetry here. In one case, the child is
    // already in the document but not in the other case.
    if (elemInfo.needsQuery) {
      var parentId = '_root';
      for (var p = elemInfo.parent; p != null; p = p.parent) {
        if (p.identifier != null) {
          parentId = p.identifier;
          break;
        }
      }

      context.createdMethod.add(
          "${elemInfo.identifier} = $parentId.query('#${elemInfo.node.id}');");
    } else {
      _emitHtmlElement(context.createdMethod, elemInfo);
    }
  }

  void emitRemoved(Context context) {
    context.removedMethod.add("${elemInfo.identifier} = null;");
  }
}


/**
 * Generates event listeners attached to a node and code that attaches/detaches
 * the listener.
 */
class EventListenerEmitter extends Emitter<ElementInfo> {

  EventListenerEmitter(ElementInfo info) : super(info);

  /** Generate a field for each listener, so it can be detached on `removed`. */
  void emitDeclarations(Context context) {
    elemInfo.events.forEach((name, events) {
      for (var event in events) {
        var listenerName = '_listener${elemInfo.identifier}_${name}_';
        event.listenerField = newName(context, listenerName);
        context.declarations.add(
          'autogenerated.EventListener ${event.listenerField};');
      }
    });
  }

  /** Define the listeners. */
  // TODO(sigmund): should the definition of listener be done in `created`?
  void emitInserted(Context context) {
    var elemField = elemInfo.identifier;
    elemInfo.events.forEach((name, events) {
      for (var event in events) {
        var field = event.listenerField;
        context.insertedMethod.add('''
          $field = (e) {
            ${event.action(elemField, "e")};
            autogenerated.dispatch();
          };
          $elemField.on.${event.eventName}.add($field);
        ''');
      }
    });
  }

  /** Emit feature-related statements in the `removed` method. */
  void emitRemoved(Context context) {
    elemInfo.events.forEach((name, events) {
      for (var event in events) {
        var field = event.listenerField;
        context.removedMethod.add('''
          ${elemInfo.identifier}.on.${event.eventName}.remove($field);
          $field = null;
        ''');
      }
    });
  }
}

/** Generates watchers that listen on data changes and update a DOM element. */
class DataBindingEmitter extends Emitter<ElementInfo> {
  DataBindingEmitter(ElementInfo info) : super(info);

  /** Emit a field for each disposer function. */
  void emitDeclarations(Context context) {
    var elemField = elemInfo.identifier;
    elemInfo.attributes.forEach((name, attrInfo) {
      attrInfo.stopperNames = [];
      attrInfo.bindings.forEach((b) {
        var stopperName = newName(context, '_stopWatcher${elemField}_');
        attrInfo.stopperNames.add(stopperName);
        context.declarations.add('autogenerated.WatcherDisposer $stopperName;');
      });
    });

    if (elemInfo.contentBinding != null) {
      elemInfo.stopperName = newName(context, '_stopWatcher${elemField}_');
      context.declarations.add(
          'autogenerated.WatcherDisposer ${elemInfo.stopperName};');
    }

    // Declare stoppers for children text nodes with content binding.
    for (var childInfo in elemInfo.children) {
      if (childInfo.contentBinding != null) {
        var childField = elemInfo.identifier;
        childInfo.stopperName = newName(context, '_stopWatcher${childField}_');
        context.declarations.add(
            'autogenerated.WatcherDisposer ${childInfo.stopperName};');
      }
    }

  }

  /** Watchers for each data binding. */
  void emitInserted(Context context) {
    var elemField = elemInfo.identifier;

    // stop-functions for watchers associated with data-bound attributes
    elemInfo.attributes.forEach((name, attrInfo) {
      if (attrInfo.isClass) {
        for (int i = 0; i < attrInfo.bindings.length; i++) {
          var stopperName = attrInfo.stopperNames[i];
          var exp = attrInfo.bindings[i];
          context.insertedMethod.add('''
              $stopperName = autogenerated.watchAndInvoke(() => $exp, (e) {
                if (e.oldValue != null && e.oldValue != '') {
                  $elemField.classes.remove(e.oldValue);
                }
                if (e.newValue != null && e.newValue != '') {
                  $elemField.classes.add(e.newValue);
                }
              });
          ''');
        }
      } else {
        var val = attrInfo.boundValue;
        var stopperName = attrInfo.stopperNames[0];
        var setter;
        // TODO(sigmund): use setters when they are available (issue #112)
        //                Need to know if an attr is known for an element.
        if ((elem.tagName == 'input' &&
             (name == 'value' || name == 'checked')) ||
            name == 'hidden') {
          setter = name;
        } else {
          setter = 'attributes["$name"]';
        }
        context.insertedMethod.add('''
            $stopperName = autogenerated.watchAndInvoke(() => $val, (e) {
            $elemField.$setter = e.newValue;
            });
        ''');
      }
    });

    // Emit functions for any data-bound content on this element or children of
    // this element.
    _emitContentWatchInvoke(context, elemInfo, elemField);
    for (var childInfo in elemInfo.children) {
      _emitContentWatchInvoke(context, childInfo, elemField);
    }
  }

  /** stop-functions for watchers associated with data-bound content. */
  void _emitContentWatchInvoke(Context context, ElementInfo info,
                               String elemField) {
    if (info.contentBinding != null) {
      var stopperName = info.stopperName;
      // TODO(sigmund): track all subexpressions, not just the first one.
      var val = info.contentBinding;
      context.insertedMethod.add('''
          $stopperName = autogenerated.watchAndInvoke(() => $val, (e) {
            $elemField.innerHTML = ${info.contentExpression};
          });
      ''');
    }
  }


  /** Call the dispose method on all watchers. */
  void emitRemoved(Context context) {
    elemInfo.attributes.forEach((name, attrInfo) {
      attrInfo.stopperNames.forEach((stopperName) {
        context.removedMethod.add('$stopperName();');
      });
    });
    if (elemInfo.contentBinding != null) {
      context.removedMethod.add('${elemInfo.stopperName}();');
    }
    for (var childInfo in elemInfo.children) {
      if (childInfo.contentBinding != null) {
        context.removedMethod.add('${childInfo.stopperName}();');
      }
    }
  }
}

/**
 * Emits code for web component instantiation. For example, if the source has:
 *
 *     <x-hello>John</x-hello>
 *
 * And the component has been defined as:
 *
 *    <element name="x-hello" extends="div" constructor="HelloComponent">
 *      <template>Hello, <content>!</template>
 *      <script type="application/dart"></script>
 *    </element>
 *
 * This will ensure that the Dart HelloComponent for `x-hello` is created and
 * attached to the appropriate DOM node.
 *
 * Also, this copies values from the scope into the object at component creation
 * time, for example:
 *
 *     <x-foo data-value="bar:baz">
 *
 * This will set the "bar" property of FooComponent to be "baz".
 */
class ComponentInstanceEmitter extends Emitter<ElementInfo> {
  ComponentInstanceEmitter(ElementInfo info) : super(info);

  void emitCreated(Context context) {
    var component = elemInfo.component;
    if (component == null) return;

    var id = elemInfo.identifier;
    context.createdMethod.add(
        'var component$id = new ${component.constructor}.forElement($id);');

    elemInfo.values.forEach((name, value) {
      context.createdMethod.add('component$id.$name = $value;');
    });

    context.createdMethod.add('component$id.created_autogenerated();')
                         .add('component$id.created();');
  }

  void emitInserted(Context context) {
    if (elemInfo.component == null) return;

    // Note: watchers are intentionally hooked up after inserted() has run,
    // in case it makes any changes to the data.
    var id = elemInfo.identifier;
    context.insertedMethod.add('$id.xtag.inserted();')
                          .add('$id.xtag.inserted_autogenerated();');
  }

  void emitRemoved(Context context) {
    if (elemInfo.component == null) return;

    var id = elemInfo.identifier;
    context.removedMethod.add('$id.xtag.removed_autogenerated();')
                         .add('$id.xtag.removed();');
  }
}

/**
 * Emitter of template conditionals like `<template instantiate="if test">` or
 * `<td template instantiate="if test">`.
 *
 * For a template element, we leave the (childless) template element in the
 * tree and use it as a reference point for child insertion. This matches
 * native MDV behavior.
 *
 * For a template attribute, we leave the (childless) element in the tree as
 * a marker, hidden with 'display:none', and use it as a reference point for
 * insertion.
 */
// TODO(jmesserly): is this good enough for template attributes? we need
// *something* for this case:
// <tr>
//   <td>some stuff</td>
//   <td>other stuff</td>
//   <td template instantiate="if test">maybe this stuff</td>
//   <td template instantiate="if test2">maybe other stuff</td>
//   <td>more random stuff</td>
// </tr>
//
// We can't necessarily rely on child position because of possible mutation,
// unless we're willing to say that "if" requires a fixed number of children.
// If that's the case, we need a way to check for this error case and alert the
// developer.
class ConditionalEmitter extends Emitter<TemplateInfo> {
  final ElementInfo childInfo;
  final CodePrinter childrenCreated = new CodePrinter();
  final CodePrinter childrenRemoved = new CodePrinter();
  final CodePrinter childrenInserted = new CodePrinter();

  ConditionalEmitter(TemplateInfo info)
      : childInfo = info.childInfo, super(info);

  Element get childNode => childInfo.node;
  String get id => childInfo.identifier;
  String get parentId => elemInfo.identifier;

  void emitDeclarations(Context context) {
    context.declarations.add('''
        // Fields for template conditional '${elemInfo.ifCondition}'
        autogenerated.WatcherDisposer _stopWatcher_if$id;
    ''');
  }

  void emitInserted(Context context) {
    var cond = elemInfo.ifCondition;
    context.insertedMethod.add('''
        _stopWatcher_if$id = autogenerated.watchAndInvoke(() => $cond, (e) {
              bool showNow = e.newValue;
              if ($id != null && !showNow) {
                // Remove the actual child
                $id.remove();
                // Remove any listeners/watchers on children''')
        .add(childrenRemoved)
        .add('} else if ($id == null && showNow) {')
        .add('// Initialize children')
        .add(childrenCreated)
        .add('$parentId.parent.insertBefore($id, $parentId.nextNode);')
        .add('// Attach listeners/watchers')
        .add(childrenInserted)
        .add('''\n}\n});\n''');
  }

  void emitRemoved(Context context) {
    context.removedMethod.add('''
        _stopWatcher_if$id();
        if ($id != null) {
          $id.remove();
          // Remove any listeners/watchers on children
    ''');
    context.removedMethod.add(childrenRemoved);
    context.removedMethod.add('}');
  }

  Context contextForChildren(Context c) => new Context(
      c.declarations, childrenCreated, childrenInserted, childrenRemoved);
}


/**
 * Emitter of template lists like `<template iterate='item in items'>` or
 * `<td template iterate='item in items'>`.
 *
 * For a template element, we leave the (childless) template element in the
 * tree, and use it as a reference point for child insertion. This matches
 * native MDV behavior.
 *
 * For a template attribute, we insert children directly.
 */
class ListEmitter extends Emitter<TemplateInfo> {
  final ElementInfo childInfo;
  final CodePrinter childrenDeclarations = new CodePrinter();
  final CodePrinter childrenCreated = new CodePrinter();
  final CodePrinter childrenRemoved = new CodePrinter();
  final CodePrinter childrenInserted = new CodePrinter();

  ListEmitter(TemplateInfo info) : childInfo = info.childInfo, super(info);

  Element get childNode => childInfo.node;
  String get iterExpr => '${elemInfo.loopVariable} in ${elemInfo.loopItems}';

  void emitDeclarations(Context context) {
    var id = childInfo.identifier;
    context.declarations.add('''
        // Fields for template list '$iterExpr'
        autogenerated.WatcherDisposer _stopWatcher$id;
        List<autogenerated.WatcherDisposer> _removeChild$id = [];''');
  }

  void emitInserted(Context context) {
    var id = childInfo.identifier;
    var items = elemInfo.loopItems;
    context.insertedMethod.add('''
        _stopWatcher$id = autogenerated.watchAndInvoke(() => $items, (e) {
          for (var remover in _removeChild$id) remover();
          _removeChild$id.clear();''');

    if (elemInfo.isTemplateElement) {
      context.insertedMethod.add(
          'var _insert$id = ${elemInfo.identifier}.nextNode;');
    }

    context.insertedMethod.add('for (var $iterExpr) {')
        .add(childrenDeclarations)
        .add(childrenCreated);

    if (elemInfo.isTemplateElement) {
      context.insertedMethod.add(
          '${elemInfo.identifier}.parent.insertBefore($id, _insert$id);');
    } else {
      context.insertedMethod.add('${elemInfo.identifier}.nodes.add($id);');
    }

    context.insertedMethod
        .add('// Attach listeners/watchers')
        .add(childrenInserted)
        .add('// Remember to unregister them')
        .add('_removeChild$id.add(() {');

    context.insertedMethod.add('$id.remove();');
    context.insertedMethod.add(childrenRemoved).add('});\n}\n});');
  }

  void emitRemoved(Context context) {
    var id = childInfo.identifier;
    context.removedMethod.add('''
        _stopWatcher$id();
        for (var remover in _removeChild$id) remover();
        _removeChild$id.clear();''');
  }

  Context contextForChildren(Context c) {
    return new Context(childrenDeclarations, childrenCreated, childrenInserted,
          childrenRemoved);
  }
}


/**
 * An visitor that applies [ElementFieldEmitter], [EventListenerEmitter],
 * [DataBindingEmitter], [DataValueEmitter], [ConditionalEmitter], and
 * [ListEmitter] recursively on a DOM tree.
 */
class RecursiveEmitter extends InfoVisitor {
  final FileInfo _fileInfo;
  Context _context;

  RecursiveEmitter(this._fileInfo, [Context context])
      : _context = context != null ? context : new Context();

  // TODO(jmesserly): currently visiting of components declared in a file is
  // handled separately. Consider refactoring so the base visitor works for us.
  visitFileInfo(FileInfo info) => visit(info.bodyInfo);

  void visitElementInfo(ElementInfo info) {
    assert(info != null);
    if (info.node is Text) {
      return;
    }

    // TODO(jmesserly): I don't like the special case for body. Can we fix how
    // we initialize the main page?
    bool shouldEmit = info.identifier != null && info.node.tagName != 'body';

    if (!shouldEmit) {
      super.visitElementInfo(info);
      return;
    }

    var emitters = [new ElementFieldEmitter(info),
        new EventListenerEmitter(info),
        new DataBindingEmitter(info),
        new ComponentInstanceEmitter(info)];

    var childContext = _context;
    if (info.hasIfCondition) {
      var condEmitter = new ConditionalEmitter(info);
      emitters.add(condEmitter);
      childContext = condEmitter.contextForChildren(_context);
    } else if (info.hasIterate) {
      var listEmitter = new ListEmitter(info);
      emitters.add(listEmitter);
      childContext = listEmitter.contextForChildren(_context);
    }

    for (var e in emitters) {
      e.emitDeclarations(_context);
      e.emitCreated(_context);
      e.emitInserted(_context);
    }

    // Remove emitters run in reverse order.
    for (var e in reversed(emitters)) {
      e.emitRemoved(_context);
    }

    var oldContext = _context;
    _context = childContext;

    // Invoke super to visit children.
    super.visitElementInfo(info);

    _context = oldContext;
  }
}

/** Generates the class corresponding to a single web component. */
class WebComponentEmitter extends RecursiveEmitter {
  WebComponentEmitter(FileInfo info) : super(info);

  String run(ComponentInfo info, PathInfo pathInfo) {
    // If this derives from another component, ensure the lifecycle methods are
    // called in the superclass.
    if (info.extendsComponent != null) {
      _context.createdMethod.add('super.created_autogenerated();');
      _context.insertedMethod.add('super.inserted_autogenerated();');
      _context.removedMethod.add('super.removed_autogenerated();');
    }

    var elemInfo = info.elemInfo;

    // elemInfo is pointing at template tag (no attributes).
    assert(elemInfo.node.tagName == 'element');
    for (var childInfo in elemInfo.children) {
      var node = childInfo.node;
      if (node.tagName == 'template') {
        elemInfo = childInfo;
        break;
      }
    }

    if (info.element.attributes['apply-author-styles'] != null) {
      _context.createdMethod.add('if (_root is autogenerated.ShadowRoot) '
          '_root.applyAuthorStyles = true;');
      // TODO(jmesserly): warn at runtime if apply-author-styles was not set,
      // and we don't have Shadow DOM support? In that case, styles won't have
      // proper encapsulation.
    }
    if (info.template != null) {
      // TODO(jmesserly): we don't need to emit the HTML file for components
      // anymore, because we're handling it here.

      // TODO(jmesserly): we need to emit code to run the <content> distribution
      // algorithm for browsers without ShadowRoot support.
      _context.createdMethod.add("_root.innerHTML = '''")
          .addRaw(escapeDartString(elemInfo.node.innerHTML, triple: true))
          .addRaw("''';\n");
    }

    visit(elemInfo);

    bool hasExtends = info.extendsComponent != null;
    var codeInfo = info.userCode;
    if (codeInfo == null) {
      var superclass = hasExtends ? info.extendsComponent.constructor
          : 'autogenerated.WebComponent';
      var imports = hasExtends ? [] : [new DartDirectiveInfo('import',
          'package:web_components/web_component.dart', 'autogenerated')];
      codeInfo = new DartCodeInfo(null, null, imports,
          'class ${info.constructor} extends $superclass {\n}');
    }

    var code = codeInfo.code;
    var match = new RegExp('class ${info.constructor}[^{]*{').firstMatch(code);
    if (match != null) {
      var printer = new CodePrinter();
      var libraryName = (codeInfo.libraryName != null)
          ? codeInfo.libraryName
          : info.tagName.replaceAll(const RegExp('[-./]'), '_');
      printer.add(codegen.header(info.declaringFile.path, libraryName));

      // Add exisitng import, export, and part directives.
      for (var directive in codeInfo.directives) {
        printer.add(codegen.directiveText(directive, info, pathInfo));
      }

      // Add imports only for those components used by this component.
      var imports = info.usedComponents.keys.map(
          (c) => PathInfo.relativePath(info, c));

      if (hasExtends) {
        // Inject an import to the base component.
        printer.add(codegen.importList(
            [PathInfo.relativePath(info, info.extendsComponent)]));
      }

      printer.add(codegen.importList(imports))
          .add(code.substring(0, match.end))
          .add('\n')
          .add(codegen.componentCode(info.constructor,
              _context.declarations.formatString(1),
              _context.createdMethod.formatString(2),
              _context.insertedMethod.formatString(2),
              _context.removedMethod.formatString(2)))
          .add(code.substring(match.end));
      return printer.formatString();
    } else {
      messages.error('please provide a class definition '
          'for ${info.constructor}:\n $code', info.element.span,
          file: info.inputPath);
      return '';
    }
  }
}

/** Generates the class corresponding to the main html page. */
class MainPageEmitter extends RecursiveEmitter {
  MainPageEmitter(FileInfo fileInfo) : super(fileInfo);

  String run(Document document, PathInfo pathInfo) {
    visit(_fileInfo.bodyInfo);

    // fix up the URLs to content that is not modified by the compiler
    document.queryAll('script').forEach((tag) {
    var src = tag.attributes["src"];
     if (tag.attributes['type'] == 'application/dart') {
       tag.remove();
     } else if (src != null) {
       tag.attributes["src"] = pathInfo.transformUrl(_fileInfo, src);
     }
    });
    document.queryAll('link').forEach((tag) {
     var href = tag.attributes['href'];
       if (tag.attributes['rel'] == 'components') {
         tag.remove();
       } else if (href != null) {
         tag.attributes['href'] = pathInfo.transformUrl(_fileInfo, href);
       }
     });

    var printer = new CodePrinter();

    // Inject library name if not pressent.
    var codeInfo = _fileInfo.userCode;
    var libraryName = codeInfo.libraryName != null
        ? codeInfo.libraryName : _fileInfo.libraryName;
    printer.add(codegen.header(_fileInfo.path, libraryName));

    // Add exisitng import, export, and part directives.
    for (var directive in codeInfo.directives) {
      printer.add(codegen.directiveText(directive, _fileInfo, pathInfo));
    }

    // TODO(jmesserly): our method of appending the body is causing it to
    // lose any attributes that were set.
    var body = _fileInfo.bodyInfo.node.query('body');

    // Import only those components used by the page.
    var imports = _fileInfo.usedComponents.keys.map(
          (c) => PathInfo.relativePath(_fileInfo, c));
    printer.add(codegen.importList(imports))
        .addRaw(codegen.mainDartCode(codeInfo.code,
            _context.declarations.formatString(0),
            _context.createdMethod.formatString(1),
            _context.insertedMethod.formatString(1),
            body.innerHTML));
    return printer.formatString();
  }
}


void _emitHtmlElement(CodePrinter method, ElementInfo info) {
  // http://dev.w3.org/html5/spec/namespaces.html#namespaces
  const htmlNamespace = 'http://www.w3.org/1999/xhtml';

  var node = info.node;

  // Generate precise types like "new ButtonElement()" if we can.
  if (node.attributes.length == 0 && node.nodes.length == 0 &&
      node.namespace == htmlNamespace) {

    var elementName = htmlElementNames[node.tagName];
    if (elementName != null) {
      method.add("${info.identifier} = new autogenerated.$elementName();");
      return;
    }
  }

  method.add("${info.identifier} = new autogenerated.Element.html('''")
      .addRaw(escapeDartString(node.outerHTML, triple: true))
      .add("''');");
}
