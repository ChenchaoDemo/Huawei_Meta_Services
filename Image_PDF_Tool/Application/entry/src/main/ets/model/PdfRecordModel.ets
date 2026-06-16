export interface PdfRecordModel {
  id: string;
  fileName: string;
  filePath: string;
  fileSize: number;
  pageCount: number;
  createTime: number;
}

export function clonePdfRecord(record: PdfRecordModel): PdfRecordModel {
  return {
    id: record.id,
    fileName: record.fileName,
    filePath: record.filePath,
    fileSize: record.fileSize,
    pageCount: record.pageCount,
    createTime: record.createTime
  };
}
