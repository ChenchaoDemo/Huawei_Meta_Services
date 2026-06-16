import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { AppHeader } from '../components/AppHeader';
import { ImageItemCard } from '../components/ImageItemCard';
import { PrimaryButton } from '../components/PrimaryButton';
import { EmptyView } from '../components/EmptyView';
import { ImageFileModel, refreshImageOrder, cloneImageFile } from '../model/ImageFileModel';
import { ImagePickerService } from '../service/ImagePickerService';
import { ConvertSessionService } from '../service/ConvertSessionService';
import { ToastUtil } from '../utils/ToastUtil';

@Entry
@Component
export struct ImageManagerPage {
  @Consume('pathStack') pathStack: NavPathStack;
  @State images: ImageFileModel[] = [];
  @State adding: boolean = false;

  aboutToAppear(): void {
    this.images = ConvertSessionService.getImages();
  }

  private syncImages(images: ImageFileModel[]): void {
    this.images = refreshImageOrder(images);
    ConvertSessionService.setImages(this.images);
  }

  private async addImages(): Promise<void> {
    if (this.images.length >= 30) {
      ToastUtil.show('最多只能选择 30 张图片');
      return;
    }
    this.adding = true;
    try {
      const picked = await ImagePickerService.selectImages(this.images.length);
      if (picked.length === 0) {
        ToastUtil.show('未选择新图片');
        return;
      }
      this.syncImages(this.images.concat(picked));
    } catch (err) {
      ToastUtil.show((err as Error).message || '添加图片失败');
    } finally {
      this.adding = false;
    }
  }

  private async takePhoto(): Promise<void> {
    if (this.images.length >= 30) {
      ToastUtil.show('最多只能选择 30 张图片');
      return;
    }
    this.adding = true;
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const picked = await ImagePickerService.takePhoto(context, this.images.length);
      if (picked.length === 0) {
        ToastUtil.show('未拍摄图片');
        return;
      }
      this.syncImages(this.images.concat(picked));
    } catch (err) {
      ToastUtil.show((err as Error).message || '拍照失败');
    } finally {
      this.adding = false;
    }
  }

  private confirmDelete(index: number): void {
    promptAction.showDialog({
      title: '删除图片',
      message: '确定删除这张图片吗？',
      buttons: [
        { text: '取消', color: '#6B7280' },
        { text: '删除', color: '#EF4444' }
      ]
    }).then((result): void => {
      if (result.index === 1) {
        const next = this.images.slice();
        next.splice(index, 1);
        this.syncImages(next);
      }
    });
  }

  private confirmClear(): void {
    if (this.images.length === 0) {
      return;
    }
    promptAction.showDialog({
      title: '清空全部',
      message: '确定移除当前已选择的全部图片吗？',
      buttons: [
        { text: '取消', color: '#6B7280' },
        { text: '清空', color: '#EF4444' }
      ]
    }).then((result): void => {
      if (result.index === 1) {
        this.syncImages([]);
      }
    });
  }

  private moveUp(index: number): void {
    if (index <= 0) {
      return;
    }
    const next = this.images.slice();
    // 创建新对象而不是直接修改
    const item1 = next[index - 1];
    const item2 = next[index];
    next[index - 1] = {
      id: item2.id,
      uri: item2.uri,
      name: item2.name,
      width: item2.width,
      height: item2.height,
      size: item2.size,
      mimeType: item2.mimeType,
      order: index
    };
    next[index] = {
      id: item1.id,
      uri: item1.uri,
      name: item1.name,
      width: item1.width,
      height: item1.height,
      size: item1.size,
      mimeType: item1.mimeType,
      order: index + 1
    };
    this.syncImages(next);
  }

  private moveDown(index: number): void {
    if (index >= this.images.length - 1) {
      return;
    }
    const next = this.images.slice();
    // 创建新对象而不是直接修改
    const item1 = next[index];
    const item2 = next[index + 1];
    next[index] = {
      id: item2.id,
      uri: item2.uri,
      name: item2.name,
      width: item2.width,
      height: item2.height,
      size: item2.size,
      mimeType: item2.mimeType,
      order: index + 1
    };
    next[index + 1] = {
      id: item1.id,
      uri: item1.uri,
      name: item1.name,
      width: item1.width,
      height: item1.height,
      size: item1.size,
      mimeType: item1.mimeType,
      order: index + 2
    };
    this.syncImages(next);
  }

  private nextStep(): void {
    if (this.images.length === 0) {
      ToastUtil.show('请先选择图片');
      return;
    }
    ConvertSessionService.setImages(this.images);
    this.pathStack.pushPathByName('PdfSettingPage', null);
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#F5F7FA')

        Column() {
          AppHeader({
            title: '管理图片',
            subtitle: `${this.images.length} / 30 张，可调整 PDF 页序`,
            showBack: true,
            backAction: (): void => {
              this.pathStack.pop();
            }
          })

          Row() {
            Button('继续添加')
              .height(36)
              .fontSize(14)
              .fontColor('#2F80ED')
              .backgroundColor('#EAF4FF')
              .enabled(!this.adding && this.images.length < 30)
              .onClick((): void => {
                this.addImages();
              })
            Button('拍照')
              .height(36)
              .fontSize(14)
              .fontColor('#00B894')
              .backgroundColor('#ECFDF5')
              .enabled(!this.adding && this.images.length < 30)
              .margin({ left: 8 })
              .onClick((): void => {
                this.takePhoto();
              })
            Blank()
            Button('清空全部')
              .height(36)
              .fontSize(14)
              .fontColor('#EF4444')
              .backgroundColor('#FFF1F2')
              .enabled(this.images.length > 0)
              .onClick((): void => {
                this.confirmClear();
              })
          }
          .width('100%')
          .margin({ bottom: 12 })

          if (this.images.length === 0) {
            EmptyView({
              icon: '图',
              title: '还没有选择图片',
              description: '点击继续添加，从相册选择需要转换的图片'
            })
          } else {
            Scroll() {
              Column({ space: 12 }) {
                ForEach(this.images, (image: ImageFileModel, index: number) => {
                  ImageItemCard({
                    image: image,
                    isFirst: index === 0,
                    isLast: index === this.images.length - 1,
                    deleteAction: (): void => {
                      this.confirmDelete(index);
                    },
                    upAction: (): void => {
                      this.moveUp(index);
                    },
                    downAction: (): void => {
                      this.moveDown(index);
                    }
                  })
                }, (image: ImageFileModel): string => image.id)
                Column()
                  .height(84)
              }
              .width('100%')
            }
            .layoutWeight(1)
            .scrollBar(BarState.Off)
          }
        }
        .width('100%')
        .height('100%')
        .padding({ left: 16, right: 16 })

        Column() {
          PrimaryButton({
            text: '下一步',
            isEnabled: this.images.length > 0,
            action: (): void => {
              this.nextStep();
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
