import { fileIo } from '@kit.CoreFileKit';

export class FileUtil {
  static getFileName(uri: string): string {
    if (uri.length === 0) {
      return 'image';
    }
    const cleanUri = uri.split('?')[0];
    const pieces = cleanUri.split('/');
    const last = pieces.length > 0 ? pieces[pieces.length - 1] : cleanUri;
    try {
      return decodeURIComponent(last);
    } catch (_) {
      return last;
    }
  }

  static getMimeTypeByName(name: string): string {
    const lowerName = name.toLowerCase();
    if (lowerName.endsWith('.png')) {
      return 'image/png';
    }
    if (lowerName.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lowerName.endsWith('.heic') || lowerName.endsWith('.heif')) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }

  static getFileSize(path: string): number {
    try {
      return fileIo.statSync(path).size;
    } catch (_) {
      return 0;
    }
  }

  static ensurePdfSuffix(fileName: string): string {
    const trimmed = fileName.trim();
    if (trimmed.toLowerCase().endsWith('.pdf')) {
      return trimmed;
    }
    return `${trimmed}.pdf`;
  }

  static sanitizeFileName(fileName: string): string {
    const replaced = fileName.replace(/[\\/:*?"<>|]/g, '_').trim();
    return replaced.length > 0 ? replaced : '图片转PDF.pdf';
  }

  static joinPath(dir: string, fileName: string): string {
    if (dir.endsWith('/')) {
      return `${dir}${fileName}`;
    }
    return `${dir}/${fileName}`;
  }

  static writeTextFile(filePath: string, content: string): number {
    let file = fileIo.openSync(filePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
    try {
      fileIo.writeSync(file.fd, content);
    } finally {
      fileIo.closeSync(file);
    }
    return FileUtil.getFileSize(filePath);
  }

  static copyFile(src: string, dest: string): void {
    const srcFile = fileIo.openSync(src);
    const dstFile = fileIo.openSync(dest, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
    try {
      fileIo.copyFileSync(srcFile.fd, dstFile.fd);
    } finally {
      fileIo.closeSync(srcFile);
      fileIo.closeSync(dstFile);
    }
  }

  static deleteFileIfExists(path: string): void {
    if (path.length === 0 || FileUtil.getFileSize(path) <= 0) {
      return;
    }
    try {
      fileIo.unlinkSync(path);
    } catch (_) {
    }
  }
}
