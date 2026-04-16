# Delight CLI (Dooray! CLI 도구)

Perl로 작성된 Dooray! (두레이) 전용 커맨드 라인 인터페이스(CLI) 도구입니다. 복잡한 웹 UI 대신 터미널에서 빠르고 효율적으로 두레이 기능을 사용할 수 있도록 설계되었습니다.

## 주요 기능

- **계정 확인**: `whoami`를 통한 연결 상태 및 내 정보 확인
- **프로젝트 및 태스크**: 프로젝트 목록 조회, 태스크 생성/삭제/상태변경/담당자지정/태그/만기일 설정
- **캘린더**: 일정 조회, 생성, 수정, 삭제 및 멤버 초대 (GWS 스타일의 `+agenda`, `+insert` 지원)
- **위키 페이지**: 위키 페이지 생성, 수정, 삭제
- **드라이브**: 파일 업로드, 목록 조회 및 로컬 디렉토리와의 **단방향 동기화(One-way Sync)**
- **다운로드**: 태스크, 위키 페이지, 드라이브 파일의 로컬 다운로드 (증분 지원)

## 설치 및 설정

### 설치 방법

**실행 파일(Binary) 사용** (권장): Perl 설치 없이 즉시 실행할 수 있습니다.
- **Linux**: `delight-linux-x64`
- **Windows**: `delight.exe`
- (Linux의 경우 `chmod +x delight-linux-x64`로 실행 권한을 부여해야 할 수 있습니다.)

**Perl 환경 사용**: 바이너리가 없는 경우 Perl로 직접 실행할 수 있습니다.
```bash
perl Makefile.PL INSTALL_BASE=$HOME/.local
make install
```

### 설정

`config.yml` (또는 `~/.delight.yml`) 파일을 생성합니다.

```yaml
domain: https://api.dooray.com
token: YOUR_TOKEN_HERE
default_project_id: "YOUR_PROJECT_ID"
default_wiki_id: "YOUR_WIKI_ID"
default_calendar_id: "YOUR_CALENDAR_ID"
download_dir: /home/user/delight
upload_dir: /home/user/delight_upload
```

*토큰 발급: 두레이 웹 > 개인 설정 > API > 개인 인증 토큰.*

## 명령어 레퍼런스

### 계정 확인

```bash
# 내 계정 정보 확인
delight whoami

# 접근 가능한 모든 프로젝트 목록과 ID 확인
delight project list

# 프로젝트 설정 조회 (상태, 단계, 태그, 멤버)
delight project settings
delight project settings --project-id <pid>
```

### 위키 페이지 관리

```bash
# 위키 페이지 생성
delight page create --subject "페이지 제목" --content "본문 내용"

# 특정 페이지 하위에 생성
delight page create --subject "하위 페이지" --content "내용" --parent-id <pageId>

# 위키 페이지 수정 (--subject 생략 시 기존 제목 유지)
delight page update --page-id <pageId> --content "수정된 내용"
delight page update --page-id <pageId> --subject "새 제목" --content "수정된 내용"

# 위키 페이지 다운로드
delight page download --page-id <pageId>

# 로컬 파일을 위키 페이지로 업로드 (다운로드 디렉토리에서 자동 탐색)
delight page upload --page-id <pageId>

# 외부 파일을 업로드 (업로드 후 다운로드 디렉토리에 자동 복사)
delight page upload --page-id <pageId> --file /path/to/file.md

# 위키 페이지 소프트 삭제 (제목에 #TBD 접두사 추가)
delight page delete --page-id <pageId>

# 위키 페이지 삭제 취소 (#TBD 접두사 제거, 로컬 사본 없으면 다운로드)
delight page undelete --page-id <pageId>
```

> `delight wiki`도 `delight page`의 별칭으로 사용 가능합니다.

### 태스크 관리

```bash
# 태스크 목록 확인 (기본 프로젝트)
delight task list

# 최근 5개만 확인
delight task list --size 5

# 특정 프로젝트의 태스크 목록 확인
delight task list --project-id <pid>

# 표시 항목 선택 (기본: title,status)
delight task list --fields title,assignee,duedate
# 사용 가능: title, status, assignee, priority, duedate, tags, tasknumber

# 태스크 개수 확인
delight task count
delight task count --phase "M000"

# 태스크 생성
delight task create --subject "업무 제목" --content "업무 내용"
delight task create --subject "업무 제목" --project-id <pid>

# 태스크 다운로드
delight task download --task-id <taskId>

# 로컬 파일을 태스크로 업로드
delight task upload --task-id <taskId>
delight task upload --task-id <taskId> --file /path/to/file.md

# 태스크 소프트 삭제 (제목에 #TBD 접두사 추가)
delight task delete --task-id <taskId>
delight task delete --task-id <taskId> --project-id <pid>

# 태스크 삭제 취소 (#TBD 접두사 제거, 로컬 사본 없으면 다운로드)
delight task undelete --task-id <taskId>

# 태스크 상태 변경
delight task status --task-id <taskId> --status "진행"
delight task status --task-id <taskId> --done

# 태스크 담당자 지정 (미입력 시 나를 담당자로 지정)
delight task assign --task-id <taskId>
delight task assign --task-id <taskId> --assignee "홍길동"
delight task assign --task-id <taskId> --assignee "user@example.com"

# 태스크 단계 변경
delight task phase --task-id <taskId> --phase "M000"

# 태스크 만기일 설정
delight task duedate --task-id <taskId> --today
delight task duedate --task-id <taskId> --tomorrow
delight task duedate --task-id <taskId> --date 2026-04-20

# 태스크 태그 지정
delight task tag --task-id <taskId> --tag "태그이름"
delight task tag --task-id <taskId> --tag "태그1" --tag "태그2"
```

