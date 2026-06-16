import { AppHeader } from '../components/AppHeader';
import { PrimaryButton } from '../components/PrimaryButton';
import { SettingItem } from '../components/SettingItem';
import { MAX_MERGED_PAGE_IMAGE_COUNT } from '../model/BusinessConstants';
import { ImageFileModel } from '../model/ImageFileModel';
import { PdfSettingModel, PdfFitMode, PdfMargin, PdfOrientation, PdfPageSize, PdfQuality } from '../model/PdfSettingModel';
import { ConvertSessionService } from '../service/ConvertSessionService';
import { DateUtil } from '../utils/DateUtil';
import { ToastUtil } from '../utils/ToastUtil';

interface PreviewBoxSize {
  width: number;
  height: number;
}

@Component
struct PdfOptionGroup {
  @Prop title: string = '';
  @Prop description: string = '';
  @Prop labels: string[] = [];
  @Link selectedIndex: number;

  build() {
    Column({ space: 10 }) {
      SettingItem({ title: this.title, description: this.description })
      Row({ space: 8 }) {
        ForEach(this.labels, (label: string, index: number) => {
          Button(label)
            .height(36)
            .layoutWeight(1)
            .fontSize(13)
            .fontColor(index === this.selectedIndex ? '#FFFFFF' : '#4B5563')
            .backgroundColor(index === this.selectedIndex ? '#2F80ED' : '#F3F4F6')
            .borderRadius(18)
            .onClick((): void => {
              this.selectedIndex = index;
            })
        }, (label: string): string => label)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 12, color: '#0D000000', offsetX: 0, offsetY: 4 })
  }
}

@Entry
@Component
export struct PdfSettingPage {
  @Consume('pathStack') pathStack: NavPathStack;
  @State fileName: string = DateUtil.defaultPdfFileName();
  @State pageSizeIndex: number = 0;
  @State fitModeIndex: number = 0;
  @State orientationIndex: number = 0;
  @State marginIndex: number = 2;
  @State qualityIndex: number = 0;
  @State oneImageOnePage: boolean = true;
  @State previewImages: ImageFileModel[] = [];

  private pageSizeValues: PdfPageSize[] = ['A4', 'ORIGINAL'];
  private fitModeValues: PdfFitMode[] = ['FIT', 'FILL', 'CENTER'];
  private orientationValues: PdfOrientation[] = ['AUTO', 'PORTRAIT', 'LANDSCAPE'];
  private marginValues: PdfMargin[] = ['NONE', 'SMALL', 'NORMAL'];
  private qualityValues: PdfQuality[] = ['HIGH', 'STANDARD', 'LOW'];

  aboutToAppear(): void {
    this.previewImages = ConvertSessionService.getImages();
    if (!this.canMergeToOnePage()) {
      this.oneImageOnePage = true;
    }
  }

  private buildSetting(): PdfSettingModel {
    return {
      fileName: this.fileName,
      pageSize: this.pageSizeValues[this.pageSizeIndex],
      fitMode: this.fitModeValues[this.fitModeIndex],
      orientation: this.orientationValues[this.orientationIndex],
      margin: this.marginValues[this.marginIndex],
      quality: this.qualityValues[this.qualityIndex],
      oneImageOnePage: this.oneImageOnePage
    };
  }

  private currentPageSizeValue(): PdfPageSize {
    return this.pageSizeValues[this.pageSizeIndex];
  }

  private currentFitModeValue(): PdfFitMode {
    return this.fitModeValues[this.fitModeIndex];
  }

  private currentOrientationValue(): PdfOrientation {
    return this.orientationValues[this.orientationIndex];
  }

  private currentMarginValue(): PdfMargin {
    return this.marginValues[this.marginIndex];
  }

  private resolvePreviewPageBox(): PreviewBoxSize {
    const firstImage = this.getPreviewImage(0);
    let width = 210;
    let height = 297;
    if (this.currentPageSizeValue() === 'ORIGINAL' && firstImage !== null && firstImage.width > 0 && firstImage.height > 0) {
      width = firstImage.width;
      height = firstImage.height;
      const maxSide = Math.max(width, height);
      if (maxSide > 320) {
        const scale = 320 / maxSide;
        width = width * scale;
        height = height * scale;
      }
    } else if (this.currentOrientationValue() === 'AUTO' && firstImage !== null && firstImage.width > firstImage.height) {
      width = 297;
      height = 210;
    }
    return this.applyPreviewOrientation({
      width: width,
      height: height
    });
  }

  private applyPreviewOrientation(box: PreviewBoxSize): PreviewBoxSize {
    const orientation = this.currentOrientationValue();
    if (orientation === 'LANDSCAPE' && box.height > box.width) {
      return {
        width: box.height,
        height: box.width
      };
    }
    if (orientation === 'PORTRAIT' && box.width > box.height) {
      return {
        width: box.height,
        height: box.width
      };
    }
    return box;
  }

