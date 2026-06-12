import 'dart:math';

class FileSizeFormatter {
  static String format(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB"];
    var i = (log(bytes) / log(1024)).floor();
    var num = bytes / pow(1024, i);
    
    // Round to 2 decimal places
    String formattedNum = num.toStringAsFixed(i == 0 ? 0 : 2);
    
    // Remove trailing .00 if present
    if (formattedNum.endsWith('.00')) {
      formattedNum = formattedNum.substring(0, formattedNum.length - 3);
    }
    
    return "$formattedNum ${suffixes[i]}";
  }

  static String formatSpeed(double bytesPerSecond) {
    return "${format(bytesPerSecond.toInt())}/s";
  }

  static String formatEta(double secondsRemaining) {
    if (secondsRemaining.isInfinite || secondsRemaining.isNaN) return "Calculating...";
    if (secondsRemaining < 60) {
      return "${secondsRemaining.toInt()}s remaining";
    }
    final minutes = secondsRemaining ~/ 60;
    final seconds = (secondsRemaining % 60).toInt();
    return "${minutes}m ${seconds}s remaining";
  }
}
