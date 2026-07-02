import 'dart:typed_data';

/// 环形字节缓冲
///
/// 用途：PCM 音频流持续到达，累积到目标 buffer 大小后做一次检测。
/// 避免每次都新建数组，提升性能。
///
/// 用法：
/// ```dart
/// final buf = RingByteBuffer(capacity: 4096);
/// buf.add(chunk1);
/// buf.add(chunk2);
/// final frame = buf.take(2048);  // 取 2048 字节做检测
/// ```
class RingByteBuffer {
  RingByteBuffer({required this.capacity})
      : _data = Uint8List(capacity),
        _writeIndex = 0,
        _available = 0;

  /// 缓冲区总容量
  final int capacity;

  final Uint8List _data;
  int _writeIndex;
  int _available;

  /// 当前可读取的字节数
  int get available => _available;

  /// 是否为空
  bool get isEmpty => _available == 0;

  /// 是否已满
  bool get isFull => _available == capacity;

  /// 追加字节
  void add(Uint8List chunk) {
    for (int i = 0; i < chunk.length; i++) {
      _data[_writeIndex] = chunk[i];
      _writeIndex = (_writeIndex + 1) % capacity;
      if (_available < capacity) {
        _available++;
      } else {
        // 已满时丢弃最老的字节（覆盖）
        // 注：实际场景下 buffer 应该足够大，不会真的覆盖
      }
    }
  }

  /// 取出指定数量的字节（FIFO）
  ///
  /// 如果可读字节不足，返回 null
  Uint8List? take(int count) {
    if (_available < count) return null;

    final Uint8List result = Uint8List(count);
    // 读指针 = 写指针 - available（模 capacity）
    int readIndex = (_writeIndex - _available) % capacity;
    if (readIndex < 0) readIndex += capacity;

    for (int i = 0; i < count; i++) {
      result[i] = _data[readIndex];
      readIndex = (readIndex + 1) % capacity;
    }
    _available -= count;
    return result;
  }

  /// 偷看最前面的字节但不移除
  Uint8List? peek(int count) {
    if (_available < count) return null;

    final Uint8List result = Uint8List(count);
    int readIndex = (_writeIndex - _available) % capacity;
    if (readIndex < 0) readIndex += capacity;

    for (int i = 0; i < count; i++) {
      result[i] = _data[readIndex];
      readIndex = (readIndex + 1) % capacity;
    }
    return result;
  }

  /// 清空
  void clear() {
    _writeIndex = 0;
    _available = 0;
  }
}