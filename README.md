# Description

Google Photos backup tool.

I was unable to get any of the current tools out there to work, mainly due to one persistent issue:
- not being able to get headless Chrome to work ([authentication not possible in -headless mode](https://github.com/JakeWharton/docker-gphotos-sync/issues/25))

This solution is focused on using Chrome, but runs it non-headlessly in an X11 environment using [Xvfb](https://en.wikipedia.org/wiki/Xvfb). It's all containerized, so it can be run on a Linux environment without a GUI.

# Steps to take

1. Use Chrome to logon to Google Photos.

```sh
docker compose -f docker-compose-login.yml up
```

Use your browser to go to https://localhost:6901/ or https://server-name:6901/. Log on using:

user: kasm_user 
password: password

Once logged on, start a terminal (click on Applications -> Terminal Emulator). 

Execute the following command:

```sh
google-chrome --user-data-dir=/config https://photos.google.com
```

Logon to Google Photos. Once successfully logged on: close the tab/browser, close the terminal and end the container.

2. Start the downloader.

In the previous step, a directory (config) should've been created which contains your Google Photos session data. 

Change the path to your downloads folder of choice by modifying docker-compose-downloader.yml.

Afterwards, build and start up the container as follows.

```sh
docker compose -f docker-compose-downloader.yml build
docker compose -f docker-compose-downloader.yml up
```

Your backup process should start now.

Tip: it can take a long time for the script to find your initial photo. You can speed up the process by placing a file called `.lastdone` in your downloads directory, containing the full url to the first item in your library (i.e. https://photos.google.com/photo/***********************************).

# Credits

The original idea of using Chrome to drive incremental backups of Google Photos.
- https://github.com/perkeep/gphotos-cdp

Dockerized version of the original tool.
- https://github.com/JakeWharton/docker-gphotos-sync