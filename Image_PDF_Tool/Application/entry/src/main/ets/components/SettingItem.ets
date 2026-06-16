@Component
export struct SettingItem {
  @Prop title: string = '';
  @Prop description: string = '';

  build() {
    Row() {
      Column({ space: 4 }) {
        Text(this.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F2937')
        if (this.description.length > 0) {
          Text(this.description)
            .fontSize(12)
            .fontColor('#9CA3AF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
  }
}
