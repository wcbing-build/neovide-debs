自行打包的 [neovide](https://github.com/neovide/neovide)，适用于 Debian 或基于 Debian 的发行版。

Self-packaged [neovide](https://github.com/neovide/neovide), suitable for Debian and Debian-based distros.


## Usage/用法

### 直接下载 .deb 文件

直接从 [Releases](https://github.com/wcbing-build/neovide-debs/releases) 下载 .deb 文件。

### 添加 apt 仓库

```sh
echo "Types: deb
URIs: https://github.com/wcbing-build/neovide-debs/releases/latest/download/
Suites: ./
Trusted: yes" | sudo tee /etc/apt/sources.list.d/neovide.sources
sudo apt update
sudo apt install neovide
```