/**
 * テスト用Webサーバー
 * オートスケーリングのテスト対象となるシンプルなWebアプリケーション
 */

import express, { Request, Response } from "express";
import { cpus } from "os";

/**
 * サーバー設定の型定義
 */
type ServerConfig = {
  readonly port: number;
  readonly minDelay: number;
  readonly maxDelay: number;
};

/**
 * レスポンスの型定義
 */
type ServerResponse = {
  readonly message: string;
  readonly timestamp: string;
  readonly processingTime: number;
  readonly serverInfo: {
    readonly hostname: string;
    readonly cpuCount: number;
  };
};

/**
 * サーバー設定のデフォルト値
 */
const DEFAULT_CONFIG: ServerConfig = {
  port: parseInt(process.env.PORT || "3000", 10),
  minDelay: 10,
  maxDelay: 100,
};

/**
 * ランダムな遅延時間を生成する関数
 * @param min - 最小遅延時間（ミリ秒）
 * @param max - 最大遅延時間（ミリ秒）
 * @returns ランダムな遅延時間（ミリ秒）
 */
const generateRandomDelay = (min: number, max: number): number => {
  return Math.floor(Math.random() * (max - min + 1)) + min;
};

/**
 * 指定された時間だけ処理を遅延させる関数
 * @param ms - 遅延時間（ミリ秒）
 * @returns Promiseオブジェクト
 */
const delay = (ms: number): Promise<void> => {
  return new Promise((resolve) => setTimeout(resolve, ms));
};

/**
 * ホスト名を取得する関数
 * @returns ホスト名
 */
const getHostname = (): string => {
  return process.env.HOSTNAME || "localhost";
};

// Expressアプリケーションの作成
const app = express();

// JSONミドルウェアの設定
app.use(express.json());

// ルートエンドポイント
app.get("/", async (_req: Request, res: Response): Promise<void> => {
  const startTime = Date.now();

  // ランダムな遅延を発生させる
  const delayTime = generateRandomDelay(
    DEFAULT_CONFIG.minDelay,
    DEFAULT_CONFIG.maxDelay
  );
  await delay(delayTime);

  const processingTime = Date.now() - startTime;

  const responseData: ServerResponse = {
    message: "オートスケーリングテスト用Webサーバーです",
    timestamp: new Date().toISOString(),
    processingTime: processingTime,
    serverInfo: {
      hostname: getHostname(),
      cpuCount: cpus().length,
    },
  };

  res.json(responseData);
});

// 高負荷エンドポイント
app.get("/heavy", async (_req: Request, res: Response): Promise<void> => {
  const startTime = Date.now();

  // より長い遅延を発生させる
  const delayTime = generateRandomDelay(500, 2000);
  await delay(delayTime);

  // CPUに負荷をかける
  let calculationResult = 0;
  for (let i = 0; i < 1000000; i++) {
    calculationResult += Math.sqrt(i);
  }

  const processingTime = Date.now() - startTime;

  const responseData: ServerResponse = {
    message: "高負荷処理を実行しました",
    timestamp: new Date().toISOString(),
    processingTime: processingTime,
    serverInfo: {
      hostname: getHostname(),
      cpuCount: cpus().length,
    },
  };

  res.json(responseData);
});

// ヘルスチェックエンドポイント
app.get("/health", (_req: Request, res: Response): void => {
  res.status(200).json({ status: "正常" });
});

// サーバーの起動
app.listen(DEFAULT_CONFIG.port, () => {
  console.log(
    `サーバーが起動しました: http://localhost:${DEFAULT_CONFIG.port}`
  );
});
