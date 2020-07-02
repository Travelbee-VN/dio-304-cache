class Cache304Config {
  final int cacheLength;
  final String cacheBoxName;
  final String hiveInitPath;

  Cache304Config({
    this.cacheLength,
    this.cacheBoxName,
    this.hiveInitPath = '',
  });
}