  private resolvePreviewPaperWidth(): number {
    const pageBox = this.resolvePreviewPageBox();
    const ratio = pageBox.width / pageBox.height;
    if (ratio > 1) {
      return 260;
    }
    return 190;
  }

  private resolvePreviewPaperHeight(): number {
    const pageBox = this.resolvePreviewPageBox();
    const paperWidth = this.resolvePreviewPaperWidth();
    return Math.max(150, Math.min(280, paperWidth * pageBox.height / pageBox.width));
  }

  private resolvePreviewPadding(): number {
    const margin = this.currentMarginValue();
    if (margin === 'NONE') {
      return 0;
    }
    if (margin === 'SMALL') {
      return 10;
    }
    return 20;
  }

  private resolvePreviewImageFit(): ImageFit {
    const fitMode = this.currentFitModeValue();
    if (fitMode === 'FILL') {
      return ImageFit.Cover;
    }
    if (fitMode === 'CENTER') {
      return ImageFit.None;
    }
    return ImageFit.Contain;
  }

  private getPreviewPageCount(): number {
    if (this.previewImages.length === 0) {
      return 0;
    }
    return this.oneImageOnePage ? this.previewImages.length : 1;
  }

  private getPreviewImage(index: number): ImageFileModel | null {
    if (this.previewImages.length === 0 || index >= this.previewImages.length) {
      return null;
    }
    return this.previewImages[index];
  }

  private getPreviewPageLabel(): string {
    const pageCount = this.getPreviewPageCount();
    if (pageCount === 0) {
      return '0 页';
    }
    if (this.oneImageOnePage) {
      return `预览第 1 / ${pageCount} 页`;
    }
    return `${this.previewImages.length} 张合并为 1 页`;
  }

  private canMergeToOnePage(): boolean {
    return this.previewImages.length <= MAX_MERGED_PAGE_IMAGE_COUNT;
  }

  private updateOneImageOnePage(isOn: boolean): void {
    if (!isOn && !this.canMergeToOnePage()) {
      this.oneImageOnePage = true;
      ToastUtil.show(`超过 ${MAX_MERGED_PAGE_IMAGE_COUNT} 张图片时建议每张独立一页`);
      return;
    }
    this.oneImageOnePage = isOn;
  }

  private getPageSizeLabel(): string {
    return this.currentPageSizeValue() === 'A4' ? 'A4' : '原图';
  }

  private getOrientationLabel(): string {
    const orientation = this.currentOrientationValue();
    if (orientation === 'PORTRAIT') {
      return '竖向';
    }
    if (orientation === 'LANDSCAPE') {
      return '横向';
    }
    return '自动';
  }

  @Builder
  previewImageSlot(imageFile: ImageFileModel | null, slotHeight: number, compact: boolean = false) {
    Stack() {
      if (imageFile !== null) {
        Image(imageFile.uri)
          .width('100%')
          .height('100%')
          .objectFit(this.resolvePreviewImageFit())
          .borderRadius(compact ? 4 : 8)
      } else {
        Column() {}
          .width('100%')
          .height('100%')
          .backgroundColor('#EEF2F7')
          .borderRadius(compact ? 4 : 8)
      }
    }
    .width('100%')
    .height(slotHeight)
    .backgroundColor('#F8FAFC')
    .borderRadius(compact ? 4 : 8)
    .clip(true)
  }

