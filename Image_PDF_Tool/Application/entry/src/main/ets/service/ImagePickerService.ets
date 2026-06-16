import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';
import { camera, cameraPicker } from '@kit.CameraKit';
import { ImageFileModel } from '../model/ImageFileModel';
import { MAX_IMAGE_COUNT } from '../model/BusinessConstants';
import { FileUtil } from '../utils/FileUtil';

interface ImageSizeInfo {
  width: number;
  height: number;
}

export class ImagePickerService {
  static async selectImages(currentCount: number = 0): Promise<ImageFileModel[]> {
    const remainCount = MAX_IMAGE_COUNT - currentCount;
    if (remainCount <= 0) {
      throw new Error(`最多只能选择 ${MAX_IMAGE_COUNT} 张图片`);
    }

    const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    photoSelectOptions.maxSelectNumber = remainCount;

    const result = await new photoAccessHelper.PhotoViewPicker().select(photoSelectOptions);
    if (!result.photoUris || result.photoUris.length === 0) {
      return [];
    }

    const images: ImageFileModel[] = [];
    for (let index = 0; index < result.photoUris.length; index++) {
      const uri = result.photoUris[index];
      const name = FileUtil.getFileName(uri);
      if (!ImagePickerService.isImageName(name)) {
        continue;
      }
      const imageSize = await ImagePickerService.safeGetImageSize(uri);
      images.push({
        id: `${Date.now()}_${index}_${Math.floor(Math.random() * 100000)}`,
        uri: uri,
        name: name.length > 0 ? name : `图片_${index + 1}.jpg`,
        width: imageSize.width,
        height: imageSize.height,
        size: ImagePickerService.safeGetSize(uri),
        mimeType: FileUtil.getMimeTypeByName(name),
        order: currentCount + images.length + 1
      });
    }
    return images;
  }

  static async takePhoto(context: common.UIAbilityContext, currentCount: number = 0): Promise<ImageFileModel[]> {
    if (currentCount >= MAX_IMAGE_COUNT) {
      throw new Error(`最多只能选择 ${MAX_IMAGE_COUNT} 张图片`);
    }
    const profile: cameraPicker.PickerProfile = {
      cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK
    };
    const result = await cameraPicker.pick(context, [cameraPicker.PickerMediaType.PHOTO], profile);
    if (!result || result.resultUri.length === 0) {
      return [];
    }
    const name = FileUtil.getFileName(result.resultUri);
    const imageSize = await ImagePickerService.safeGetImageSize(result.resultUri);
    return [{
      id: `${Date.now()}_camera_${Math.floor(Math.random() * 100000)}`,
      uri: result.resultUri,
      name: name.length > 0 ? name : `拍照_${Date.now()}.jpg`,
      width: imageSize.width,
      height: imageSize.height,
      size: ImagePickerService.safeGetSize(result.resultUri),
      mimeType: FileUtil.getMimeTypeByName(name),
      order: currentCount + 1
    }];
  }

  private static isImageName(name: string): boolean {
    const lowerName = name.toLowerCase();
    if (lowerName.indexOf('.') < 0) {
      return true;
    }
    return lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg') || lowerName.endsWith('.png') ||
      lowerName.endsWith('.webp') || lowerName.endsWith('.heic') || lowerName.endsWith('.heif') ||
      lowerName.endsWith('.bmp');
  }

  private static safeGetSize(uri: string): number {
    try {
      return fileIo.statSync(uri).size;
    } catch (_) {
      return 0;
    }
  }

  private static async safeGetImageSize(uri: string): Promise<ImageSizeInfo> {
    try {
      const imageFile = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      try {
        const source = image.createImageSource(imageFile.fd);
        const info = await source.getImageInfo();
        return {
          width: info.size.width,
          height: info.size.height
        };
      } finally {
        fileIo.closeSync(imageFile);
      }
    } catch (_) {
      return {
        width: 0,
        height: 0
      };
    }
  }
}
