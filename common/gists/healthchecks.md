


## Wget
````bash
test: ["CMD", "wget", "--quiet", "--spider", "http://127.0.0.1/${APP_PORT:?}"]
````
o en https:
````bash
test: ["CMD", "wget", "--quiet", "--spider", "--no-check-certificate", "http://127.0.0.1/${APP_PORT:?}"]
````

## Curl
````bash
test: ["CMD", "curl", "--silent", "--fail", "http://127.0.0.1:${APP_PORT:?}"]
````

## Python
````bash
test: ["CMD", "python3", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:${APP_PORT:?}', timeout=3)"]
````

## Consola
````bash
test: ["CMD", "sh", "-c", "echo > /dev/tcp/127.0.0.1/${APP_PORT:?}"]
````