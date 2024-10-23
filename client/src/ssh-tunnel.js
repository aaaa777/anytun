const socks = require('socksv5');
const { Client } = require('ssh2');
const http = require('http');
const fs = require('fs');
const net = require('net');

const sshConfig = {
  host: '172.207.80.203',
  port: 22,
  username: 'hp',
  // privateKey: fs.readFileSync('./.ssh/id_ed25519'),
  privateKey: Buffer.from('-----BEGIN OPENSSH PRIVATE KEY-----\nb3BlbnNzaC1rZXktdjEAAAAACmFlczI1Ni1jdHIAAAAGYmNyeXB0AAAAGAAAABCZreORME\nWq8QQkgw+tam6fAAAAGAAAAAEAAAAzAAAAC3NzaC1lZDI1NTE5AAAAILnDzDUraB7RNvSn\n8e7ZXjiJeBBMZZvxcCGv6jIU46q+AAAAsIfJ4suKl5pUPNlwVVqaBxhofzVcvnTgPhPUvl\nJOi3xnCppSYoslnhP4rbTUlRRi0CPaS2bCnYvwu2X68fRJ9t/msNzee4em+5jg52IT5WIP\nHguB6QZxbpyVG3Do+EVD3Gix+O2cUEZe1jkyRdQNgs8O+CkZYIzDEDogbLRpgmZXPgn5gA\nBR0TS2gHdJWyWCMrJ3s4UJpOgJfnjIGBRPaxR24ube+EIv4IhiqUq5270L\n-----END OPENSSH PRIVATE KEY-----\n'),
  passphrase: "do-johodaido-johodai",
};


socks.createServer((info, accept, deny) => {
  // NOTE: you could just use one ssh2 client connection for all forwards, but
  // you could run into server-imposed limits if you have too many forwards open
  // at any given time
  const conn = new Client();
  conn.on('ready', () => {
    conn.forwardOut(info.srcAddr,
                    info.srcPort,
                    info.dstAddr,
                    info.dstPort,
                    (err, stream) => {
      if (err) {
        conn.end();
        return deny();
      }

      const clientSocket = accept(true)
      if (clientSocket) {
        clientSocket.on('error', () => {
          conn.end();
        });
        stream.pipe(clientSocket).pipe(stream).on('close', () => {
          // https://stackoverflow.com/questions/50993979/node-js-error-read-econnreset-using-ssh2
          setTimeout(function() {
            conn.end();
          },100);
          // conn.end();
        });
      } else {
        conn.end();
      }
    });
  }).on('error', (err) => {
    console.error('[socksv5 server]Unhandle error: ' + err.toString());
    deny();
  }).connect(sshConfig);
}).listen(1080, 'localhost', () => {
  console.log('SOCKSv5 proxy server started on port 1080');
}).useAuth(
  socks.auth.None()
)

// pacファイル配信用サーバ
http.createServer(async (req, res) => {
  // 設定ファイルの場所
  if(req.url === "/proxy.pac") {
    res.writeHead(200, {
      'Content-Type': 'application/x-ns-proxy-autoconfig',
      "Content-Disposition": "attachment;filename=\"abe.pac\""
    });
    res.end(`
      function FindProxyForURL(url, host)
        {
          if (dnsDomainIs(host, "` + proxyTargetDomain + `")){
            return "PROXY localhost:3003";
          } else {
            return "DIRECT";
          }
        }
    `);
    return;
  }
  res.writeHead(404, {});
  res.end('file not found');
}).listen(3002);

// test with cURL:
//   curl -i --socks5 localhost:1080 google.com