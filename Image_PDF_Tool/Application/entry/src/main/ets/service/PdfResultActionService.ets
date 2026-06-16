import { common, Want, wantConstant } from '@kit.AbilityKit';
import { fileUri } from '@kit.CoreFileKit';
import { filePreview } from '@kit.PreviewKit';
import { PdfRecordModel } from '../model/PdfRecordModel';
import { FileUtil } from '../utils/FileUtil';

const PDF_MIME_TYPE = 'application/pdf';
const ACTION_SEND_DATA = 'ohos.want.action.sendData';

export class PdfResultActionService {
  private static getPdfFileUri(record: PdfRecordModel): string {
    if (record.filePath.length === 0 || FileUtil.getFileSize(record.filePath) <= 0) {
      throw new Error('PDF 文件不存在，请重新生成');
    }
    return fileUri.getUriFromPath(record.filePath);
  }

  static async previewPdf(context: common.UIAbilityContext, record: PdfRecordModel): Promise<void> {
    const uri = PdfResultActionService.getPdfFileUri(record);
    const canPreview = await filePreview.canPreview(context, uri);
    if (!canPreview) {
      throw new Error('当前设备暂不支持预览 PDF，请先保存到本地查看');
    }
    await filePreview.openPreview(context, {
      title: record.fileName,
      uri: uri,
      mimeType: PDF_MIME_TYPE
    });
  }

  static async sharePdf(context: common.UIAbilityContext, record: PdfRecordModel): Promise<void> {
    const uri = PdfResultActionService.getPdfFileUri(record);
    const want: Want = {
      action: ACTION_SEND_DATA,
      uri: uri,
      type: PDF_MIME_TYPE,
      flags: wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION,
      parameters: {
        [wantConstant.Params.CONTENT_TITLE_KEY]: record.fileName,
        [wantConstant.Params.SHARE_ABSTRACT_KEY]: '由图片转PDF工具箱生成',
        [wantConstant.Params.PARAMS_STREAM]: [uri]
      }
    };
    await context.startAbility(want);
  }
}
