# DPlatform (alpha) - Docker version

[![DP Docker](https://raw.githubusercontent.com/DFabric/DPlatform-DockerShip/gh-pages/img/deploy-docker.png)](https://dfabric.github.io/DPlatform-DockerShip)

### Try [DPlatform-DockerShell](https://github.com/DFabric/DPlatform-ShellCore) - The bare metal version of DPlatform!

[![DP Shell](https://raw.githubusercontent.com/DFabric/DPlatform-ShellCore/gh-pages/img/deploy.png)](https://dfabric.github.io/DPlatform-ShellCore)

### Check out [browser-tools.net](https://browser-tools.net)! In-browser, offline standalone and statically servable web tool set.

![DP logo](https://dfabric.github.io/DPlatform-ShellCore/img/logo.svg)
**DPlatform** helps you to easily install containers and manage them.

#### Install new containers and manage them without efforts
![menu](https://raw.githubusercontent.com/DFabric/DPlatform-DockerShip/gh-pages/img/menu.png)
![setup](https://raw.githubusercontent.com/DFabric/DPlatform-DockerShip/gh-pages/img/setup.png)

*Use of [Simple Shell Menu](https://github.com/j8r/SimpleShellMenu) for the menus*

## Features
- Install docker containers easily
- Manage Container Services - View container status, one click start/stop, auto-start at boot and auto-restart if down unexpectively
- Update/Remove installed container simply with two clicks
- Change your hostname
- Determine your IPv4, IPv6, LocalIP and your hostname

## Available containers
- [Docker](https://www.docker.com/) - Open container engine platform for distributed application
- [Docker compose](https://docs.docker.com/compose/)
- [ui-for-docker](https://github.com/kevana/ui-for-docker) - A pure client-side web interface for the Docker Remote API to connect and manage docker
- [seagull](https://github.com/tobegit3hub/seagull) - Friendly Web UI to manage and monitor docker
- [Rocket.Chat](https://rocket.chat/) - The Ultimate Open Source WebChat Platform
- [Gogs](https://gogs.io/) - Gogs(Go Git Service), a painless self-hosted Git Service
- [Ghost](https://ghost.org/) - Simple and powerful blogging/publishing platform
- [OwnCloud](https://owncloud.org/) - Access & share your files, calendars, contacts, mail & more from any device, on your terms
- [WordPress](https://wordpress.org/) - Web software you can use to create a beautiful website, blog, or app
- [Redmine](https://redmine.org/) - Flexible project management web application

## Installation
To begin with DPlatform Docker, the best way is to clone the repository and run this command to be able to have auto-updates:

` git clone -b master --single-branch https://github.com/DFabric/DPlatform-DockerShip; sh DPlatform-DockerShip/dplatform.sh`

You can also:

[Download the zip](https://github.com/DFabric/DPlatform-DockerShip/archive/master.zip)

`wget https://raw.githubusercontent.com/DFabric/DPlatform-ShellCore/master/dplatform.sh; sudo sh dplatform.sh`

or

`curl -O https://raw.githubusercontent.com/DFabric/DPlatform-ShellCore/master/dplatform.sh; sudo sh dplatform.sh`

## Requirements
Any system/architecure supported by Docker, including GNU/Linux, macOS, Windows.

Development is still active. Most things should work, but problems could occur, more testing is needed.
Please feel free to open an issue and create a pull request, all contributions are welcome!

## License
DPlatform - Deploy self-hosted apps easily

Copyright (c) 2015-2016 Julien Reichardt - [MIT License](http://opensource.org/licenses/MIT) (MIT)
