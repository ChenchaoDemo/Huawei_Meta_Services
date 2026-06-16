import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { AppHeader } from '../components/AppHeader';
import { PrimaryButton } from '../components/PrimaryButton';
import { ImageFileModel } from '../model/ImageFileModel';
import { PdfSettingModel } from '../model/PdfSettingModel';
import { PdfGenerateService } from '../service/PdfGenerateService';
import { ConvertSessionService } from '../service/ConvertSessionService';
import { RecordStorageService } from '../service/RecordStorageService';
import { ToastUtil } from '../utils/ToastUtil';

@Entry
@Component
export struct GeneratePage {
  @Consume('pathStack') pathStack: NavPathStack;
  @Consume('recordRefreshVersion') recordRefreshVersion: number;
  @State current: number = 0;
  @State total: number = 0;
  @State generating: boolean = false;
  @State hasStarted: boolean = false;
  @State errorMessage: string = '';

  aboutToAppear(): void {
    if (!this.hasStarted) {
      this.startGenerate();
    }
  }

  private async startGenerate(): Promise<void> {
    if (this.generating) {
      return;
    }
    this.hasStarted = true;
    const images: ImageFileModel[] = ConvertSessionService.getImages();
    const setting: PdfSettingModel | null = ConvertSessionService.getSetting();
    if (setting === null) {
      ToastUtil.show('请先完成 PDF 参数设置');
      this.pathStack.pop();
      return;
    }
    this.total = images.length;
    this.current = 0;
    this.errorMessage = '';
    this.generating = true;
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const record = await PdfGenerateService.generatePdf(context, images, setting, (current: number, total: number): void => {
        this.current = current;
        this.total = total;
      });
      ConvertSessionService.setRecord(record);
      await RecordStorageService.addRecord(context, record);
      this.recordRefreshVersion++;
      this.pathStack.clear();
      this.pathStack.pushPathByName('ResultPage', null);
    } catch (err) {
      this.errorMessage = (err as Error).message || '生成 PDF 失败';
      this.showErrorDialog();
    } finally {
      this.generating = false;
    }
  }

  private showErrorDialog(): void {
    promptAction.showDialog({
      title: '生成失败',
      message: this.errorMessage,
      buttons: [
        { text: '返回', color: '#6B7280' },
        { text: '重新生成', color: '#2F80ED' }
      ]
    }).then((result): void => {
      if (result.index === 1) {
        this.hasStarted = false;
        this.startGenerate();
      } else {
        this.pathStack.pop();
      }
    });
  }

  build() {
    NavDestination() {
      Column({ space: 18 }) {
        AppHeader({
          title: '生成 PDF',
          subtitle: '正在处理图片，请勿关闭页面',
          showBack: true,
          backAction: (): void => {
            if (this.generating) {
              ToastUtil.show('PDF 正在生成，请稍候');
            } else {
              this.pathStack.pop();
            }
          }
        })

        Column({ space: 18 }) {
          Stack() {
            Progress({
              value: this.total === 0 ? 0 : Math.floor(this.current / this.total * 100),
              total: 100,
              type: ProgressType.Ring
            })
              .width(132)
              .height(132)
              .color('#2F80ED')
              .backgroundColor('#E5E7EB')
            Text(`${this.total === 0 ? 0 : Math.floor(this.current / this.total * 100)}%`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1F2937')
          }

          Text('正在生成 PDF，请勿关闭页面')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1F2937')
          Text(`当前处理第 ${this.current} / ${this.total} 张图片`)
            .fontSize(14)
            .fontColor('#6B7280')

          Progress({
            value: this.total === 0 ? 0 : this.current,
            total: this.total,
            type: ProgressType.Linear
          })
            .width('100%')
            .height(8)
            .color('#00B894')
            .backgroundColor('#E5E7EB')
            .borderRadius(4)

          if (this.errorMessage.length > 0) {
            PrimaryButton({
              text: '重新生成',
              isEnabled: !this.generating,
              action: (): void => {
                this.hasStarted = false;
                this.startGenerate();
              }
            })
          }
        }
        .width('100%')
        .padding(24)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .shadow({ radius: 16, color: '#12000000', offsetX: 0, offsetY: 5 })

        Blank()
      }
      .width('100%')
      .height('100%')
      .padding({ left: 16, right: 16 })
      .backgroundColor('#F5F7FA')
    }
    .hideTitleBar(true)
  }
}
