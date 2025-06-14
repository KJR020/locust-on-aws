/**
 * テスト用Webサーバー
 * オートスケーリングのテスト対象となるシンプルなWebアプリケーション
 */

import express, { Request, Response } from 'express';
import { cpus } from 'os';

/**
 * サーバー設定の型定義
 */
type サーバー設定 = {
  readonly ポート番号: number;
  readonly 遅延最小値: number;
  readonly 遅延最大値: number;
};

/**
 * レスポンスの型定義
 */
type レスポンス = {
  readonly メッセージ: string;
  readonly タイムスタンプ: string;
  readonly 処理時間: number;
  readonly サーバー情報: {
    readonly ホスト名: string;
    readonly CPU数: number;
  };
};

/**
 * サーバー設定のデフォルト値
 */
const デフォルト設定: サーバー設定 = {
  ポート番号: parseInt(process.env.PORT || '3000', 10),
  遅延最小値: 10,
  遅延最大値: 100
};

/**
 * ランダムな遅延時間を生成する関数
 * @param 最小値 - 最小遅延時間（ミリ秒）
 * @param 最大値 - 最大遅延時間（ミリ秒）
 * @returns ランダムな遅延時間（ミリ秒）
 */
const ランダム遅延生成 = (最小値: number, 最大値: number): number => {
  return Math.floor(Math.random() * (最大値 - 最小値 + 1)) + 最小値;
};

/**
 * 指定された時間だけ処理を遅延させる関数
 * @param ミリ秒 - 遅延時間（ミリ秒）
 * @returns Promiseオブジェクト
 */
const 遅延処理 = (ミリ秒: number): Promise<void> => {
  return new Promise(resolve => setTimeout(resolve, ミリ秒));
};

/**
 * ホスト名を取得する関数
 * @returns ホスト名
 */
const ホスト名取得 = (): string => {
  return process.env.HOSTNAME || 'localhost';
};

// Expressアプリケーションの作成
const アプリ = express();

// JSONミドルウェアの設定
アプリ.use(express.json());

// ルートエンドポイント
アプリ.get('/', async (_req: Request, res: Response): Promise<void> => {
  const 開始時間 = Date.now();
  
  // ランダムな遅延を発生させる
  const 遅延時間 = ランダム遅延生成(デフォルト設定.遅延最小値, デフォルト設定.遅延最大値);
  await 遅延処理(遅延時間);
  
  const 処理時間 = Date.now() - 開始時間;
  
  const レスポンスデータ: レスポンス = {
    メッセージ: 'オートスケーリングテスト用Webサーバーです',
    タイムスタンプ: new Date().toISOString(),
    処理時間: 処理時間,
    サーバー情報: {
      ホスト名: ホスト名取得(),
      CPU数: cpus().length
    }
  };
  
  res.json(レスポンスデータ);
});

// 高負荷エンドポイント
アプリ.get('/heavy', async (_req: Request, res: Response): Promise<void> => {
  const 開始時間 = Date.now();
  
  // より長い遅延を発生させる
  const 遅延時間 = ランダム遅延生成(500, 2000);
  await 遅延処理(遅延時間);
  
  // CPUに負荷をかける
  let 計算結果 = 0;
  for (let i = 0; i < 1000000; i++) {
    計算結果 += Math.sqrt(i);
  }
  
  const 処理時間 = Date.now() - 開始時間;
  
  const レスポンスデータ: レスポンス = {
    メッセージ: '高負荷処理を実行しました',
    タイムスタンプ: new Date().toISOString(),
    処理時間: 処理時間,
    サーバー情報: {
      ホスト名: ホスト名取得(),
      CPU数: cpus().length
    }
  };
  
  res.json(レスポンスデータ);
});

// ヘルスチェックエンドポイント
アプリ.get('/health', (_req: Request, res: Response): void => {
  res.status(200).json({ 状態: '正常' });
});

// サーバーの起動
アプリ.listen(デフォルト設定.ポート番号, () => {
  console.log(`サーバーが起動しました: http://localhost:${デフォルト設定.ポート番号}`);
});
