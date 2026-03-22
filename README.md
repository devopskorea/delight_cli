# Delight CLI (Dooray! Clone)

A command-line interface for Dooray!, written in Perl.

## Features
- `whoami`: Check your connection and member info.
- `project list`: List all accessible projects.
- `post list <project-id>`: List tasks/posts within a specific project.
- `calendar +agenda`: Show today's calendar events.
- `drive +upload <path>`: Upload a file to your private Dooray Drive.

## Installation & Setup

1.  **Dependencies**: Install Perl (on Windows, Strawberry Perl is recommended).
2.  **Configuration**: Create a `config.yml` (or `~/.delight.yml`) with your Dooray API token.
    ```yaml
    domain: https://api.dooray.com
    token: YOUR_TOKEN_HERE
    ```
    To get a token, go to **Private Settings > API > Personal Authentication Token** in Dooray.

## Usage
Primary usage for CMD (using the compiled `delight.exe`):
```cmd
delight.exe whoami
delight.exe project list
delight.exe post list <project-id>
delight.exe calendar +agenda

### Drive Examples

```powershell
# Upload with GWS-style JSON params
delight.exe drive files create --params '{"name": "report.pdf"}' report.pdf

# Upload with simplified name flag
delight.exe drive files create --name "report.pdf" report.pdf

# Target specific locations
delight.exe drive files create --project-id 123 --wiki-id 456 test.txt

# List files
delight.exe drive files list --params '{"pageSize": 5}'
```

### Calendar Examples

```powershell
# View Agenda
delight.exe calendar +agenda --today
delight.exe calendar +agenda --days 3

# Create Events (GWS +insert alias)
delight.exe calendar +insert --summary "Team Sync" --start "2026-03-25T10:00:00+09:00"
delight.exe calendar +insert --summary "Meeting" --location "Room 101"

# Quick Add
delight.exe calendar events quickAdd --text "Dinner at 7pm tomorrow"

# Event Management
delight.exe calendar events list --maxResults 10
delight.exe calendar events get --eventId <EVENT_ID>
delight.exe calendar events delete --eventId <EVENT_ID>

# Availability
delight.exe calendar freebusy query --params '{"timeMin": "2026-03-25T00:00:00Z", "timeMax": "2026-03-25T23:59:59Z"}'
```

## Configuration

Options in `config.yml`:
- `token`: Your Dooray! API token.
- `domain`: Your Dooray! API domain.
- `default_project_id`: Default project ID for drive.
- `default_wiki_id`: Default wiki ID for drive.
- `default_drive_id`: Fixed drive ID.
- `default_calendar_id`: Default calendar ID.

> [!TIP]
> **PowerShell Users**: Use single quotes around JSON blobs to avoid escape hell:
> `delight.exe drive files create --params '{"name": "test.txt"}' test.txt`

## Packaging
To create a standalone executable:
```bash
pp -o delight.exe -I lib bin/delight
```
Requires `PAR::Packer` (install via `cpan PAR::Packer`).
