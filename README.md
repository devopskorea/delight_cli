# Delight CLI

Dooray를 이용하기 위한 CLI입니다.
Google Workspace(GWS) CLI와 비슷합니다.

## 제공과 제작

* "사회적협동조합 데브옵스 코리아"는 커뮤니티 "데브옵스 코리아"를 지원합니다.
* "사회적협동조합 데브옵스 코리아"의 운영자들의 원활한 업무를 위해 "주식회사 시스템파이브"가 Delight CLI를 제작합니다.
* "사회적협동조합 데브옵스 코리아"가 Delight CLI를 대중에게 제공합니다.

## 주요 기능
- `whoami`: Check your connection and member info.
- `project list`: List all accessible projects.
- `post list <project-id>`: List tasks/posts within a specific project.
- `calendar +agenda`: Show today's calendar events.
- `drive +upload <path>`: Upload a file to your private Dooray Drive.
- GWS CLI가 제공하는 기능을 최대한 유사하게 제공하고자 합니다.
- openclaw가 Delight CLI를 이용할 것을 고려하고 있습니다.

## 설치

* 유닉스, 리눅스, macOS에서 `Perl -I lib bin/delight`로 실행할 수 있습니다.
  * `bin/delight`로도 실행할 수 있습니다. 
* Microsoft Windows에서 delight.exe를 이용하세요.
* 현재 디렉토리에 config.yml을 두거나 ~/.delight.yml 파일을 두세요.

## 이용 예

### 👤 Identity & Basic Info
```powershell
# Check who you are (name and email)
delight.exe whoami
```

---

### 📂 Google Drive / Dooray! Files
The [drive](cci:1://file:///c:/Users/ella/Documents/delight_cli/lib/Delight/Dooray.pm:100:0-107:1) command supports both simplified flags and GWS-style JSON parameters.

#### **Creating/Uploading Files**
```powershell
# 1. Simple upload with automatic name extraction
delight.exe drive files create report.pdf

# 2. Upload with a specific remote name
delight.exe drive files create --name "Final_Report.pdf" report.pdf

# 3. GWS-style upload using JSON params
delight.exe drive files create --params '{"name": "test.txt"}' test.txt

# 4. Upload to a specific location (Project, Wiki, or fixed Drive ID)
delight.exe drive files create --project-id 123456789 test.txt
delight.exe drive files create --wiki-id 987654321 test.txt
delight.exe drive files create --drive-id 1122334455 test.txt
```

#### **Listing Files**
```powershell
# 1. List recently uploaded files (default size 10)
delight.exe drive files list

# 2. List with specific result size
delight.exe drive files list --size 5

# 3. GWS-style listing with pageSize
delight.exe drive files list --params '{"pageSize": 5}'

# 4. List files from a specific project
delight.exe drive files list --project-id 123456789
```

---

### 📅 Calendar Management
Extensive support for GWS-style aliases and sophisticated parameters.

#### **Viewing Agenda**
```powershell
# 1. Today's agenda
delight.exe calendar +agenda --today

# 2. This week's agenda
delight.exe calendar +agenda --week

# 3. Custom range (e.g., next 3 days)
delight.exe calendar +agenda --days 3

# 4. Specific timezone
delight.exe calendar +agenda --timezone "America/New_York"
```

#### **Creating Events**
```powershell
# 1. Quick create with summary and start time
delight.exe calendar +insert --summary "Team Sync" --start "2026-03-25T10:00:00+09:00"

# 2. Create with duration (defaults to 1 hour if --end is omitted)
delight.exe calendar +insert --summary "Deep Work" --start "2026-03-22T09:00:00+09:00"

# 3. Create with attendee and location
delight.exe calendar +insert --summary "lunch" --location "Subway" --attendee "ella@example.com"

# 4. Natural Language expression (Quick Add)
delight.exe calendar events quickAdd --text "Dinner at 7pm tomorrow at Italian Restaurant"
```

#### **Event Lifecycle**
```powershell
# 1. List events (default searches ±7 days)
delight.exe calendar events list --maxResults 10

# 2. Search events by keyword
delight.exe calendar events list --q "Project"

# 3. Get full details of a specific event
delight.exe calendar events get --eventId <EVENT_ID>

# 4. Delete an event
delight.exe calendar events delete --eventId <EVENT_ID>
```

#### **Availability**
```powershell
# 1. Free/Busy query (requires JSON params)
delight.exe calendar freebusy query --params '{"timeMin": "2026-03-25T00:00:00Z", "timeMax": "2026-03-25T23:59:59Z"}'
```

---

### 🏗️ Project & Wiki Discovery

```powershell
# List all accessible projects and their IDs
delight.exe project list

# List all accessible wikis and their IDs
delight.exe wiki list
```

> [!TIP]
> **PowerShell Tip**: Always use **single quotes** (`'`) for the entire JSON blob to avoid PowerShell's quote-escaping issues:
> `delight.exe drive files create --params '{"name": "test.txt"}' test.txt`

## Configuration

Options in `config.yml`:
- `token`: Your Dooray! API token.
- `domain`: Your Dooray! API domain.  https://api.dooray.com or https://api.gov-dooray.com or https://api.dooray.co.kr
- `default_project_id`: Default project ID for drive.
- `default_wiki_id`: Default wiki ID for drive.
- `default_drive_id`: Fixed drive ID.
- `default_calendar_id`: Default calendar ID.
