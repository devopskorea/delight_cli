# 기능 개발 현황

## 1. 구현 완료

### 1.1 계정/프로젝트
- [x] 본인 정보 조회 (`whoami`)
- [x] 프로젝트 목록 (`project list`)
- [x] 프로젝트 설정(워크플로/단계/태그/멤버) 조회 + 파일 저장 (`project settings`)

### 1.2 태스크 (`task` / `post` 별칭)
- [x] 태스크 생성 (`create`)
- [x] 태스크 목록 (`list`, 필드 선택 지원)
- [x] 태스크 카운트 (`count`, `--phase`로 단계별 워크플로 분포)
- [x] 태그 부여 (`tag`)
- [x] 만기일 설정 (`duedate`, `--today/--tomorrow/--date`)
- [x] 단계 변경 (`phase`)
- [x] 워크플로 변경 (`status --status` / `--done`)
- [x] 담당자 지정 (`assign`, 이름/이메일 모두 지원)
- [x] 소프트 삭제/복구 (`delete` / `undelete`)
- [x] 본문 다운로드 (`download`)
- [x] 본문 업로드 (`upload`, 외부 파일 시 canonical 경로 동기 복사)

### 1.3 위키 (`page` / `wiki` 별칭)
- [x] 페이지 생성 (`create`, `--parent-id`)
- [x] 페이지 수정 (`update`, 제목 보존 옵션)
- [x] 페이지 다운로드 (`download`)
- [x] 페이지 업로드 (`upload`)
- [x] 소프트 삭제/복구 (`delete` / `undelete`)

### 1.4 캘린더
- [x] 오늘/주간/N일 일정 (`+agenda --today/--week/--days N`)
- [x] 이벤트 목록 (`events list`, `-q`)
- [x] 이벤트 상세 (`events get`)
- [x] 이벤트 생성 (`+insert`, `events create`, `--busy`, `--public`)
- [x] 이벤트 수정 (`events update` — subject/start/end/location 부분 갱신)
- [x] 이벤트 삭제 (`events delete`, 반복 일정 `--deleteType`)
- [x] 멤버 초대 (`+insert --attendee`, `events invite`)
- [x] Free/Busy 쿼리 (`freebusy query --params <json>`)

### 1.5 드라이브
- [x] 단건 업로드 (`+upload`, `files create`)
- [x] 파일 목록 (`files list`)
- [x] 드라이브 ID 자동 결정 (project/wiki/private 폴백 체인)

### 1.6 일괄 처리
- [x] 태스크 일괄 다운로드 (`download tasks`, 첨부 옵션, 대화형 프로젝트 선택)
- [x] 위키 일괄 다운로드 (`download wiki`, BFS 트리 순회, `WIKI_MAP` 생성, 첨부)
- [x] 드라이브 일괄 다운로드 (`download drive`)
- [x] 드라이브 단방향 업로드 동기화 (`upload drive`, mtime+size 캐시)
- [x] SDBM 캐시 + 랜덤 슬립 기반 재시작 가능한 다운로드

### 1.7 인프라
- [x] YAML 설정 (CWD `config.yml` 우선, fallback `~/.delight.yml`)
- [x] `dooray-api` 토큰 인증 자동 헤더
- [x] 더블 UTF-8 디코딩 보정 (한국어 응답)
- [x] `api.` ↔ `file-api.` 도메인 자동 치환

## 2. 미구현 / 결함 / 정리 필요

| ID | 항목 | 상태 | 근거 |
|---|---|---|---|
| G-01 | `Delight::Dooray::get_wiki_id_by_project_id` | **미구현** (호출만 존재) | `bin/delight:50, 1221`, `samples/check_by_project_id.pl:61` |
| G-02 | `Delight::Dooray::list_wiki_pages` | **미구현** (호출만 존재) | `samples/check_by_project_id.pl:64` |
| G-03 | `Delight::Auth.pm` (Google OAuth2) | **미사용 데드코드** | `bin/delight`에서 import 안 함, `cpanfile`에 의존성 누락(`LWP::Authen::OAuth2`, `Config::Tiny`, `JSON::MaybeXS`) |
| G-04 | `Delight::Drive.pm` (Google Drive v3) | **미사용 데드코드** | 동일 |
| G-05 | `download_dir`/`upload_dir` 디폴트 | 부분 구현 | `download_dir`은 `$HOME/delight`, `upload_dir`은 `$HOME/delight_upload`로 폴백되나 README의 표 기재와 일치 — 단 `config_example.yml`에는 두 키가 없음 |
| G-06 | `task assign` `--assignee` 다중 시 첫 검색 결과만 사용 | 동작 한계 | `bin/delight:919` (`$members->[0]`) |
| G-07 | `calendar +insert --params` 파서 | 부분 구현 | `dateTime` 패턴만 인식, `endedAt` 미처리 |
| G-08 | `upload drive` 디렉토리 재귀 / 삭제 동기화 | 미구현 | 평면 디렉토리 + upsert 만 |
| G-09 | `delight wiki` 별칭에서 `delete` 외 일부 흐름은 `page`와 동일 코드 사용하지만 별칭 일관성 테스트 없음 | 잠재 위험 | — |
| G-10 | 자동 테스트 (`t/`) | 0% | `t/` 디렉토리 부재, `samples/*.pl`은 단언 없는 스크립트 |
| G-11 | CI/CD (GitHub Actions 등) | 없음 | 레포에 `.github/workflows/` 부재 |
| G-12 | 바이너리 빌드 스크립트 | 미공개 | `delight-linux-x64`, `delight.exe`만 커밋, 빌드 절차 문서/스크립트 없음 |
| G-13 | `delight task tag` 사용하지 않는 변수 `$tag_prefix` | 코드 정리 | `bin/delight:813` (할당 후 사용 안 함) |
| G-14 | `delight calendar +insert --params` JSON 정식 파서 | 정규식 기반 부분 파싱 | 신뢰성 낮음 |
| G-15 | 토큰 회전/만료 알림 | 없음 | 401 시 일반 API 에러로만 노출 |
| G-16 | 다국어 응답 외 더블 인코딩 안전성 | 휴리스틱 | `[\xC2-\xF4][\x80-\xBF]` 패턴 매칭, 우연히 일치하는 라틴 문자열 오변환 위험 |

## 3. 우선순위 제안

| 우선 | 작업 |
|---|---|
| P0 | G-01 `get_wiki_id_by_project_id` 구현 (download wiki --project-id 정상화) |
| P0 | G-03/G-04 미사용 모듈 제거 또는 cpanfile에 의존성 추가하여 살리기 결정 |
| P1 | G-02 `list_wiki_pages` 구현 또는 sample 스크립트 갱신 |
| P1 | G-10 최소 단위 테스트(`_fix_double_utf8`, `_format_task`) |
| P2 | G-13 사용 안 함 변수 정리, G-07/G-14 옵션 파서 정비 |
| P2 | G-12 빌드 스크립트 공개 + CI 추가(G-11) |
