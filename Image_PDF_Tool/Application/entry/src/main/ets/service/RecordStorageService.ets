import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { PdfRecordModel } from '../model/PdfRecordModel';

const STORE_NAME = 'pdf_record_store';
const RECORD_KEY = 'recent_pdf_records';
const MAX_RECORD_COUNT = 10;

export class RecordStorageService {
  static async getRecords(context: common.UIAbilityContext): Promise<PdfRecordModel[]> {
    const store = await preferences.getPreferences(context, STORE_NAME);
    const value = await store.get(RECORD_KEY, '[]') as string;
    try {
      const parsed = JSON.parse(value) as PdfRecordModel[];
      return parsed.slice(0, MAX_RECORD_COUNT);
    } catch (_) {
      return [];
    }
  }

  static async addRecord(context: common.UIAbilityContext, record: PdfRecordModel): Promise<void> {
    const records = await RecordStorageService.getRecords(context);
    const nextRecords = [record].concat(records.filter((item: PdfRecordModel): boolean => {
      return item.filePath !== record.filePath;
    })).slice(0, MAX_RECORD_COUNT);
    await RecordStorageService.saveRecords(context, nextRecords);
  }

  static async deleteRecord(context: common.UIAbilityContext, id: string): Promise<void> {
    const records = await RecordStorageService.getRecords(context);
    await RecordStorageService.saveRecords(context, records.filter((item: PdfRecordModel): boolean => item.id !== id));
  }

  static async clearRecords(context: common.UIAbilityContext): Promise<void> {
    await RecordStorageService.saveRecords(context, []);
  }

  private static async saveRecords(context: common.UIAbilityContext, records: PdfRecordModel[]): Promise<void> {
    const store = await preferences.getPreferences(context, STORE_NAME);
    await store.put(RECORD_KEY, JSON.stringify(records.slice(0, MAX_RECORD_COUNT)));
    await store.flush();
  }
}