  @Builder
  previewPaper() {
    Column() {
      if (this.previewImages.length === 0) {
        Column({ space: 6 }) {
          Text('暂无图片')
            .fontSize(14)
            .fontColor('#9CA3AF')
          Text('返回上一步添加后可预览')
            .fontSize(11)
            .fontColor('#CBD5E1')
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height('100%')
      } else if (this.oneImageOnePage) {
        this.previewImageSlot(this.getPreviewImage(0), Math.max(this.resolvePreviewPaperHeight() - this.resolvePreviewPadding() * 2, 40))
      } else {
        ForEach([0, 1, 2], (index: number) => {
          if (index < Math.min(this.previewImages.length, 3)) {
            this.previewImageSlot(this.getPreviewImage(index), Math.max((this.resolvePreviewPaperHeight() - this.resolvePreviewPadding() * 2 - 12) / Math.min(this.previewImages.length, 3), 32), true)
          }
        }, (index: number): string => `${index}`)
      }
    }
    .justifyContent(FlexAlign.Center)
    .width(this.resolvePreviewPaperWidth())
    .height(this.resolvePreviewPaperHeight())
    .padding(this.resolvePreviewPadding())
    .backgroundColor('#FFFFFF')
    .borderRadius(6)
    .shadow({ radius: 18, color: '#18000000', offsetX: 0, offsetY: 6 })
  }

  @Builder
  previewMeta(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(12)
        .fontColor('#9CA3AF')
      Text(value)
        .fontSize(12)
        .fontColor('#1F2937')
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }

  @Builder
  previewCard() {
    Column({ space: 14 }) {
      Row() {
        Column({ space: 4 }) {
          Text('效果预览')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F2937')
          Text('根据当前参数模拟生成后的页面版式')
            .fontSize(12)
            .fontColor('#9CA3AF')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text(this.getPreviewPageLabel())
          .fontSize(12)
          .fontColor('#2F80ED')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor('#EAF3FF')
          .borderRadius(12)
      }
      .width('100%')

      Column() {
        this.previewPaper()
      }
      .width('100%')
      .height(300)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#F3F6FA')
      .borderRadius(14)

      Column({ space: 8 }) {
        this.previewMeta('页面', `${this.getPageSizeLabel()} · ${this.getOrientationLabel()}`)
        this.previewMeta('边距', ['无边距', '小边距', '标准边距'][this.marginIndex])
        this.previewMeta('图片', ['适应页面', '填充页面', '居中显示'][this.fitModeIndex])
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 12, color: '#0D000000', offsetX: 0, offsetY: 4 })
  }

  private generate(): void {
    this.previewImages = ConvertSessionService.getImages();
    if (this.previewImages.length === 0) {
      ToastUtil.show('请先选择需要转换的图片');
      this.pathStack.pop();
      return;
    }
    if (this.fileName.trim().length === 0) {
      ToastUtil.show('PDF 文件名不能为空');
      return;
    }
    if (!this.oneImageOnePage && !this.canMergeToOnePage()) {
      ToastUtil.show(`超过 ${MAX_MERGED_PAGE_IMAGE_COUNT} 张图片时请使用每张独立一页`);
      this.oneImageOnePage = true;
      return;
    }
    ConvertSessionService.setSetting(this.buildSetting());
    this.pathStack.pushPathByName('GeneratePage', null);
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#F5F7FA')

        Scroll() {
          Column({ space: 12 }) {
            AppHeader({
              title: 'PDF 参数设置',
              subtitle: '设置页面尺寸、边距与图片质量',
              showBack: true,
              backAction: (): void => {
                this.pathStack.pop();
              }
            })

            Column({ space: 10 }) {
              SettingItem({
                title: 'PDF 文件名',
                description: '建议保留 .pdf 后缀，生成时会自动补全'
              })
              TextInput({ text: this.fileName, placeholder: '请输入 PDF 文件名' })
                .height(44)
                .fontSize(14)
                .fontColor('#1F2937')
                .placeholderColor('#9CA3AF')
                .backgroundColor('#F5F7FA')
                .borderRadius(12)
                .onChange((value: string): void => {
                  this.fileName = value;
                })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .shadow({ radius: 12, color: '#0D000000', offsetX: 0, offsetY: 4 })

            this.previewCard()

            PdfOptionGroup({
              title: '页面尺寸',
              description: 'A4 适合打印，原图尺寸适合保留图片比例',
              labels: ['A4', '原图尺寸'],
              selectedIndex: $pageSizeIndex
            })
            PdfOptionGroup({
              title: '图片适配方式',
              description: '控制图片在 PDF 页面中的展示方式',
              labels: ['适应页面', '填充页面', '居中'],
              selectedIndex: $fitModeIndex
            })
            PdfOptionGroup({
              title: '页面方向',
              description: '自动会根据图片宽高判断方向',
              labels: ['自动', '竖向', '横向'],
              selectedIndex: $orientationIndex
            })
            PdfOptionGroup({
              title: '页面边距',
              description: '标准边距适合文档归档，无边距适合图片册',
              labels: ['无', '小', '标准'],
              selectedIndex: $marginIndex
            })
            PdfOptionGroup({
              title: '图片质量',
              description: '高清文件更大，压缩适合快速分享',
              labels: ['高清', '标准', '压缩'],
              selectedIndex: $qualityIndex
            })

            Row() {
              Column({ space: 4 }) {
                Text('每张图片单独一页')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#1F2937')
                Text(this.canMergeToOnePage() ? '默认开启，适合扫描件、作业、票据整理' : `超过 ${MAX_MERGED_PAGE_IMAGE_COUNT} 张图片时固定为每张独立一页`)
                  .fontSize(12)
                  .fontColor('#9CA3AF')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.oneImageOnePage })
                .selectedColor('#00B894')
                .enabled(this.canMergeToOnePage())
                .onChange((isOn: boolean): void => {
                  this.updateOneImageOnePage(isOn);
                })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .shadow({ radius: 12, color: '#0D000000', offsetX: 0, offsetY: 4 })

            Column()
              .height(84)
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)

        Column() {
          PrimaryButton({
            text: '生成 PDF',
            action: (): void => {
              this.generate();
            }
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 16 })
        .backgroundColor('#F5F7FA')
      }
    }
    .hideTitleBar(true)
  }
}
