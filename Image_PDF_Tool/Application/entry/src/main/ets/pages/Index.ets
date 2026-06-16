import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { AppHeader } from '../components/AppHeader';
import { FeatureCard } from '../components/FeatureCard';
import { PrimaryButton } from '../components/PrimaryButton';
import { EmptyView } from '../components/EmptyView';
import { RecentPdfCard } from '../components/RecentPdfCard';
import { PdfRecordModel } from '../model/PdfRecordModel';
import { ImagePickerService } from '../service/ImagePickerService';
import { ConvertSessionService } from '../service/ConvertSessionService';
import { RecordStorageService } from '../service/RecordStorageService';
import { FileUtil } from '../utils/FileUtil';
import { ToastUtil } from '../utils/ToastUtil';
import { ImageManagerPage } from './ImageManagerPage';
import { PdfSettingPage } from './PdfSettingPage';
import { GeneratePage } from './GeneratePage';
import { ResultPage } from './ResultPage';

@Entry
@Component
struct Index {
  @Provide('pathStack') pathStack: NavPathStack = new NavPathStack();
  @Provide('recordRefreshVersion') @Watch('handleRecordRefresh') recordRefreshVersion: number = 0;
  @State records: PdfRecordModel[] = [];
  @State selecting: boolean = false;

  aboutToAppear(): void {
    this.loadRecords();
  }

  @Builder
  pathMap(routeName: string) {
    if (routeName === 'ImageManagerPage') {
      ImageManagerPage();
    } else if (routeName === 'PdfSettingPage') {
      PdfSettingPage();
    } else if (routeName === 'GeneratePage') {
      GeneratePage();
    } else if (routeName === 'ResultPage') {
      ResultPage();
    }
  }

