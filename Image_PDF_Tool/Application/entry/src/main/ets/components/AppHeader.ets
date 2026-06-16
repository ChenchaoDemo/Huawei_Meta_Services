@Component
export struct AppHeader {
  @Prop title: string = '图片转PDF工具箱';
  @Prop subtitle: string = '';
  @Prop showBack: boolean = false;
  backAction: () => void = (): void => {};

  build() {
    Row() {
      if (this.showBack) {
        Button({ type: ButtonType.Circle }) {
          Text('‹')
            .fontSize(30)
            .fontColor('#1F2937')
            .fontWeight(FontWeight.Bold)
        }
        .width(40)
        .height(40)
        .backgroundColor('#FFFFFF')
        .shadow({ radius: 10, color: '#14000000', offsetX: 0, offsetY: 3 })
        .onClick((): void => {
          this.backAction();
        })
      }

      Column({ space: 4 }) {
        Text(this.title)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2937')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (this.subtitle.length > 0) {
          Text(this.subtitle)
            .fontSize(14)
            .fontColor('#4B5563')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: this.showBack ? 12 : 0 })
    }
    .width('100%')
    .padding({ top: 16, bottom: 12 })
  }
}
