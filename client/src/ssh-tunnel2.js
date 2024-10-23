const { Client } = require('ssh2');
const net = require('net');
const socks = require('socksv5');

class SSHDynamicForward {
  constructor(sshConfig, localPort) {
    this.sshConfig = sshConfig;
    this.localPort = localPort;
    this.sshClient = new Client();
    this.activeConnections = new Map();
  }

  async start() {
    // SOCKSサーバーの設定
    const socksServer = socks.createServer((info, accept, deny) => {
      this.handleSocksConnection(info, accept, deny);
    });

    // SSHコネクションの確立
    await new Promise((resolve, reject) => {
      this.sshClient
        .on('ready', () => {
          console.log('SSH connection established');
          resolve();
        })
        .on('error', (err) => {
          console.error('SSH connection error:', err);
          reject(err);
        })
        .connect(this.sshConfig);
    });

    // SOCKSサーバーの起動
    socksServer.listen(this.localPort, 'localhost', () => {
      console.log(`SOCKS server listening on port ${this.localPort}`);
    });

    // エラーハンドリング
    socksServer.on('error', (err) => {
      console.error('SOCKS server error:', err);
    });
  }

  handleSocksConnection(info, accept, deny) {
    // 単一のSSHコネクション上で新しいチャネルを作成
    this.sshClient.forwardOut(
      info.srcAddr,
      info.srcPort,
      info.dstAddr,
      info.dstPort,
      (err, stream) => {
        if (err) {
          console.error('Port forward error:', err);
          return deny();
        }

        const conn = accept(true);
        if (!conn) return;

        // 双方向のデータ転送を設定
        stream.on('error', (err) => {
          console.error('Stream error:', err);
          conn.destroy();
        });

        conn.on('error', (err) => {
          console.error('Connection error:', err);
          stream.destroy();
        });

        // ストリームの接続
        stream.pipe(conn).pipe(stream);

        // 接続を追跡（必要に応じて）
        const connectionId = `${info.srcAddr}:${info.srcPort}-${info.dstAddr}:${info.dstPort}`;
        this.activeConnections.set(connectionId, {
          stream,
          conn,
          timestamp: Date.now()
        });

        // 接続が終了したら追跡から削除
        stream.on('close', () => {
          this.activeConnections.delete(connectionId);
        });
      }
    );
  }

  // クリーンアップ用のメソッド
  cleanup() {
    this.activeConnections.forEach((connection) => {
      connection.stream.destroy();
      connection.conn.destroy();
    });
    this.activeConnections.clear();
    this.sshClient.end();
  }
}

// 使用例
const sshConfig = {
  host: '172.207.80.203',
  port: 22,
  username: 'hp',
  privateKey: Buffer.from('-----BEGIN OPENSSH PRIVATE KEY-----\nb3BlbnNzaC1rZXktdjEAAAAACmFlczI1Ni1jdHIAAAAGYmNyeXB0AAAAGAAAABCZreORME\nWq8QQkgw+tam6fAAAAGAAAAAEAAAAzAAAAC3NzaC1lZDI1NTE5AAAAILnDzDUraB7RNvSn\n8e7ZXjiJeBBMZZvxcCGv6jIU46q+AAAAsIfJ4suKl5pUPNlwVVqaBxhofzVcvnTgPhPUvl\nJOi3xnCppSYoslnhP4rbTUlRRi0CPaS2bCnYvwu2X68fRJ9t/msNzee4em+5jg52IT5WIP\nHguB6QZxbpyVG3Do+EVD3Gix+O2cUEZe1jkyRdQNgs8O+CkZYIzDEDogbLRpgmZXPgn5gA\nBR0TS2gHdJWyWCMrJ3s4UJpOgJfnjIGBRPaxR24ube+EIv4IhiqUq5270L\n-----END OPENSSH PRIVATE KEY-----\n'),
  passphrase: "do-johodaido-johodai",
  
  // privateKey: require('fs').readFileSync('/path/to/private/key')
};

const dynamicForward = new SSHDynamicForward(sshConfig, 1080);

// 起動
dynamicForward.start().catch(err => {
  console.error('Failed to start dynamic forward:', err);
  process.exit(1);
});

// グレースフルシャットダウン
process.on('SIGINT', () => {
  console.log('Shutting down...');
  dynamicForward.cleanup();
  process.exit(0);
});