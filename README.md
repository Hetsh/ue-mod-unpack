# ue-zlib-inflate
Bash script for unpacking .z files from Unreal Engine. It is desigend for unpacking ARK mods.

# Usage
`inflate.sh` decompresses a `.z` file and `modgen.sh` generates the required `<mod_id>.mod` file:
```bash
$ ./inflate.sh workshop/<mod_id>/WindowsNoEditor/file.z
$ ./modgen.sh ARK/ShooterGame/Content/Mods/<mod_id> "<mod_name>"
```
More detailed examples shown in this [Dockerfile](https://github.com/Hetsh/docker-ark-modded/blob/master/Dockerfile).

# Tested
The following mods are tested with my [ARK docker image](https://hub.docker.com/r/hetsh/ark-modded) and confirmed working:
* Structures Plus (Mod-ID: 731604991)
* Bridges (Mod-ID: 558651608)
* Castles, Keeps and Forts: Remastered (Mod-ID: 1814953878)
* Castles, Keeps and Forts: Science Fiction (Mod-ID: 2121156303)
