# WIP ASKA Dedicated Server in Docker optimized for Unraid

This Docker container will download and install SteamCMD and run ASKA Dedicated Server through Wine. It's based on ich777's WineHQ baseimage and optimized for use with Unraid.

## Required Server Setup

Before running the server, you **must** obtain a Steam Game Server Token from:
https://steamcommunity.com/dev/managegameservers

The game ID (App ID) for ASKA is: 1898300

## Environment Variables

| Name | Description | Default Value | Required |
| --- | --- | --- | --- |
| AUTH_TOKEN | Steam Game Server Token | - | Yes |
| SERVER_NAME | Name displayed in server browser | "Default ASKA Server" | No |
| SERVER_PASSWORD | Password to join the server | - | No |
| GAME_PORT | Main game port | 27015 | No |
| QUERY_PORT | Server query port | 27016 | No |
| SERVER_REGION | Server region | "default" | No |
| KEEP_ALIVE | Keep world loaded without players | "false" | No |
| AUTOSAVE_STYLE | Autosave frequency | "every morning" | No |
| GAME_MODE | Game mode setting | "normal" | No |
| VALIDATE | Validate game files on startup | - | No |
| UID | User Identifier | 99 | No |
| GID | Group Identifier | 100 | No |

### Available Server Regions
- default (auto-select best)
- asia
- japan
- europe
- south america
- south korea
- usa east
- usa west
- australia
- canada east
- hong kong
- india
- turkey
- united arab emirates
- usa south central

### Available Autosave Styles
- every morning
- disabled
- every 5 minutes
- every 10 minutes
- every 15 minutes
- every 20 minutes

### Available Game Modes
- normal
- custom (if you set this then there are options inside the server properties.txt you should look at)

## Port Forwarding

The following ports need to be forwarded:
- 27015/udp (Game Port)
- 27016/udp (Query Port)

## Docker Run Example

```bash
docker run --name aska-server -d \
    -p 27015:27015/udp \
    -p 27016:27016/udp \
    --env 'AUTH_TOKEN=your_token_here' \
    --env 'SERVER_NAME=My ASKA Server' \
    --env 'SERVER_PASSWORD=optional_password' \
    --volume /path/to/steamcmd:/serverdata/steamcmd \
    --volume /path/to/serverfiles:/serverdata/serverfiles \
    yeitso/docker-steamcmd-server:aska
```

## Unraid Example

1. Open the Docker tab in your Unraid web interfac    e
2. Click "Add Container"
3. Enter the following basic configuration:
   - Repository: `yeitso/docker-steamcmd-server:aska`
   - Name: aska-server
   - Network Type: Bridge

4. Add the following port mappings:
   - 27015/udp
   - 27016/udp

5. Add the following path mappings:
   - Container Path: /serverdata/steamcmd
   - Host Path: /path/to/your/steamcmd
   - Container Path: /serverdata/serverfiles
   - Host Path: /path/to/your/serverfiles

6. Set your variables:
   - AUTH_TOKEN: Your Steam Game Server Token
   - Other variables as desired

## Save Files

Save files are stored in the `/serverdata/serverfiles/saves/server` directory. Make sure to back up this directory if you want to preserve your world data.

## Logs

The server creates several log files in the `/serverdata/serverfiles/logs` directory:
- server.log: Main server output
- error.log: Error messages
- unity_detailed.log: Detailed Unity engine logs

## Updating

To update the server:
```bash
docker pull yeitso/docker-steamcmd-server:aska
```

Then stop, remove, and recreate the container with the same parameters.

## Troubleshooting

1. If the server fails to start, check:
   - Logs in the `/serverdata/serverfiles/logs` directory
   - Steam Game Server Token validity
   - Port availability and forwarding
   - File permissions in the /serverdata directory

2. For connection issues:
   - Verify ports are properly forwarded
   - Check server region setting
   - Ensure authentication token is valid

## Credits

This Docker is based on work by ich777 and mattieserver. Modified for ASKA server support by JohanLeirnes.

## Support

For issues and feature requests, please use the GitHub repository's issue tracker:
https://github.com/JohanLeirnes/docker-steamcmd-server
