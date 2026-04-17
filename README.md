# mac-init
Give full disk access for the Terminal first, System Preferences -> Privacy -> Full Disk Access 
```sh
curl -s https://raw.githubusercontent.com/chubbyhippo/mac-init/main/init.sh | /usr/bin/env sh
```
### format sh
```sh
shfmt -l -w .
```
###
```sh
defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys
```
### refs
https://macos-defaults.com/  
https://gist.github.com/bennlee/0f5bc8dc15a53b2cc1c81cd92363bf18
