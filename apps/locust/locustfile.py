"""
テスト対象WebサーバーへのLocust負荷テストファイル
"""

from locust import HttpUser, task, between


class Webサーバーユーザー(HttpUser):
    """
    テスト対象のWebサーバーにリクエストを送信するユーザークラス
    """

    # リクエスト間の待機時間（1〜5秒）
    wait_time = between(1, 5)

    @task(3)
    def 通常リクエスト(self):
        """
        通常のエンドポイントへのリクエスト（高頻度）
        """
        with self.client.get(
            "/", name="通常リクエスト", catch_response=True
        ) as response:
            if response.status_code != 200:
                response.failure(
                    f"通常リクエストが失敗しました: {response.status_code}"
                )
            else:
                response.success()

    @task(1)
    def 高負荷リクエスト(self):
        """
        高負荷エンドポイントへのリクエスト（低頻度）
        """
        with self.client.get(
            "/heavy", name="高負荷リクエスト", catch_response=True
        ) as response:
            if response.status_code != 200:
                response.failure(
                    f"高負荷リクエストが失敗しました: {response.status_code}"
                )
            else:
                response.success()

    @task(5)
    def ヘルスチェック(self):
        """
        ヘルスチェックエンドポイントへのリクエスト（最高頻度）
        """
        with self.client.get(
            "/health", name="ヘルスチェック", catch_response=True
        ) as response:
            if response.status_code != 200:
                response.failure(
                    f"ヘルスチェックが失敗しました: {response.status_code}"
                )
            else:
                response.success()
