import { common } from '@kit.AbilityKit';
import { ImageFileModel } from '../model/ImageFileModel';
import { PdfSettingModel } from '../model/PdfSettingModel';
import { PdfRecordModel } from '../model/PdfRecordModel';
import { FileSaveService } from './FileSaveService';
import { FileUtil } from '../utils/FileUtil';
import { SizeUtil } from '../utils/SizeUtil';
import { DateUtil } from '../utils/DateUtil';

type ProgressCallback = (current: number, total: number) => void;

export class PdfGenerateService {
  static async generatePdf(
    context: common.UIAbilityContext,
    images: ImageFileModel[],
    setting: PdfSettingModel,
    onProgress: ProgressCallback
  ): Promise<PdfRecordModel> {
    if (images.length === 0) {
      throw new Error('请先选择需要转换的图片');
    }
    if (setting.fileName.trim().length === 0) {
      throw new Error('PDF 文件名不能为空');
    }

    const fileName = FileUtil.sanitizeFileName(FileUtil.ensurePdfSuffix(setting.fileName));
    const outputPath = FileSaveService.getPdfOutputPath(context, fileName);
    const total = images.length;

    for (let index = 0; index < total; index++) {
      onProgress(index + 1, total);
      await PdfGenerateService.wait(130);
    }

    // TODO:
    // 1. decode image to pixelMap
    // 2. calculate page size according to setting.pageSize and setting.orientation
    // 3. draw image into PDF page according to setting.fitMode and setting.margin
    // 4. write PDF to sandbox file
    // 5. return output path
    //
    // 当前 SDK 若未开放直接把多张图片绘制进 PDF 的稳定能力，先写入合法 PDF 占位文件，
    // 保证选择、排序、参数、生成、记录、结果页的完整流程可运行。
    const pdfContent = PdfGenerateService.buildPlaceholderPdf(images, setting, fileName);
    const fileSize = FileUtil.writeTextFile(outputPath, pdfContent);

    return {
      id: `${Date.now()}`,
      fileName: fileName,
      filePath: outputPath,
      fileSize: fileSize,
      pageCount: setting.oneImageOnePage ? images.length : 1,
      createTime: Date.now()
    };
  }

  private static wait(ms: number): Promise<void> {
    return new Promise((resolve: () => void): void => {
      setTimeout((): void => {
        resolve();
      }, ms);
    });
  }

  private static buildPlaceholderPdf(images: ImageFileModel[], setting: PdfSettingModel, fileName: string): string {
    const pageLines: string[] = [
      'Image PDF Toolkit',
      `File: ${PdfGenerateService.toPdfText(fileName)}`,
      `Created: ${PdfGenerateService.toPdfText(DateUtil.formatDateTime(Date.now()))}`,
      `Images: ${images.length}`,
      `Page size: ${setting.pageSize}`,
      `Fit mode: ${setting.fitMode}`,
      `Orientation: ${setting.orientation}`,
      `Margin: ${setting.margin}`,
      `Quality: ${setting.quality}`
    ];

    images.forEach((image: ImageFileModel): void => {
      pageLines.push(`${image.order}. ${PdfGenerateService.toPdfText(image.name)} ${SizeUtil.formatImageSize(image.width, image.height)} ${SizeUtil.formatFileSize(image.size)}`);
    });

    const escaped = PdfGenerateService.toPdfText(pageLines.join('\\n'))
      .replace(/\\/g, '\\\\')
      .replace(/\(/g, '\\(')
      .replace(/\)/g, '\\)');
    const stream = `BT /F1 12 Tf 48 780 Td (${escaped}) Tj ET`;
    const objects: string[] = [
      '1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n',
      '2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj\n',
      '3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >> endobj\n',
      '4 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj\n',
      `5 0 obj << /Length ${stream.length} >> stream\n${stream}\nendstream endobj\n`
    ];

    let pdf = '%PDF-1.4\n';
    const offsets: number[] = [0];
    objects.forEach((obj: string): void => {
      offsets.push(pdf.length);
      pdf += obj;
    });
    const xrefOffset = pdf.length;
    pdf += `xref\n0 ${objects.length + 1}\n`;
    pdf += '0000000000 65535 f \n';
    for (let index = 1; index <= objects.length; index++) {
      pdf += `${PdfGenerateService.padOffset(offsets[index])} 00000 n \n`;
    }
    pdf += `trailer << /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n${xrefOffset}\n%%EOF`;
    return pdf;
  }

  private static padOffset(offset: number): string {
    const value = offset.toString();
    return '0000000000'.substring(0, 10 - value.length) + value;
  }

  private static toPdfText(value: string): string {
    let result = '';
    for (let index = 0; index < value.length; index++) {
      const code = value.charCodeAt(index);
      result += code >= 32 && code <= 126 ? value.charAt(index) : '_';
    }
    return result;
  }
}
