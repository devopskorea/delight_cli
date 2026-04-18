# 유저 시나리오

각 시나리오는 (1) 사용자 의도, (2) 사전 조건, (3) 단계, (4) 기대 결과 순으로 정리한다.

---

## S-01. 신규 사용자 초기 설정

**의도**: Dooray CLI를 처음 사용하기 위해 기본 설정을 한다.

**사전 조건**: Dooray 웹에서 개인 인증 토큰 발급 완료.

**단계**:
1. `cp config_example.yml config.yml`
2. `config.yml`에 `token`, `default_project_id`, `default_wiki_id`, `default_calendar_id` 입력
3. `delight whoami` 실행 → 본인 이름/이메일 출력 확인
4. `delight project list` → 접근 가능한 프로젝트 ID 확인

**기대 결과**: 인증 성공, 프로젝트 ID 목록 확인.

---

## S-02. 빠른 일정 잡기 (오늘/이번주 보기 → 회의 등록)

**의도**: 오늘 일정을 보고 비어있는 시간에 회의를 잡는다.

**단계**:
1. `delight calendar +agenda --today` → 오늘 일정 확인
2. 빈 시간 발견 → `delight calendar +insert --summary "백엔드 회의" --start "2026-04-18T15:00:00+09:00" --attendee "홍길동" --busy`
3. `delight calendar events list` → 신규 이벤트 ID 확인

**기대 결과**: 이벤트 ID 출력, 본인+초대 멤버가 참석자로 등록.

---

## S-03. 태스크 생성 → 담당 → 단계 → 만기일 설정

**의도**: 신규 작업을 등록하고 담당/단계/마감일을 한 번에 세팅한다.

**단계**:
1. `delight task create --subject "DB 인덱스 추가" --content "users.email"` → `taskId` 확보
2. `delight task assign --task-id <id> --assignee "user@example.com"`
3. `delight task phase --task-id <id> --phase "M001"`
4. `delight task duedate --task-id <id> --tomorrow`
5. `delight task tag --task-id <id> --tag "백엔드" --tag "성능"`

**기대 결과**: 4번의 PUT 호출이 누적되어 동일 태스크에 모든 메타가 반영됨.

**주의**: 각 명령이 독립적으로 PUT 하므로, 중간 호출이 실패해도 이전까지의 변경은 유지됨.

---

## S-04. 태스크 본문을 로컬에서 편집 후 업로드

**의도**: 긴 본문은 에디터로 편집하고 싶다.

**단계**:
1. `delight task download --task-id <id>` → `~/delight/project_<pid>/<id>.md` 생성
2. 위 파일을 에디터에서 편집
3. `delight task upload --task-id <id>` → 동일 파일 자동 탐색 후 PUT

**기대 결과**: 본문이 편집된 내용으로 갱신, 제목은 유지.

---

## S-05. 위키 페이지 트리 백업

**의도**: 특정 위키의 모든 페이지를 로컬로 백업한다.

**단계**:
1. `delight download wiki --wiki-id <wid> --with-attachments`
2. (또는 `--project-id`로 추론 — *현재 미구현 메서드 호출 위험, S-12 참조*)

**기대 결과**:
- `~/delight/wiki_<wid>/<pageId>.md` 파일들
- `~/delight/wiki_<wid>/<pageId>_attachments/*` 첨부
- `~/delight/WIKI_MAP_<wid>.md` 계층 인덱스

**중단 후 재개**: 동일 명령 재실행 시 SDBM 캐시(`wiki_<id>`)로 이미 받은 페이지는 스킵. `--reset-cache`로 강제 재다운로드.

---

## S-06. 드라이브 단방향 동기화

**의도**: 로컬 폴더(`upload_dir`)의 파일을 두레이 드라이브에 항상 최신으로 유지한다.

**단계**:
1. `~/delight_upload/` 에 파일 복사/저장
2. `delight upload drive --project-id <pid>`
3. 파일 수정 후 다시 `delight upload drive --project-id <pid>` → mtime 변화 감지로 재업로드(update_file 호출)

**기대 결과**: 동일 이름 파일이면 update, 새 파일이면 create. 변경 없는 파일은 SDBM 캐시 적중으로 스킵.

**제한**: 하위 폴더 재귀 안 함, 삭제 동기화 안 함(단방향 upsert만).

---

## S-07. 태스크 소프트 삭제 후 복구

**의도**: 잘못 만든 태스크를 휴지통 개념으로 표시했다가 되살린다.

**단계**:
1. `delight task delete --task-id <id>` → 제목에 `#TBD` 접두사 부여 + 로컬 사본 삭제
2. (필요 시) `delight task undelete --task-id <id>` → `#TBD` 제거 + 본문 다시 다운로드

**기대 결과**: Dooray 측 실삭제는 일어나지 않음. 제목만 토글.

---

## S-08. 프로젝트 설정 스냅샷 보관

**의도**: 워크플로/단계/태그/멤버 ID를 한 화면에 모아 본다.

**단계**:
1. `delight project settings --project-id <pid>`

**기대 결과**:
- 콘솔 출력
- `~/delight/project_<pid>/settings.md` 동시 저장 (다음에 ID 찾을 때 grep 가능)

---

## S-09. 캘린더 이벤트에 추가 멤버 초대

**의도**: 이미 만들어둔 회의에 참석자를 추가한다.

**단계**:
1. `delight calendar events invite --eventId <eid> --name "홍길동"`

**기대 결과**: 기존 이벤트의 `users.to` 배열에 멤버가 push되고 PUT으로 반영. 기존 참석자 유지.

---

## S-10. 프로젝트 전체 태스크 일괄 백업 (첨부 포함)

**의도**: 감사용으로 모든 태스크를 첨부까지 받는다.

**단계**:
1. `delight download tasks --with-attachments`
2. (대화형) 프로젝트 번호 선택, 또는 `0` = 전체

**기대 결과**: `project_<pid>/<postId>-<slug>.md` + `*_attachments/*`. 캐시로 인해 다음 실행은 신규 태스크만 처리. 매 항목 후 2~10초 슬립으로 서버 보호.

---

## S-11. 위키 단일 페이지 빠른 백업

**의도**: 큰 트리 전체가 아닌 특정 페이지만 받는다.

**단계**:
1. `delight page download --page-id <pid>` (위키 ID는 페이지 ID로 자동 추론)

**기대 결과**: `wiki_<wid>/<pid>.md` 단일 파일 저장.

---

## S-12. (알려진 결함) project-id로 위키 다운로드 시도

**의도**: 위키 ID 없이 프로젝트 ID만으로 위키를 받으려 한다.

**단계**:
1. `delight download wiki --project-id <pid>`

**현재 동작**: `bin/delight:1221`이 `Delight::Dooray::get_wiki_id_by_project_id`를 호출하지만 해당 메서드가 정의되어 있지 않음 → `Can't locate object method` 에러로 실패.

**해결책 (TODO)**: `Delight::Dooray`에 메서드 추가 (예: `GET /wiki/v1/wikis?projectIds=<pid>` 사용 추정).

---

## S-13. 다른 도메인의 두레이 사용 (엔터프라이즈)

**의도**: `https://api.dooray.com`이 아닌 자체 도메인을 사용한다.

**단계**:
1. `delight config domain https://api.example.dooray.com`
2. 이후 모든 명령은 새 도메인으로 호출. 파일 업로드는 `https://file-api.example.dooray.com`로 자동 치환.

**기대 결과**: 도메인 한 번 설정으로 메인/파일 API 베이스 동시 변경.
