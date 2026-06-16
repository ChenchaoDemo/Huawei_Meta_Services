export interface ImageFileModel {
  id: string;
  uri: string;
  name: string;
  width: number;
  height: number;
  size: number;
  mimeType: string;
  order: number;
}

export function cloneImageFile(image: ImageFileModel): ImageFileModel {
  return {
    id: image.id,
    uri: image.uri,
    name: image.name,
    width: image.width,
    height: image.height,
    size: image.size,
    mimeType: image.mimeType,
    order: image.order
  };
}

export function refreshImageOrder(images: ImageFileModel[]): ImageFileModel[] {
  return images.map((item: ImageFileModel, index: number): ImageFileModel => {
    return {
      id: item.id,
      uri: item.uri,
      name: item.name,
      width: item.width,
      height: item.height,
      size: item.size,
      mimeType: item.mimeType,
      order: index + 1
    };
  });
}
