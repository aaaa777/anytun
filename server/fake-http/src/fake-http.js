const express = require('express');
const net = require('net');
const { Transform } = require('stream');
const bodyParser = require('body-parser');

class SOCKS5HttpServer {
  constructor(options = {}) {
    this.app = express();
    this.port = options.port || 8080;
    this.setupMiddleware();
    this.setupRoutes();
  }

  setupMiddleware() {
    // Raw bodyParserを使用してバイナリデータを処理
    this.app.use(bodyParser.raw({
      type: 'application/octet-stream',
      limit: '1mb'
    }));
  }

  setupRoutes() {
    this.app.post('/proxy', async (req, res) => {
      const targetHost = req.headers['x-target-host'];
      const targetPort = parseInt(req.headers['x-target-port'], 10);

      if (!targetHost || !targetPort) {
        res.status(400).send('Missing target host or port');
        return;
      }

      try {
        const socket = await this.createTargetConnection(targetHost, targetPort);
        this.handleProxyConnection(socket, req, res);
      } catch (err) {
        console.error('Connection error:', err);
        res.status(502).send('Connection failed');
      }
    });
  }

  createTargetConnection(host, port) {
    return new Promise((resolve, reject) => {
      const socket = new net.Socket();

      socket.on('error', (err) => {
        reject(err);
      });

      socket.connect(port, host, () => {
        resolve(socket);
      });
    });
  }

  handleProxyConnection(targetSocket, req, res) {
    // SOCKSレスポンスストリームの作成
    const responseTransform = new Transform({
      transform(chunk, encoding, callback) {
        this.push(chunk);
        callback();
      }
    });

    // エラーハンドリング
    const handleError = (err) => {
      console.error('Proxy error:', err);
      targetSocket.destroy();
      res.status(502).end();
    };

    // ソケットイベントのセットアップ
    targetSocket.on('error', handleError);
    res.on('error', handleError);

    // クライアントからのデータをターゲットに転送
    req.on('data', (chunk) => {
      try {
        targetSocket.write(chunk);
      } catch (err) {
        handleError(err);
      }
    });

    // ターゲットからのレスポンスをクライアントに転送
    targetSocket.on('data', (chunk) => {
      try {
        responseTransform.write(chunk);
      } catch (err) {
        handleError(err);
      }
    });

    // 接続終了処理
    req.on('end', () => {
      targetSocket.end();
    });

    targetSocket.on('end', () => {
      responseTransform.end();
    });

    // レスポンスヘッダーの設定
    res.writeHead(200, {
      'Content-Type': 'application/octet-stream',
      'Connection': 'keep-alive',
      'Transfer-Encoding': 'chunked'
    });

    // レスポンスストリームのパイプ設定
    responseTransform.pipe(res);
  }

  // SOCKS5メッセージのパース用ユーティリティ
  parseSocks5Message(data) {
    if (data.length < 3) return null;

    const version = data[0];
    if (version !== 0x05) return null;

    const cmd = data[1];
    const atyp = data[3];

    let addr, port, offset;

    switch (atyp) {
      case 0x01: // IPv4
        addr = data.slice(4, 8).join('.');
        offset = 8;
        break;
      case 0x03: // Domain name
        const len = data[4];
        addr = data.slice(5, 5 + len).toString();
        offset = 5 + len;
        break;
      case 0x04: // IPv6
        addr = data.slice(4, 20).toString('hex').match(/.{1,4}/g).join(':');
        offset = 20;
        break;
      default:
        return null;
    }

    port = data.readUInt16BE(offset);

    return {
      version,
      cmd,
      atyp,
      addr,
      port
    };
  }

  // SOCKS5レスポンスの生成
  createSocks5Response(success = true) {
    return Buffer.from([
      0x05, // バージョン
      success ? 0x00 : 0x01, // 成功/失敗
      0x00, // 予約済み
      0x01, // アドレスタイプ (IPv4)
      0x00, 0x00, 0x00, 0x00, // バインドアドレス
      0x00, 0x00 // バインドポート
    ]);
  }

  start() {
    return new Promise((resolve) => {
      this.server = this.app.listen(this.port, () => {
        console.log(`SOCKS5 HTTP server listening on port ${this.port}`);
        resolve(this.server);
      });
    });
  }

  stop() {
    if (this.server) {
      return new Promise((resolve) => {
        this.server.close(() => {
          console.log('Server stopped');
          resolve();
        });
      });
    }
    return Promise.resolve();
  }
}

// 使用例
async function main() {
  const server = new SOCKS5HttpServer({
    port: 8080
  });

  try {
    await server.start();

    // グレースフルシャットダウンの設定
    process.on('SIGTERM', async () => {
      console.log('Received SIGTERM. Shutting down...');
      await server.stop();
      process.exit(0);
    });

  } catch (err) {
    console.error('Failed to start server:', err);
    process.exit(1);
  }
}

module.exports = SOCKS5HttpServer;

main()