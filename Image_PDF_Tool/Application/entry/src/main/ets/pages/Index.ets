import { common } from '@kit.AbilityKit';
import { AtomicServiceTabs, promptAction, TabBarOptions, TabBarPosition } from '@kit.ArkUI';
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
import { NavPathStackUtil } from '../utils/NavPathStackUtil';
import { ToastUtil } from '../utils/ToastUtil';
import { ImageManagerPage } from './ImageManagerPage';
import { PdfSettingPage } from './PdfSettingPage';
import { GeneratePage } from './GeneratePage';
import { ResultPage } from './ResultPage';

@Entry
@Component
struct Index {
  private pathStack: NavPathStack = new NavPathStack();
  @Provide('recordRefreshVersion') @Watch('handleRecordRefresh') recordRefreshVersion: number = 0;
  @State records: PdfRecordModel[] = [];
  @State selecting: boolean = false;
  @State currentTabIndex: number = 0;

  aboutToAppear(): void {
    this.loadRecords();
  }

  @Builder
  pathMap(routeName: string) {
    if (routeName === 'ImageManagerPage') {
      ImageManagerPage({ pathStack: this.pathStack });
    } else if (routeName === 'PdfSettingPage') {
      PdfSettingPage({ pathStack: this.pathStack });
    } else if (routeName === 'GeneratePage') {
      GeneratePage({ pathStack: this.pathStack });
    } else if (routeName === 'ResultPage') {
      ResultPage({ pathStack: this.pathStack });
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
      NavPathStackUtil.pushPathByName(this.pathStack, 'ImageManagerPage', null);
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
      NavPathStackUtil.pushPathByName(this.pathStack, 'ImageManagerPage', null);
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
      NavPathStackUtil.pushPathByName(this.pathStack, 'ResultPage', null);
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

  @LocalBuilder
  homeTabContent() {
    Scroll() {
      Column({ space: 16 }) {
        Row()
        .height(44)
        .width('100%')

        Column({ space: 12 }) {
          Row() {
            Column({ space: 6 }) {
              Text('图片转 PDF')
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              Text('多图合成 · 灵活排序 · 高清保存')
                .fontSize(14)
                .fontColor('#DCEBFF')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text('PDF')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2F80ED')
              .width(58)
              .height(58)
              .textAlign(TextAlign.Center)
              .borderRadius(18)
              .backgroundColor('#FFFFFF')
          }
          .width('100%')

          Text('选择图片后，可按需调整顺序、纸张尺寸与边距，一键生成可保存和分享的 PDF 文件。')
            .fontSize(13)
            .fontColor('#EAF4FF')
            .lineHeight(21)
            .width('100%')

          Row({ space: 10 }) {
            Column({ space: 2 }) {
              Text(`${(this.records ?? []).length}`)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              Text('最近记录')
                .fontSize(12)
                .fontColor('#DCEBFF')
            }
            .layoutWeight(1)
            .padding({ top: 10, bottom: 10 })
            .backgroundColor('#24FFFFFF')
            .borderRadius(14)

            Column({ space: 2 }) {
              Text('10')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              Text('最多保留')
                .fontSize(12)
                .fontColor('#DCEBFF')
            }
            .layoutWeight(1)
            .padding({ top: 10, bottom: 10 })
            .backgroundColor('#24FFFFFF')
            .borderRadius(14)
          }
          .width('100%')
        }
        .padding(18)
        .width('100%')
        .borderRadius(24)
        .linearGradient({
          angle: 135,
          colors: [['#2F80ED', 0.0], ['#56CCF2', 1.0]]
        })
        .shadow({ radius: 24, color: '#26007DFF', offsetX: 0, offsetY: 10 })

        Column({ space: 12 }) {
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
        .padding(14)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .shadow({ radius: 16, color: '#12000000', offsetX: 0, offsetY: 5 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 18 })
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180,
      colors: [['#F2F8FF', 0.0], ['#F7F8FA', 0.6], ['#FFFFFF', 1.0]]
    })
    .scrollBar(BarState.Off)
  }

  @LocalBuilder
  recentTabContent() {
    Column({ space: 16 }) {
      Row() {
        Text('最近记录')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2937')
        Blank()
      }
      .height(44)
      .width('100%')

      Column({ space: 10 }) {
        Row() {
          Column({ space: 4 }) {
            Text('生成历史')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1F2937')
            Text('快速打开、预览或删除已生成的 PDF')
              .fontSize(13)
              .fontColor('#6B7280')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          if ((this.records ?? []).length > 0) {
            Button('清空')
              .height(36)
              .fontSize(13)
              .fontColor('#EF4444')
              .backgroundColor('#FFF1F2')
              .borderRadius(18)
              .onClick((): void => {
                this.confirmClearRecords();
              })
          }
        }
        .width('100%')

        Row() {
          Text(`${(this.records ?? []).length} 个文件`)
            .fontSize(13)
            .fontColor('#2F80ED')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor('#EAF4FF')
            .borderRadius(14)
          Blank()
          Text('最近生成优先展示')
            .fontSize(12)
            .fontColor('#9CA3AF')
        }
        .width('100%')
      }
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(20)
      .shadow({ radius: 16, color: '#10000000', offsetX: 0, offsetY: 5 })
      .width('100%')

      if ((this.records ?? []).length === 0) {
        Column({ space: 14 }) {
          EmptyView({
            icon: 'PDF',
            title: '暂无生成记录',
            description: '完成一次转换后，PDF 会显示在这里'
          })
          Button('去首页生成 PDF')
            .height(44)
            .fontSize(15)
            .fontColor('#FFFFFF')
            .backgroundColor('#2F80ED')
            .borderRadius(22)
            .onClick((): void => {
              this.currentTabIndex = 0;
            })
        }
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(20)
        .shadow({ radius: 14, color: '#10000000', offsetX: 0, offsetY: 4 })
        .width('100%')
          .layoutWeight(1)
      } else {
        Scroll() {
          Column({ space: 12 }) {
            ForEach(this.records ?? [], (record: PdfRecordModel) => {
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

            Column()
              .height(12)
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 34, bottom: 14 })
    .linearGradient({
      angle: 180,
      colors: [['#F4F9FF', 0.0], ['#F7F8FA', 0.7], ['#FFFFFF', 1.0]]
    })
  }

  @LocalBuilder
  mineTabContent() {
    Scroll() {
      Column({ space: 16 }) {
        Text('我的')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2937')
          .height(44)
          .width('100%')

        Column({ space: 12 }) {
          Row({ space: 14 }) {
            Text('PDF')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .width(58)
              .height(58)
              .textAlign(TextAlign.Center)
              .borderRadius(18)
              .linearGradient({
                angle: 135,
                colors: [['#2F80ED', 0.0], ['#56CCF2', 1.0]]
              })

            Column({ space: 5 }) {
              Text('图片转PDF工具箱')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1F2937')
              Text('轻量、清爽、专注转换')
                .fontSize(13)
                .fontColor('#6B7280')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')

          Text('专注图片转 PDF：选择图片、排序、设置参数、生成并保存最近记录。')
            .fontSize(14)
            .fontColor('#6B7280')
            .lineHeight(22)
            .width('100%')
        }
        .padding(18)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(22)
        .shadow({ radius: 18, color: '#12000000', offsetX: 0, offsetY: 6 })

        Column({ space: 0 }) {
          Row() {
            Text('当前记录')
              .fontSize(15)
              .fontColor('#374151')
            Blank()
            Text(`${(this.records ?? []).length} 条`)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#2F80ED')
          }
          .height(48)
          .width('100%')

          Divider()
            .color('#F1F5F9')

          Row() {
            Text('隐私说明')
              .fontSize(15)
              .fontColor('#374151')
            Blank()
            Text('本地处理')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#10B981')
          }
          .height(48)
          .width('100%')

          Divider()
            .color('#F1F5F9')

          Row() {
            Text('主要能力')
              .fontSize(15)
              .fontColor('#374151')
            Blank()
            Text('图片合成 PDF')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#6B7280')
          }
          .height(48)
          .width('100%')
        }
        .padding({ left: 16, right: 16, top: 4, bottom: 4 })
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .shadow({ radius: 14, color: '#10000000', offsetX: 0, offsetY: 4 })

        Column({ space: 8 }) {
          Text('使用建议')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F2937')
            .width('100%')
          Text('为了获得更清晰的 PDF，建议优先选择原图，并在生成前检查图片顺序。')
            .fontSize(13)
            .fontColor('#6B7280')
            .lineHeight(21)
            .width('100%')
        }
        .padding(16)
        .width('100%')
        .backgroundColor('#F0F7FF')
        .borderRadius(18)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 24, bottom: 18 })
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180,
      colors: [['#F4F9FF', 0.0], ['#F7F8FA', 0.7], ['#FFFFFF', 1.0]]
    })
    .scrollBar(BarState.Off)
  }

  build() {
    Navigation(this.pathStack) {
      AtomicServiceTabs({
        tabContents: [
          this.homeTabContent,
          this.recentTabContent,
          this.mineTabContent
        ],
        tabBarOptionsArray: [
          new TabBarOptions($r('app.media.window'), '首页', '#801F2937', '#FF2F80ED'),
          new TabBarOptions($r('app.media.ic_public_time'), '最近记录', '#801F2937', '#FF2F80ED'),
          new TabBarOptions($r('app.media.user_dark'), '我的', '#801F2937', '#FF2F80ED')
        ],
        tabBarPosition: TabBarPosition.BOTTOM,
        barBackgroundColor: '#FAFFFFFF',
        barOverlap: false,
        index: this.currentTabIndex,
        onChange: (index: number): void => {
          this.currentTabIndex = index;
          if (index === 1) {
            this.loadRecords();
          }
        }
      })
    }
    .hideTitleBar(true)
    .navDestination(this.pathMap)
  }
}
