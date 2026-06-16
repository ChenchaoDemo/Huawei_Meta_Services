import { common } from '@kit.AbilityKit';
import { AppHeader } from '../components/AppHeader';
import { PrimaryButton } from '../components/PrimaryButton';
import { EmptyView } from '../components/EmptyView';
import { PdfRecordModel } from '../model/PdfRecordModel';
import { ConvertSessionService } from '../service/ConvertSessionService';
import { FileSaveService } from '../service/FileSaveService';
import { PdfResultActionService } from '../service/PdfResultActionService';
import { RecordStorageService } from '../service/RecordStorageService';
import { SizeUtil } from '../utils/SizeUtil';
import { DateUtil } from '../utils/DateUtil';
import { ToastUtil } from '../utils/ToastUtil';

@Entry
@Component
export struct ResultPage {
  @Consume('pathStack') pathStack: NavPathStack;
  @Consume('recordRefreshVersion') recordRefreshVersion: number;
  @State hasRecord: boolean = false;
  @State record: PdfRecordModel = {
    id: '',
    fileName: '',
    filePath: '',
    fileSize: 0,
    pageCount: 0,
    createTime: 0
  };
  @State saving: boolean = false;
  @State previewing: boolean = false;
  @State sharing: boolean = false;

  aboutToAppear(): void {
    const currentRecord = ConvertSessionService.getRecord();
    if (currentRecord !== null) {
      this.record = currentRecord;
      this.hasRecord = true;
    } else {
      this.hasRecord = false;
    }
  }

  private async previewPdf(): Promise<void> {
    if (!this.hasRecord || this.previewing) {
      return;
    }
    this.previewing = true;
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await PdfResultActionService.previewPdf(context, this.record);
    } catch (err) {
      ToastUtil.show((err as Error).message || '预览失败');
    } finally {
      this.previewing = false;
    }
  }

  private async sharePdf(): Promise<void> {
    if (!this.hasRecord || this.sharing) {
      return;
    }
    this.sharing = true;
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await PdfResultActionService.sharePdf(context, this.record);
    } catch (err) {
      ToastUtil.show((err as Error).message || '分享失败');
    } finally {
      this.sharing = false;
    }
  }

  private async saveToLocal(): Promise<void> {
    if (!this.hasRecord || this.saving) {
      return;
    }
    this.saving = true;
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const savedPath = await FileSaveService.saveToUserSelectedPath(this.record);
      const saved = await FileSaveService.saveCopyToSandbox(this.record, context);
      ConvertSessionService.setRecord(saved);
      await RecordStorageService.addRecord(context, saved);
      this.record = saved;
      this.recordRefreshVersion++;
      ToastUtil.show(`已保存：${savedPath}`);
    } catch (err) {
      ToastUtil.show((err as Error).message || '保存失败');
    } finally {
      this.saving = false;
    }
  }

  private backHome(): void {
    this.recordRefreshVersion++;
    this.pathStack.clear();
  }

  @Builder
  infoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor('#9CA3AF')
        .width(82)
      Text(value)
        .fontSize(14)
        .fontColor('#1F2937')
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
  }

  build() {
    NavDestination() {
      if (!this.hasRecord) {
        Column({ space: 16 }) {
          AppHeader({
            title: '生成结果',
            showBack: true,
            backAction: (): void => {
              this.pathStack.pop();
            }
          })
          EmptyView({
            icon: '!',
            title: '没有找到 PDF 记录',
            description: '请重新选择图片生成 PDF'
          })
        }
        .width('100%')
        .height('100%')
        .padding({ left: 16, right: 16 })
        .backgroundColor('#F5F7FA')
      } else {
        Scroll() {
          Column({ space: 16 }) {
            AppHeader({
              title: '生成结果',
              subtitle: 'PDF 已生成，可预览、分享或保存',
              showBack: true,
              backAction: (): void => {
                this.pathStack.pop();
              }
            })

            Column({ space: 14 }) {
              Text('✓')
                .fontSize(34)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Bold)
                .width(72)
                .height(72)
                .textAlign(TextAlign.Center)
                .backgroundColor('#00B894')
                .borderRadius(36)
              Text('PDF 生成成功')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1F2937')
              Text(this.record.fileName)
                .fontSize(14)
                .fontColor('#6B7280')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .padding(24)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .shadow({ radius: 16, color: '#12000000', offsetX: 0, offsetY: 5 })

            Column({ space: 12 }) {
              this.infoRow('文件名', this.record.fileName)
              this.infoRow('文件大小', SizeUtil.formatFileSize(this.record.fileSize))
              this.infoRow('页数', `${this.record.pageCount} 页`)
              this.infoRow('生成时间', DateUtil.formatDateTime(this.record.createTime))
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .shadow({ radius: 12, color: '#0D000000', offsetX: 0, offsetY: 4 })

            Column({ space: 12 }) {
              PrimaryButton({
                text: '预览 PDF',
                loading: this.previewing,
                btnBackgroundColor: '#2F80ED',
                action: (): void => {
                  this.previewPdf();
                }
              })
              PrimaryButton({
                text: '分享 PDF',
                loading: this.sharing,
                btnBackgroundColor: '#00B894',
                action: (): void => {
                  this.sharePdf();
                }
              })
              PrimaryButton({
                text: '保存到本地',
                loading: this.saving,
                btnBackgroundColor: '#1F2937',
                action: (): void => {
                  this.saveToLocal();
                }
              })
              Button('返回首页')
                .height(48)
                .width('100%')
                .fontSize(16)
                .fontColor('#4B5563')
                .backgroundColor('#FFFFFF')
                .borderRadius(24)
                .onClick((): void => {
                  this.backHome();
                })
            }
            .width('100%')
            .padding({ bottom: 24 })
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F5F7FA')
        .scrollBar(BarState.Off)
      }
    }
    .hideTitleBar(true)
  }
}
