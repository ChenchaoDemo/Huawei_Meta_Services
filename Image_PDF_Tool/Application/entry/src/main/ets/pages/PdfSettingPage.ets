import { AppHeader } from '../components/AppHeader';
import { PrimaryButton } from '../components/PrimaryButton';
import { SettingItem } from '../components/SettingItem';
import { PdfSettingModel, PdfFitMode, PdfMargin, PdfOrientation, PdfPageSize, PdfQuality } from '../model/PdfSettingModel';
import { ConvertSessionService } from '../service/ConvertSessionService';
import { DateUtil } from '../utils/DateUtil';
import { ToastUtil } from '../utils/ToastUtil';

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

  private pageSizeValues: PdfPageSize[] = ['A4', 'ORIGINAL'];
  private fitModeValues: PdfFitMode[] = ['FIT', 'FILL', 'CENTER'];
  private orientationValues: PdfOrientation[] = ['AUTO', 'PORTRAIT', 'LANDSCAPE'];
  private marginValues: PdfMargin[] = ['NONE', 'SMALL', 'NORMAL'];
  private qualityValues: PdfQuality[] = ['HIGH', 'STANDARD', 'LOW'];

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

  private generate(): void {
    if (this.fileName.trim().length === 0) {
      ToastUtil.show('PDF 文件名不能为空');
      return;
    }
    ConvertSessionService.setSetting(this.buildSetting());
    this.pathStack.pushPathByName('GeneratePage', null);
  }

  @Builder
  optionGroup(title: string, description: string, labels: string[], selectedIndex: number, onChange: (index: number) => void) {
    Column({ space: 10 }) {
      SettingItem({ title: title, description: description })
      Row({ space: 8 }) {
        ForEach(labels, (label: string, index: number) => {
          Button(label)
            .height(36)
            .layoutWeight(1)
            .fontSize(13)
            .fontColor(index === selectedIndex ? '#FFFFFF' : '#4B5563')
            .backgroundColor(index === selectedIndex ? '#2F80ED' : '#F3F4F6')
            .borderRadius(18)
            .onClick((): void => {
              onChange(index);
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

            this.optionGroup('页面尺寸', 'A4 适合打印，原图尺寸适合保留图片比例', ['A4', '原图尺寸'], this.pageSizeIndex,
              (index: number): void => {
                this.pageSizeIndex = index;
              })
            this.optionGroup('图片适配方式', '控制图片在 PDF 页面中的展示方式', ['适应页面', '填充页面', '居中'], this.fitModeIndex,
              (index: number): void => {
                this.fitModeIndex = index;
              })
            this.optionGroup('页面方向', '自动会根据图片宽高判断方向', ['自动', '竖向', '横向'], this.orientationIndex,
              (index: number): void => {
                this.orientationIndex = index;
              })
            this.optionGroup('页面边距', '标准边距适合文档归档，无边距适合图片册', ['无', '小', '标准'], this.marginIndex,
              (index: number): void => {
                this.marginIndex = index;
              })
            this.optionGroup('图片质量', '高清文件更大，压缩适合快速分享', ['高清', '标准', '压缩'], this.qualityIndex,
              (index: number): void => {
                this.qualityIndex = index;
              })

            Row() {
              Column({ space: 4 }) {
                Text('每张图片单独一页')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#1F2937')
                Text('默认开启，适合扫描件、作业、票据整理')
                  .fontSize(12)
                  .fontColor('#9CA3AF')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.oneImageOnePage })
                .selectedColor('#00B894')
                .onChange((isOn: boolean): void => {
                  this.oneImageOnePage = isOn;
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
