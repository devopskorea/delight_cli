# Delight CLI (Dooray! CLI 도구)

Perl로 작성된 Dooray! (두레이) 전용 커맨드 라인 인터페이스(CLI) 도구입니다. 복잡한 웹 UI 대신 터미널에서 빠르고 효율적으로 두레이 기능을 사용할 수 있도록 설계되었습니다.

## 🚀 주요 기능
- **계정 확인**: `whoami`를 통한 연결 상태 및 내 정보 확인.
- **프로젝트 및 업무**: 프로젝트 목록 조회 및 프로젝트 내 업무(Task) 리스트 확인.
- **캘린더**: 일정 조회, 생성, 삭제 및 멤버 초대 (GWS 스타일의 `+agenda`, `+insert` 지원).
- **드라이브**: 파일 업로드, 목록 조회 및 로컬 디렉토리와의 **단방향 동기화(One-way Sync)**.
- **백업(Download)**: 업무, 위키, 드라이브 파일의 전체 로컬 백업 (증분 백업 지원).

## 📦 설치 및 설정

1.  **의존성**: Perl이 설치되어 있어야 합니다 (Windows: Strawberry Perl, Linux/macOS: 기본 설치됨).
2.  **설정**: `config.yml` (또는 `~/.delight.yml`) 파일을 생성합니다.
    ```yaml
    domain: https://api.dooray.com
    token: YOUR_TOKEN_HERE
    default_project_id: "3117440634317265196" # 자주 쓰는 프로젝트
    default_calendar_id: "2418519835984710667" # 기본 캘린더
    download_dir: /home/user/delight       # 백업 파일 저장 경로
    upload_dir: /home/user/delight_upload # 동기화 업로드 소스 경로
    ```
    *토큰 발급: 두레이 웹 > 개인 설정 > API > 개인 인증 토큰.*

3.  **설치**:
    ```bash
    perl Makefile.PL INSTALL_BASE=$HOME/.local
    make install
    ```

## 🛠️ 상세 사용 예시

### 1. 프로젝트 및 업무 관리
```bash
# 접근 가능한 모든 프로젝트 목록과 ID 확인
delight project list

# 특정 프로젝트의 업무 목록 확인 (최신순)
delight post list <project-id>

# 내 계정 정보 확인
delight whoami
```

### 2. 드라이브 (Drive) 작업
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

### 3. 드라이브 단방향 동기화 (Upload Sync)
`upload_dir`에 있는 파일들을 두레이 드라이브로 동기화합니다. 파일이 변경되었거나 새로 생성된 경우에만 업로드하며, 기존 파일은 새 버전으로 업데이트합니다.
```bash
# 설정파일의 upload_dir 경로 파일을 프로젝트 드라이브로 동기화
delight upload drive --project-id <pid>

# 동기화 캐시를 무시하고 모든 파일 강제 재업로드
delight upload drive --reset-cache
```

### 4. 캘린더 (Calendar) 일정 관리
```bash
# 오늘 일정만 보기
delight calendar +agenda --today

# 주간 일정 확인 (내일 포함 7일)
delight calendar +agenda --week

# 특정 날짜/시간에 일정 생성
delight calendar +insert --summary "기획안 검토 회의" --start "2026-03-26T14:00:00+09:00"

# 생성된 일정(ID: 123)에 동료 초대하기
delight calendar invite 123 "조철현"

# 일정 상세 정보 보기
delight calendar events get --eventId <eventId>

# 일정 삭제 (취소)
delight calendar events delete --eventId <eventId> --calendarId <calendarId>
```

### 5. 데이터 백업 (Download)
업무, 위키, 드라이브의 방대한 데이터를 로컬로 안전하게 내려받습니다.
```bash
# 프로젝트 위키의 모든 페이지를 마크다운 파일로 백업
# (파일명 형식: {page-id}-{제목슬러그}.md)
delight download wiki --project-id <pid>

# 프로젝트의 모든 업무와 첨부파일까지 백업
delight download tasks --project-id <pid> --with-attachments

# 드라이브의 모든 파일 백업
delight download drive --project-id <pid>
```

## ⚙️ 설정 항목 (config.yml) 상세
| 항목 | 설명 | 기본값 |
| :--- | :--- | :--- |
| `token` | Dooray! API 개인 인증 토큰 (필수) | - |
| `domain` | API 도메인 주소 | https://api.dooray.com |
| `default_project_id` | 각종 명령에서 `--project-id` 생략 시 사용 | - |
| `default_calendar_id` | 캘린더 명령에서 `--calendarId` 생략 시 사용 | primary |
| `download_dir` | `download` 명령 실행 시 파일이 저장될 경로 | $HOME/delight |
| `upload_dir` | `upload drive` 명령 실행 시 소스 디렉토리 경로 | $HOME/delight_upload |

---
**Tip**: API 요청 간 지연 시간(Delay)은 `download` 및 `upload` 작업 시 자동으로 랜덤하게(2~10초) 적용되어 서버 부하를 최소화합니다.
