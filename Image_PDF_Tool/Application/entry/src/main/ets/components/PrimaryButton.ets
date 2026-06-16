@Component
export struct PrimaryButton {
  @Prop text: string = '确定';
  @Prop isEnabled: boolean = true;
  @Prop loading: boolean = false;
  @Prop btnBackgroundColor: string = '#2F80ED';
  @Prop textColor: string = '#FFFFFF';
  action: () => void = (): void => {};

  build() {
    Button({ type: ButtonType.Capsule }) {
      Row({ space: 8 }) {
        if (this.loading) {
          LoadingProgress()
            .width(18)
            .height(18)
            .color('#FFFFFF')
        }
        Text(this.text)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textColor)
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
    }
    .height(48)
    .width('100%')
    .borderRadius(24)
    .backgroundColor(this.isEnabled ? this.btnBackgroundColor : '#CBD5E1')
    .enabled(this.isEnabled && !this.loading)
    .onClick((): void => {
      this.action();
    })
  }
}
