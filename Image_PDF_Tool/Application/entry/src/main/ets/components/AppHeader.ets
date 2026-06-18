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

      Text(this.title)
        .fontSize(this.showBack ? 20 : 22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F2937')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .margin({ left: this.showBack ? 12 : 0 })
    }
    .width('100%')
    .height(64)
    .padding({ right: 112 })
    .alignItems(VerticalAlign.Center)
  }
}
