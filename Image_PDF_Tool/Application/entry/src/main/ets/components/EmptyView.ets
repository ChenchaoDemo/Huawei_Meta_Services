@Component
export struct EmptyView {
  @Prop title: string = '暂无内容';
  @Prop description: string = '';
  @Prop icon: string = '∅';

  build() {
    Column({ space: 8 }) {
      Text(this.icon)
        .fontSize(34)
        .fontColor('#9CA3AF')
      Text(this.title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#4B5563')
      if (this.description.length > 0) {
        Text(this.description)
          .fontSize(13)
          .fontColor('#9CA3AF')
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 12, color: '#0D000000', offsetX: 0, offsetY: 4 })
  }
}