> `delight post`도 `delight task`의 별칭으로 사용 가능합니다.

### 캘린더 일정 관리

```bash
# 오늘 일정만 보기
delight calendar +agenda --today

# 주간 일정 확인 (내일 포함 7일)
delight calendar +agenda --week

# 일정 목록 보기 (최근 ±7일)
delight calendar events list

# 일정 상세 정보 보기
delight calendar events get --eventId <eventId>

# 특정 날짜/시간에 일정 생성
delight calendar +insert --summary "기획안 검토 회의" --start "2026-03-26T14:00:00+09:00"

# 바쁨(busy) 상태로 일정 생성 (기본값: 한가함)
delight calendar +insert --summary "중요 회의" --start "2026-04-10T14:00:00+09:00" --busy

# 공개 일정으로 생성 (기본값: 비공개)
delight calendar +insert --summary "공개 일정" --start "2026-04-10T14:00:00+09:00" --public

# 일정 수정 (제목, 시간, 장소를 개별적으로 변경 가능)
delight calendar events update --eventId <eventId> --summary "변경된 제목"
delight calendar events update --eventId <eventId> --start "2026-04-10T14:00:00+09:00" --end "2026-04-10T15:00:00+09:00"
delight calendar events update --eventId <eventId> --location "회의실 B"

# 일정 삭제
delight calendar events delete --eventId <eventId>

# 반복 일정 삭제 (deleteType: this, wholeFromThis, whole)
delight calendar events delete --eventId <eventId> --deleteType this

# 일정 생성 시 동료 초대 (이름 또는 이메일)
delight calendar +insert --summary "회의" --start "2026-03-26T14:00:00+09:00" --attendee "홍길동"
delight calendar +insert --summary "회의" --start "2026-03-26T14:00:00+09:00" --attendee "user@example.com"
delight calendar +insert --summary "회의" --start "2026-03-26T14:00:00+09:00" --attendee "홍길동" --attendee "user@example.com"
```

> `--attendee`는 이름과 이메일 주소를 모두 지원합니다. `@`가 포함되면 이메일로 검색합니다.

### 드라이브 (Drive) 작업

```bash
# 간단한 파일 업로드 (개인 드라이브)
delight drive +upload test.txt

# 특정 프로젝트 드라이브에 이름 지정해서 업로드
delight drive files create --project-id <pid> --upload report.pdf --name "2026_보고서.pdf"

# 드라이브 파일 목록 확인 (최근 5개)
delight drive files list --size 5

# 프로젝트 드라이브 파일 목록 확인
delight drive files list --project-id <pid>
```

### 드라이브 단방향 동기화 (Upload Sync)

`upload_dir`에 있는 파일들을 두레이 드라이브로 동기화합니다. 파일이 변경되었거나 새로 생성된 경우에만 업로드하며, 기존 파일은 새 버전으로 업데이트합니다.

```bash
# 설정파일의 upload_dir 경로 파일을 프로젝트 드라이브로 동기화
delight upload drive --project-id <pid>

# 동기화 캐시를 무시하고 모든 파일 강제 재업로드
delight upload drive --reset-cache
```

### 다운로드 (Download)

```bash
# 위키 페이지 다운로드
delight download wiki --project-id <pid>

# 특정 위키 페이지 1개만 다운로드
delight download wiki --page-id <pageId>

# 태스크 다운로드 (첨부파일 포함)
delight download tasks --project-id <pid> --with-attachments

# 드라이브 파일 다운로드
delight download drive --project-id <pid>

# 캐시를 무시하고 전체 재다운로드
delight download wiki --project-id <pid> --reset-cache
```

### 설정 관리

```bash
# 설정값 변경
delight config <key> <value>
```

## 설정 항목 (config.yml) 상세

| 항목 | 설명 | 기본값 |
| :--- | :--- | :--- |
| `token` | Dooray! API 개인 인증 토큰 (필수) | - |
| `domain` | API 도메인 주소 | `https://api.dooray.com` |
| `default_project_id` | 각종 명령에서 `--project-id` 생략 시 사용 | - |
| `default_wiki_id` | 위키 명령에서 `--wiki-id` 생략 시 사용 | - |
| `default_calendar_id` | 캘린더 명령에서 `--calendarId` 생략 시 사용 | `primary` |
| `download_dir` | `download` 명령 실행 시 파일이 저장될 경로 | `$HOME/delight` |
| `upload_dir` | `upload drive` 명령 실행 시 소스 디렉토리 경로 | `$HOME/delight_upload` |

## 참고 사항

- API 요청 간 지연 시간(Delay)은 `download` 및 `upload` 작업 시 자동으로 랜덤하게(2~10초) 적용되어 서버 부하를 최소화합니다. `--delay 0`으로 비활성화할 수 있습니다.
- 위키 다운로드 시 페이지 계층 구조를 나타내는 `WIKI_MAP_<wiki-id>.md` 인덱스 파일이 자동 생성됩니다.
- 위키 다운로드 파일은 `wiki_<wiki-id>/` 디렉토리에 저장됩니다 (다중 프로젝트 지원).