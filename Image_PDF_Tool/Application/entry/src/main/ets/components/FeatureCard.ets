@Component
export struct FeatureCard {
  @Prop title: string = '';
  @Prop description: string = '';
  @Prop icon: string = '✓';
  @Prop iconColor: string = '#2F80ED';

  build() {
    Row({ space: 10 }) {
      Text(this.icon)
        .fontSize(18)
        .fontColor(this.iconColor)
        .fontWeight(FontWeight.Bold)
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .backgroundColor('#EEF6FF')
        .borderRadius(20)

      Column({ space: 3 }) {
        Text(this.title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F2937')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.description)
          .fontSize(13)
          .fontColor('#6B7280')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .layoutWeight(1)
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 12, color: '#10000000', offsetX: 0, offsetY: 4 })
  }
}
