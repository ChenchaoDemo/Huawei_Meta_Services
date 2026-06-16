import { ImageFileModel } from '../model/ImageFileModel';
import { SizeUtil } from '../utils/SizeUtil';

@Component
export struct ImageItemCard {
  @Prop image: ImageFileModel = {
    id: '',
    uri: '',
    name: '',
    width: 0,
    height: 0,
    size: 0,
    mimeType: 'image/jpeg',
    order: 1
  };
  @Prop isFirst: boolean = false;
  @Prop isLast: boolean = false;
  deleteAction: () => void = (): void => {};
  upAction: () => void = (): void => {};
  downAction: () => void = (): void => {};

  build() {
    Row({ space: 12 }) {
      Stack({ alignContent: Alignment.BottomEnd }) {
        Image(this.image.uri)
          .width(78)
          .height(92)
          .borderRadius(12)
          .objectFit(ImageFit.Cover)
          .backgroundColor('#E5E7EB')
        Text(`${this.image.order}`)
          .fontSize(12)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
          .height(22)
          .padding({ left: 6, right: 6 })
          .textAlign(TextAlign.Center)
          .backgroundColor('#2F80ED')
          .borderRadius(11)
          .margin({ right: 6, bottom: 6 })
      }

      Column({ space: 7 }) {
        Text(this.image.name)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F2937')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`${SizeUtil.formatImageSize(this.image.width, this.image.height)} · ${SizeUtil.formatFileSize(this.image.size)}`)
          .fontSize(12)
          .fontColor('#6B7280')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.image.mimeType)
          .fontSize(12)
          .fontColor('#9CA3AF')
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column({ space: 8 }) {
        Button('上移')
          .height(28)
          .fontSize(12)
          .fontColor(this.isFirst ? '#9CA3AF' : '#2F80ED')
          .backgroundColor('#F3F7FF')
          .enabled(!this.isFirst)
          .onClick((): void => {
            this.upAction();
          })
        Button('下移')
          .height(28)
          .fontSize(12)
          .fontColor(this.isLast ? '#9CA3AF' : '#2F80ED')
          .backgroundColor('#F3F7FF')
          .enabled(!this.isLast)
          .onClick((): void => {
            this.downAction();
          })
        Button('删除')
          .height(28)
          .fontSize(12)
          .fontColor('#EF4444')
          .backgroundColor('#FFF1F2')
          .onClick((): void => {
            this.deleteAction();
          })
      }
      .width(58)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 12, color: '#0D000000', offsetX: 0, offsetY: 4 })
  }
}
