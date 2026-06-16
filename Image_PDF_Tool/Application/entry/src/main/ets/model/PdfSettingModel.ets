export type PdfPageSize = 'A4' | 'ORIGINAL';
export type PdfFitMode = 'FIT' | 'FILL' | 'CENTER';
export type PdfOrientation = 'AUTO' | 'PORTRAIT' | 'LANDSCAPE';
export type PdfMargin = 'NONE' | 'SMALL' | 'NORMAL';
export type PdfQuality = 'HIGH' | 'STANDARD' | 'LOW';

export interface PdfSettingModel {
  fileName: string;
  pageSize: PdfPageSize;
  fitMode: PdfFitMode;
  orientation: PdfOrientation;
  margin: PdfMargin;
  quality: PdfQuality;
  oneImageOnePage: boolean;
}

export function clonePdfSetting(setting: PdfSettingModel): PdfSettingModel {
  return {
    fileName: setting.fileName,
    pageSize: setting.pageSize,
    fitMode: setting.fitMode,
    orientation: setting.orientation,
    margin: setting.margin,
    quality: setting.quality,
    oneImageOnePage: setting.oneImageOnePage
  };
}
