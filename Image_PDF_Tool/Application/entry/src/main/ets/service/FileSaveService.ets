import { common } from '@kit.AbilityKit';
import { picker } from '@kit.CoreFileKit';
import { PdfRecordModel } from '../model/PdfRecordModel';
import { FileUtil } from '../utils/FileUtil';

export class FileSaveService {
  static getPdfOutputPath(context: common.UIAbilityContext, fileName: string): string {
    const safeFileName = FileUtil.sanitizeFileName(FileUtil.ensurePdfSuffix(fileName));
    return FileUtil.joinPath(context.filesDir, safeFileName);
  }

  static async saveCopyToSandbox(record: PdfRecordModel, context: common.UIAbilityContext): Promise<PdfRecordModel> {
    const fileName = FileUtil.sanitizeFileName(FileUtil.ensurePdfSuffix(record.fileName));
    const destPath = FileUtil.joinPath(context.filesDir, fileName);
    if (destPath !== record.filePath) {
      FileUtil.copyFile(record.filePath, destPath);
    }
    return {
      id: `${Date.now()}`,
      fileName: fileName,
      filePath: destPath,
      fileSize: FileUtil.getFileSize(destPath),
      pageCount: record.pageCount,
      createTime: Date.now()
    };
  }

  static async saveToUserSelectedPath(record: PdfRecordModel): Promise<string> {
    const fileName = FileUtil.sanitizeFileName(FileUtil.ensurePdfSuffix(record.fileName));
    const saveOptions = new picker.DocumentSaveOptions();
    saveOptions.newFileNames = [fileName];
    saveOptions.fileSuffixChoices = ['.pdf'];
    const documentPicker = new picker.DocumentViewPicker();
    const uris = await documentPicker.save(saveOptions);
    if (!uris || uris.length === 0) {
      throw new Error('未选择保存位置');
    }
    FileUtil.copyFile(record.filePath, uris[0]);
    return uris[0];
  }
}