  private async loadRecords(): Promise<void> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.records = await RecordStorageService.getRecords(context);
  }

  private handleRecordRefresh(): void {
    this.loadRecords();
  }

  private async pickImages(): Promise<void> {
    if (this.selecting) {
      return;
    }
    this.selecting = true;
    try {
      const images = await ImagePickerService.selectImages(0);
      if (images.length === 0) {
        ToastUtil.show('未选择图片');
        return;
      }
      ConvertSessionService.setImages(images);
      this.pathStack.pushPathByName('ImageManagerPage', null);
    } catch (err) {
      ToastUtil.show((err as Error).message || '选择图片失败');
    } finally {
      this.selecting = false;
    }
  }

  private async takePhoto(): Promise<void> {
    if (this.selecting) {
      return;
    }
    this.selecting = true;
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const images = await ImagePickerService.takePhoto(context, 0);
      if (images.length === 0) {
        ToastUtil.show('未拍摄图片');
        return;
      }
      ConvertSessionService.setImages(images);
      this.pathStack.pushPathByName('ImageManagerPage', null);
    } catch (err) {
      ToastUtil.show((err as Error).message || '拍照失败');
    } finally {
      this.selecting = false;
    }
  }

  private async openRecord(record: PdfRecordModel): Promise<void> {
    try {
      if (FileUtil.getFileSize(record.filePath) <= 0) {
        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        await RecordStorageService.deleteRecord(context, record.id);
        this.records = await RecordStorageService.getRecords(context);
        ToastUtil.show('PDF 文件不存在，已移除该记录');
        return;
      }
      ConvertSessionService.setRecord(record);
      this.pathStack.pushPathByName('ResultPage', null);
    } catch (err) {
      ToastUtil.show((err as Error).message || '打开记录失败');
    }
  }

  private confirmDeleteRecord(record: PdfRecordModel): void {
    promptAction.showDialog({
      title: '删除记录',
      message: `确定删除“${record.fileName}”吗？对应的沙箱 PDF 文件也会一起删除。`,
      buttons: [
        { text: '取消', color: '#6B7280' },
        { text: '删除', color: '#EF4444' }
      ]
    }).then((result): void => {
      if (result.index === 1) {
        this.deleteRecord(record);
      }
    });
  }

  private async deleteRecord(record: PdfRecordModel): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      FileUtil.deleteFileIfExists(record.filePath);
      await RecordStorageService.deleteRecord(context, record.id);
      this.records = await RecordStorageService.getRecords(context);
      ToastUtil.show('已删除');
    } catch (err) {
      ToastUtil.show((err as Error).message || '删除失败');
    }
  }

  private confirmClearRecords(): void {
    if (this.records.length === 0) {
      return;
    }
    promptAction.showDialog({
      title: '清空最近生成',
      message: '确定清空所有最近生成记录吗？对应的沙箱 PDF 文件也会一起删除。',
      buttons: [
        { text: '取消', color: '#6B7280' },
        { text: '清空', color: '#EF4444' }
      ]
    }).then((result): void => {
      if (result.index === 1) {
        this.clearRecords();
      }
    });
  }

  private async clearRecords(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      this.records.forEach((record: PdfRecordModel): void => {
        FileUtil.deleteFileIfExists(record.filePath);
      });
      await RecordStorageService.clearRecords(context);
      this.records = [];
      ToastUtil.show('已清空最近生成');
    } catch (err) {
      ToastUtil.show((err as Error).message || '清空失败');
    }
  }

  build() {
    Navigation(this.pathStack) {
      Stack() {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 160,
            colors: [['#F5F7FA', 0.0], ['#EAF4FF', 1.0]]
          })

        Scroll() {
          Column({ space: 16 }) {
            AppHeader({
              title: '图片转PDF工具箱',
              subtitle: '多张图片一键生成高清 PDF'
            })

            Column({ space: 14 }) {
              Row({ space: 12 }) {
                FeatureCard({
                  icon: '多',
                  title: '多图合成',
                  description: '一次选择多张图片'
                })
                FeatureCard({
                  icon: '序',
                  title: '灵活排序',
                  description: '支持上移和下移'
                })
              }
              Row({ space: 12 }) {
                FeatureCard({
                  icon: 'A4',
                  title: '页面尺寸',
                  description: 'A4 或原图尺寸'
                })
                FeatureCard({
                  icon: '存',
                  title: '保存分享',
                  description: '本地生成 PDF'
                })
              }
            }

            Column({ space: 12 }) {
              PrimaryButton({
                text: '选择图片',
                loading: this.selecting,
                action: (): void => {
                  this.pickImages();
                }
              })
              Button({ type: ButtonType.Capsule }) {
                Text('拍照添加')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#2F80ED')
              }
              .height(48)
              .width('100%')
              .borderRadius(24)
              .backgroundColor('#FFFFFF')
              .border({ width: 1, color: '#BFDBFE' })
              .enabled(!this.selecting)
              .onClick((): void => {
                this.takePhoto();
              })
            }
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .shadow({ radius: 16, color: '#12000000', offsetX: 0, offsetY: 5 })

            Row() {
              Text('最近生成')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1F2937')
              Blank()
              if (this.records.length > 0) {
                Button('清空')
                  .height(32)
                  .fontSize(13)
                  .fontColor('#EF4444')
                  .backgroundColor('#FFF1F2')
                  .borderRadius(16)
                  .onClick((): void => {
                    this.confirmClearRecords();
                  })
              }
            }
            .width('100%')
            .margin({ top: 4 })

            if (this.records.length === 0) {
              EmptyView({
                icon: 'PDF',
                title: '暂无生成记录',
                description: '完成一次转换后，PDF 会显示在这里'
              })
            } else {
              Column({ space: 12 }) {
                ForEach(this.records, (record: PdfRecordModel) => {
                  RecentPdfCard({
                    record: record,
                    openAction: (): void => {
                      this.openRecord(record);
                    },
                    deleteAction: (): void => {
                      this.confirmDeleteRecord(record);
                    }
                  })
                }, (record: PdfRecordModel): string => record.id)
              }
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 24 })
        }
        .width('100%')
        .height('100%')
      }
    }
    .hideTitleBar(true)
    .navDestination(this.pathMap)
    .onAppear((): void => {
      this.loadRecords();
    })
  }
}
