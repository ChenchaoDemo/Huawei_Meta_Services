export class SizeUtil {
  static formatFileSize(size: number): string {
    if (size <= 0) {
      return '未知大小';
    }
    if (size < 1024) {
      return `${size} B`;
    }
    if (size < 1024 * 1024) {
      return `${(size / 1024).toFixed(1)} KB`;
    }
    return `${(size / 1024 / 1024).toFixed(1)} MB`;
  }

  static formatImageSize(width: number, height: number): string {
    if (width <= 0 || height <= 0) {
      return '尺寸读取中';
    }
    return `${width} x ${height}`;
  }
}
