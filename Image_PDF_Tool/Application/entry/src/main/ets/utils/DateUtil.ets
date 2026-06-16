export class DateUtil {
  private static pad(value: number): string {
    return value < 10 ? `0${value}` : value.toString();
  }

  static pdfFileStamp(date: Date = new Date()): string {
    const year = date.getFullYear();
    const month = DateUtil.pad(date.getMonth() + 1);
    const day = DateUtil.pad(date.getDate());
    const hour = DateUtil.pad(date.getHours());
    const minute = DateUtil.pad(date.getMinutes());
    const second = DateUtil.pad(date.getSeconds());
    return `${year}${month}${day}_${hour}${minute}${second}`;
  }

  static formatDateTime(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = DateUtil.pad(date.getMonth() + 1);
    const day = DateUtil.pad(date.getDate());
    const hour = DateUtil.pad(date.getHours());
    const minute = DateUtil.pad(date.getMinutes());
    return `${year}-${month}-${day} ${hour}:${minute}`;
  }

  static defaultPdfFileName(): string {
    return `图片转PDF_${DateUtil.pdfFileStamp()}.pdf`;
  }
}
