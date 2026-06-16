import { PdfRecordModel } from '../model/PdfRecordModel';
import { DateUtil } from '../utils/DateUtil';
import { SizeUtil } from '../utils/SizeUtil';

@Component
export struct RecentPdfCard {
  @Prop record: PdfRecordModel = {
    id: '',
    fileName: '',
    filePath: '',
    fileSize: 0,
    pageCount: 0,
    createTime: 0
  };
  openAction: () => void = (): void => {};
  deleteAction: () => void = (): void => {};

  build() {
    Row({ space: 12 }) {
      Text('PDF')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2F80ED')
        .width(48)
        .height(48)
        .textAlign(TextAlign.Center)
        .backgroundColor('#EEF6FF')
        .borderRadius(14)

      Column({ space: 5 }) {
        Text(this.record.fileName)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F2937')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`${this.record.pageCount} 页 · ${SizeUtil.formatFileSize(this.record.fileSize)}`)
          .fontSize(12)
          .fontColor('#6B7280')
        Text(DateUtil.formatDateTime(this.record.createTime))
          .fontSize(12)
          .fontColor('#9CA3AF')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .onClick((): void => {
        this.openAction();
      })

      Button('打开')
        .height(34)
        .fontSize(13)
        .fontColor('#2F80ED')
        .backgroundColor('#EAF4FF')
        .borderRadius(17)
        .onClick((): void => {
          this.openAction();
        })

      Button('删除')
        .height(34)
        .fontSize(13)
        .fontColor('#EF4444')
        .backgroundColor('#FFF1F2')
        .borderRadius(17)
        .onClick((): void => {
          this.deleteAction();
        })
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 12, color: '#0D000000', offsetX: 0, offsetY: 4 })
  }
}
