
part of charted.charts;

class _ChartConfig extends ChangeNotifier implements ChartConfig {
  final Map<String,ChartAxisConfig> _measureAxisRegistry = {};
  final Map<int,ChartAxisConfig> _dimensionAxisRegistry = {};
  final SubscriptionsDisposer _disposer = new SubscriptionsDisposer();

  Iterable<ChartSeries> _series;
  Iterable<int> _dimensions;
  StreamSubscription _dimensionsSubscription;

  @override
  Rect minimumSize = const Rect.size(400, 300);

  @override
  bool leftAxisIsPrimary = false;

  @override
  bool autoResizeAxis = true;

  @override
  ChartLegend legend;

  @override
  List<String> displayedMeasureAxes;

  @override
  bool renderDimensionAxes = true;

  _ChartConfig(Iterable<ChartSeries> series, Iterable<int> dimensions) {
    this.series = series;
    this.dimensions = dimensions;
  }

  @override
  set series(Iterable<ChartSeries> values) {
    assert(values != null && values.isNotEmpty);

    _disposer.dispose();
    _series = values;
    notifyChange(const ChartConfigChangeRecord());

    // Monitor each series for changes on them
    values.forEach((item) => _disposer.add(item.changes.listen(
        (_) => notifyChange(const ChartConfigChangeRecord())), item));

    // Monitor series for changes.  When the list changes, update
    // subscriptions to ChartSeries changes.
    if (_series is ObservableList) {
      var observable = _series as ObservableList;
      _disposer.add(observable.listChanges.listen((records) {
        records.forEach((record) {
          record.removed.forEach((value) => _disposer.unsubscribe(value));
          for (int i = 0; i < record.addedCount; i++) {
            var added = observable[i + record.index];
            _disposer.add(added.changes.listen(
                (_) => notifyChange(const ChartConfigChangeRecord())));
          }
        });
        notifyChange(const ChartConfigChangeRecord());
      }));
    }
  }

  @override
  Iterable<ChartSeries> get series => _series;

  @override
  set dimensions(Iterable<int> values) {
    _dimensions = values;

    if (_dimensionsSubscription != null) {
      _dimensionsSubscription.cancel();
      _dimensionsSubscription = null;
    }

    if (values == null || values.isEmpty) return;

    if (_dimensions is ObservableList) {
      _dimensionsSubscription =
          (_dimensions as ObservableList).listChanges.listen(
              (_) => notifyChange(const ChartConfigChangeRecord()));
    }
  }

  @override
  Iterable<int> get dimensions => _dimensions;

  @override
  void registerMeasureAxis(String id, ChartAxisConfig config) {
    assert(config != null);
    _measureAxisRegistry[id] = config;
  }

  @override
  ChartAxisConfig getMeasureAxis(String id) => _measureAxisRegistry[id];

  @override
  void registerDimensionAxis(int column, ChartAxisConfig config) {
    assert(config != null);
    assert(dimensions.contains(column));
    _dimensionAxisRegistry[column] = config;
  }

  @override
  ChartAxisConfig getDimensionAxis(int column) => _dimensionAxisRegistry[column];
}
