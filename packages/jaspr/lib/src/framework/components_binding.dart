part of framework;

/// Main app binding, controls the root component and global state
mixin ComponentsBinding on AppBinding {
  /// Sets [app] as the new root of the component tree and performs an initial build
  Future<void> attachRootComponent(Component app) async {
    var buildOwner = _rootElement?._owner ?? BuildOwner();
    await buildOwner.lockState(() {
      assert(() {
        buildOwner._debugBuilding = true;
        return true;
      }());
      buildOwner._isFirstBuild = true;

      var renderer = createRenderer();

      var element = _Root(child: app).createElement();
      element._binding = this;
      element._owner = buildOwner;
      element._renderer = renderer;

      element.mount(null, null);

      end() {
        _rootElement = element;
        buildOwner._isFirstBuild = false;
        assert(() {
          buildOwner._debugBuilding = false;
          return true;
        }());

        didAttachRootElement(element);
      }

      if (element._asyncFirstBuild != null) {
        assert(!isClient);
        return element._asyncFirstBuild!.then((_) => end());
      }

      end();
    });
  }

  @protected
  void didAttachRootElement(Element element) {}

  /// The [Element] that is at the root of the hierarchy.
  ///
  /// This is initialized when [runApp] is called.
  @override
  RenderElement? get rootElement => _rootElement;
  RenderElement? _rootElement;

  Renderer createRenderer();

  static final Map<GlobalKey, Element> _globalKeyRegistry = {};

  static void _registerGlobalKey(GlobalKey key, Element element) {
    _globalKeyRegistry[key] = element;
  }

  static void _unregisterGlobalKey(GlobalKey key, Element element) {
    if (_globalKeyRegistry[key] == element) {
      _globalKeyRegistry.remove(key);
    }
  }
}

class _Root extends Component {
  _Root({required this.child});

  final Component child;

  @override
  _RootElement createElement() => _RootElement(this);
}

class _RootElement extends SingleChildElement with RenderElement {
  _RootElement(_Root component) : super(component);

  @override
  _Root get component => super.component as _Root;

  @override
  void _firstBuild([VoidCallback? onBuilt]) {
    _attach();
    super._firstBuild(onBuilt);
  }

  @override
  void renderNode(Renderer renderer) {}

  @override
  Component build() => component.child;
}
