import { ImageFileModel, cloneImageFile, refreshImageOrder } from '../model/ImageFileModel';
import { PdfSettingModel, clonePdfSetting } from '../model/PdfSettingModel';
import { PdfRecordModel, clonePdfRecord } from '../model/PdfRecordModel';
import { MAX_IMAGE_COUNT } from '../model/BusinessConstants';

export class ConvertSessionService {
  private static images: ImageFileModel[] = [];
  private static setting: PdfSettingModel | null = null;
  private static record: PdfRecordModel | null = null;

  static setImages(images: ImageFileModel[]): void {
    ConvertSessionService.images = refreshImageOrder(images.slice(0, MAX_IMAGE_COUNT));
  }

  static getImages(): ImageFileModel[] {
    return ConvertSessionService.images.map((item: ImageFileModel): ImageFileModel => cloneImageFile(item));
  }

  static appendImages(images: ImageFileModel[]): ImageFileModel[] {
    const merged = ConvertSessionService.images.concat(images);
    ConvertSessionService.images = refreshImageOrder(merged.slice(0, MAX_IMAGE_COUNT));
    return ConvertSessionService.getImages();
  }

  static clearImages(): void {
    ConvertSessionService.images = [];
  }

  static setSetting(setting: PdfSettingModel): void {
    ConvertSessionService.setting = clonePdfSetting(setting);
  }

  static getSetting(): PdfSettingModel | null {
    return ConvertSessionService.setting === null ? null : clonePdfSetting(ConvertSessionService.setting);
  }

  static setRecord(record: PdfRecordModel): void {
    ConvertSessionService.record = clonePdfRecord(record);
  }

  static getRecord(): PdfRecordModel | null {
    return ConvertSessionService.record === null ? null : clonePdfRecord(ConvertSessionService.record);
  }
}
