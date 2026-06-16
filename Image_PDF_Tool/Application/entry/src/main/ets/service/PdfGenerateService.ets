import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { ImageFileModel } from '../model/ImageFileModel';
import { MAX_IMAGE_COUNT, MAX_MERGED_PAGE_IMAGE_COUNT } from '../model/BusinessConstants';
import { PdfSettingModel } from '../model/PdfSettingModel';
import { PdfRecordModel } from '../model/PdfRecordModel';
import { FileSaveService } from './FileSaveService';
import { FileUtil } from '../utils/FileUtil';

type ProgressCallback = (current: number, total: number) => void;

interface PdfImagePayload {
  name: string;
  width: number;
  height: number;
  hexData: string;
}

interface PdfPageBox {
  width: number;
  height: number;
}

interface PdfRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

interface PdfImageResource {
  resourceName: string;
  objectId: number;
}

interface PdfWriteState {
  offsets: number[];
  objectId: number;
  position: number;
}

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
    if (images.length > MAX_IMAGE_COUNT) {
      throw new Error(`最多只能选择 ${MAX_IMAGE_COUNT} 张图片`);
    }
    if (!setting.oneImageOnePage && images.length > MAX_MERGED_PAGE_IMAGE_COUNT) {
      throw new Error(`超过 ${MAX_MERGED_PAGE_IMAGE_COUNT} 张图片时请使用每张独立一页`);
    }
    if (setting.fileName.trim().length === 0) {
      throw new Error('PDF 文件名不能为空');
    }

    const fileName = FileUtil.sanitizeFileName(FileUtil.ensurePdfSuffix(setting.fileName));
    const outputPath = FileSaveService.getPdfOutputPath(context, fileName);
    const total = images.length;

    await PdfGenerateService.writeImagePdf(outputPath, images, setting, onProgress);
    const fileSize = FileUtil.getFileSize(outputPath);

    return {
      id: `${Date.now()}`,
      fileName: fileName,
      filePath: outputPath,
      fileSize: fileSize,
      pageCount: setting.oneImageOnePage ? images.length : 1,
      createTime: Date.now()
    };
  }

  private static async loadImageAsJpeg(imageFile: ImageFileModel, setting: PdfSettingModel): Promise<PdfImagePayload> {
    try {
      const imageFileHandle = fileIo.openSync(imageFile.uri, fileIo.OpenMode.READ_ONLY);
      try {
        const source = image.createImageSource(imageFileHandle.fd);
        const imageInfo = await source.getImageInfo();
        const packer = image.createImagePacker();
        const options: image.PackingOption = {
          format: 'image/jpeg',
          quality: PdfGenerateService.resolveJpegQuality(setting),
          bufferSize: 50 * 1024 * 1024
        };
        const buffer = await packer.packToData(source, options);
        const bytes = new Uint8Array(buffer);
        const width = imageInfo.size.width > 0 ? imageInfo.size.width : imageFile.width;
        const height = imageInfo.size.height > 0 ? imageInfo.size.height : imageFile.height;
        return {
          name: imageFile.name,
          width: width > 0 ? width : 595,
          height: height > 0 ? height : 842,
          hexData: PdfGenerateService.bytesToAsciiHex(bytes)
        };
      } finally {
        fileIo.closeSync(imageFileHandle);
      }
    } catch (_) {
      throw new Error(`图片“${imageFile.name}”写入 PDF 失败，请重新选择该图片后再试`);
    }
  }

  private static async writeImagePdf(
    outputPath: string,
    images: ImageFileModel[],
    setting: PdfSettingModel,
    onProgress: ProgressCallback
  ): Promise<void> {
    const pdfFile = fileIo.openSync(outputPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
    const state: PdfWriteState = {
      offsets: [0, 0, 0],
      objectId: 2,
      position: 0
    };
    const pageObjectIds: number[] = [];

    try {
      PdfGenerateService.writePdfChunk(pdfFile.fd, state, '%PDF-1.4\n');

      if (setting.oneImageOnePage) {
        for (let index = 0; index < images.length; index++) {
          const imagePayload = await PdfGenerateService.loadImageAsJpeg(images[index], setting);
          const pageObjectId = PdfGenerateService.writeSingleImagePage(pdfFile.fd, state, imagePayload, setting, index);
          pageObjectIds.push(pageObjectId);
          onProgress(index + 1, images.length);
        }
      } else {
        pageObjectIds.push(await PdfGenerateService.writeMergedImagePage(pdfFile.fd, state, images, setting, onProgress));
      }

      PdfGenerateService.writePdfObjectWithId(pdfFile.fd, state, 1, '<< /Type /Catalog /Pages 2 0 R >>');
      PdfGenerateService.writePdfObjectWithId(pdfFile.fd, state, 2, PdfGenerateService.buildPagesObject(pageObjectIds));
      PdfGenerateService.writePdfXref(pdfFile.fd, state);
    } finally {
      fileIo.closeSync(pdfFile);
    }
  }

  private static writeSingleImagePage(
    fd: number,
    state: PdfWriteState,
    imagePayload: PdfImagePayload,
    setting: PdfSettingModel,
    imageIndex: number
  ): number {
    const pageBox = PdfGenerateService.resolvePageBox(imagePayload, setting);
    const margin = PdfGenerateService.resolveMargin(setting);
    const contentBox: PdfRect = {
      x: margin,
      y: margin,
      width: Math.max(pageBox.width - margin * 2, 1),
      height: Math.max(pageBox.height - margin * 2, 1)
    };
    const imageObjectId = PdfGenerateService.writePdfObject(fd, state, PdfGenerateService.buildImageObject(imagePayload));
    const resourceName = `Im${imageIndex}`;
    const drawRect = PdfGenerateService.fitImageRect(imagePayload, contentBox, setting);
    const drawCommand = PdfGenerateService.buildDrawCommand(resourceName, drawRect, setting.fitMode === 'FILL' ? contentBox : undefined);
    const contentObjectId = PdfGenerateService.writePdfObject(fd, state, PdfGenerateService.buildStreamObject(drawCommand));
    return PdfGenerateService.writePdfObject(fd, state, PdfGenerateService.buildPageObject(pageBox, [{
      resourceName: resourceName,
      objectId: imageObjectId
    }], contentObjectId));
  }

  private static async writeMergedImagePage(
    fd: number,
    state: PdfWriteState,
    images: ImageFileModel[],
    setting: PdfSettingModel,
    onProgress: ProgressCallback
  ): Promise<number> {
    let pageBox: PdfPageBox | null = null;
    const margin = PdfGenerateService.resolveMargin(setting);
    const gap = images.length > 1 ? 12 : 0;
    const resources: PdfImageResource[] = [];
    const commands: string[] = [];

    for (let index = 0; index < images.length; index++) {
      const item = await PdfGenerateService.loadImageAsJpeg(images[index], setting);
      if (pageBox === null) {
        pageBox = PdfGenerateService.resolveMergedPageBox([item], setting);
      }
      const contentWidth = Math.max(pageBox.width - margin * 2, 1);
      const contentHeight = Math.max(pageBox.height - margin * 2 - gap * (images.length - 1), 1);
      const slotHeight = Math.max(contentHeight / images.length, 1);
      const resourceName = `Im${index}`;
      const imageObjectId = PdfGenerateService.writePdfObject(fd, state, PdfGenerateService.buildImageObject(item));
      const slotTop = pageBox.height - margin - index * (slotHeight + gap);
      const slotBox: PdfRect = {
        x: margin,
        y: slotTop - slotHeight,
        width: contentWidth,
        height: slotHeight
      };
      const drawRect = PdfGenerateService.fitImageRect(item, slotBox, setting);
      resources.push({
        resourceName: resourceName,
        objectId: imageObjectId
      });
      commands.push(PdfGenerateService.buildDrawCommand(resourceName, drawRect, setting.fitMode === 'FILL' ? slotBox : undefined));
      onProgress(index + 1, images.length);
    }

    const contentObjectId = PdfGenerateService.writePdfObject(fd, state, PdfGenerateService.buildStreamObject(commands.join('\n')));
    return PdfGenerateService.writePdfObject(fd, state, PdfGenerateService.buildPageObject(pageBox as PdfPageBox, resources, contentObjectId));
  }

  private static resolveJpegQuality(setting: PdfSettingModel): number {
    if (setting.quality === 'HIGH') {
      return 92;
    }
    if (setting.quality === 'LOW') {
      return 65;
    }
    return 82;
  }

  private static resolveMargin(setting: PdfSettingModel): number {
    if (setting.margin === 'NONE') {
      return 0;
    }
    if (setting.margin === 'SMALL') {
      return 24;
    }
    return 48;
  }

  private static resolvePageBox(imagePayload: PdfImagePayload, setting: PdfSettingModel): PdfPageBox {
    let width = 595;
    let height = 842;
    if (setting.pageSize === 'ORIGINAL') {
      width = imagePayload.width;
      height = imagePayload.height;
      const maxSide = Math.max(width, height);
      if (maxSide > 1440) {
        const scale = 1440 / maxSide;
        width = width * scale;
        height = height * scale;
      }
    } else if (setting.orientation === 'AUTO' && imagePayload.width > imagePayload.height) {
      width = 842;
      height = 595;
    }
    return PdfGenerateService.applyOrientation({
      width: width,
      height: height
    }, setting);
  }

  private static resolveMergedPageBox(images: PdfImagePayload[], setting: PdfSettingModel): PdfPageBox {
    const firstImage = images[0];
    if (setting.pageSize === 'ORIGINAL') {
      return PdfGenerateService.resolvePageBox(firstImage, setting);
    }
    let box: PdfPageBox = {
      width: 595,
      height: 842
    };
    if (setting.orientation === 'AUTO') {
      return box;
    }
    return PdfGenerateService.applyOrientation(box, setting);
  }

  private static applyOrientation(box: PdfPageBox, setting: PdfSettingModel): PdfPageBox {
    if (setting.orientation === 'LANDSCAPE' && box.height > box.width) {
      return {
        width: box.height,
        height: box.width
      };
    }
    if (setting.orientation === 'PORTRAIT' && box.width > box.height) {
      return {
        width: box.height,
        height: box.width
      };
    }
    return box;
  }

  private static fitImageRect(imagePayload: PdfImagePayload, box: PdfRect, setting: PdfSettingModel): PdfRect {
    const widthScale = box.width / imagePayload.width;
    const heightScale = box.height / imagePayload.height;
    let scale = Math.min(widthScale, heightScale);
    if (setting.fitMode === 'FILL') {
      scale = Math.max(widthScale, heightScale);
    } else if (setting.fitMode === 'CENTER') {
      scale = Math.min(1, scale);
    }
    const drawWidth = imagePayload.width * scale;
    const drawHeight = imagePayload.height * scale;
    return {
      x: box.x + (box.width - drawWidth) / 2,
      y: box.y + (box.height - drawHeight) / 2,
      width: drawWidth,
      height: drawHeight
    };
  }

  private static buildImageObject(imagePayload: PdfImagePayload): string {
    return [
      '<<',
      '/Type /XObject',
      '/Subtype /Image',
      `/Width ${Math.round(imagePayload.width)}`,
      `/Height ${Math.round(imagePayload.height)}`,
      '/ColorSpace /DeviceRGB',
      '/BitsPerComponent 8',
      '/Interpolate true',
      '/Filter [/ASCIIHexDecode /DCTDecode]',
      `/Length ${imagePayload.hexData.length}`,
      '>>',
      'stream',
      imagePayload.hexData,
      'endstream'
    ].join('\n');
  }

  private static buildStreamObject(stream: string): string {
    return [
      `<< /Length ${stream.length} >>`,
      'stream',
      stream,
      'endstream'
    ].join('\n');
  }

  private static buildPageObject(pageBox: PdfPageBox, resources: PdfImageResource[], contentObjectId: number): string {
    const xObjects = resources.map((item: PdfImageResource): string => {
      return `/${item.resourceName} ${item.objectId} 0 R`;
    }).join(' ');
    return `<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ${PdfGenerateService.formatNumber(pageBox.width)} ${PdfGenerateService.formatNumber(pageBox.height)}] /Resources << /XObject << ${xObjects} >> >> /Contents ${contentObjectId} 0 R >>`;
  }

  private static buildPagesObject(pageObjectIds: number[]): string {
    const kids = pageObjectIds.map((objectId: number): string => {
      return `${objectId} 0 R`;
    }).join(' ');
    return `<< /Type /Pages /Kids [${kids}] /Count ${pageObjectIds.length} >>`;
  }

  private static buildDrawCommand(resourceName: string, drawRect: PdfRect, clipRect?: PdfRect): string {
    const commands: string[] = ['q'];
    if (clipRect) {
      commands.push(`${PdfGenerateService.formatNumber(clipRect.x)} ${PdfGenerateService.formatNumber(clipRect.y)} ${PdfGenerateService.formatNumber(clipRect.width)} ${PdfGenerateService.formatNumber(clipRect.height)} re W n`);
    }
    commands.push(`${PdfGenerateService.formatNumber(drawRect.width)} 0 0 ${PdfGenerateService.formatNumber(drawRect.height)} ${PdfGenerateService.formatNumber(drawRect.x)} ${PdfGenerateService.formatNumber(drawRect.y)} cm`);
    commands.push(`/${resourceName} Do`);
    commands.push('Q');
    return commands.join('\n');
  }

  private static writePdfObject(fd: number, state: PdfWriteState, body: string): number {
    state.objectId++;
    state.offsets.push(state.position);
    PdfGenerateService.writePdfChunk(fd, state, `${state.objectId} 0 obj\n${body}\nendobj\n`);
    return state.objectId;
  }

  private static writePdfObjectWithId(fd: number, state: PdfWriteState, objectId: number, body: string): void {
    state.offsets[objectId] = state.position;
    PdfGenerateService.writePdfChunk(fd, state, `${objectId} 0 obj\n${body}\nendobj\n`);
  }

  private static writePdfXref(fd: number, state: PdfWriteState): void {
    const xrefOffset = state.position;
    let trailer = `xref\n0 ${state.objectId + 1}\n`;
    trailer += '0000000000 65535 f \n';
    for (let index = 1; index <= state.objectId; index++) {
      trailer += `${PdfGenerateService.padOffset(state.offsets[index])} 00000 n \n`;
    }
    trailer += `trailer << /Size ${state.objectId + 1} /Root 1 0 R >>\nstartxref\n${xrefOffset}\n%%EOF`;
    PdfGenerateService.writePdfChunk(fd, state, trailer);
  }

  private static writePdfChunk(fd: number, state: PdfWriteState, content: string): void {
    const written = fileIo.writeSync(fd, content);
    state.position += written;
  }

  private static bytesToAsciiHex(bytes: Uint8Array): string {
    const alphabet = '0123456789ABCDEF';
    let result = '';
    for (let index = 0; index < bytes.length; index++) {
      const value = bytes[index];
      result += alphabet.charAt(value >> 4);
      result += alphabet.charAt(value & 15);
    }
    return `${result}>`;
  }

  private static formatNumber(value: number): string {
    const normalized = Math.abs(value) < 0.005 ? 0 : value;
    const fixed = normalized.toFixed(2);
    if (fixed.endsWith('.00')) {
      return fixed.substring(0, fixed.length - 3);
    }
    if (fixed.endsWith('0')) {
      return fixed.substring(0, fixed.length - 1);
    }
    return fixed;
  }

  private static padOffset(offset: number): string {
    const value = offset.toString();
    return '0000000000'.substring(0, 10 - value.length) + value;
  }
}
