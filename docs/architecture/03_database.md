# 데이터베이스

## 결론: **자체 DB 없음 (N/A)**

`delight_cli`는 RDBMS, NoSQL, ORM, 마이그레이션 시스템을 사용하지 않는다.
모든 비즈니스 데이터(프로젝트, 태스크, 위키, 캘린더 이벤트, 드라이브 파일)는 **Dooray SaaS 측 DB**에 존재하고, CLI는 REST API로만 접근한다.

## 로컬 영속 저장소

| 종류 | 파일 | 형식 | 위치 | 용도 |
|---|---|---|---|---|
| 사용자 설정 | `config.yml` 또는 `~/.delight.yml` | YAML | CWD 우선, 없으면 홈 | 토큰, 도메인, 기본 ID, 디렉토리 경로 |
| 다운로드 캐시 | `.delight_download_cache.sdbm.{dir,pag}` | SDBM | 명령 실행 CWD | 다운로드 완료된 task/wiki/drive 항목 식별자 |
| 업로드 캐시 | `.delight_upload_cache.sdbm.{dir,pag}` | SDBM | 명령 실행 CWD | 업로드 완료된 파일의 `name_size_mtime` 키 |
| 다운로드 결과 | `$download_dir/...` | 일반 파일 | 사용자 지정 | 위키/태스크 본문(.md/.html), 첨부, 드라이브 파일 |

## SDBM 캐시 키 스키마

### 다운로드 캐시 (`.delight_download_cache.sdbm`)

```
key                       value   의미
task_<postId>             "1"     해당 태스크 본문 다운로드 완료
wiki_<pageId>             "1"     해당 위키 페이지 본문 다운로드 완료
drive_<fileId>            "1"     해당 드라이브 파일 다운로드 완료
```

> 첨부파일에 대한 별도 캐시 키는 없다. 부모(task/wiki) 캐시가 존재하면 첨부도 다시 다운로드되지 않는다.

### 업로드 캐시 (`.delight_upload_cache.sdbm`)

```
key                                 value           의미
<filename>_<size>_<mtime>           "<dooray_id>"   해당 mtime/size 시점에 업로드한 결과 파일 ID
```

mtime 또는 size가 바뀌면 키 자체가 달라져 자연스럽게 재업로드 트리거.

## Dooray 측 데이터 모델 (호출 관점)

CLI가 다루는 Dooray의 주요 리소스 (실제 스키마는 Dooray API 문서 참조):

| 리소스 | 식별자 변수 | 주요 엔드포인트 베이스 |
|---|---|---|
| Member | `organizationMemberId` | `/common/v1/members` |
| Project | `projectId` | `/project/v1/projects/{projectId}` |
| Workflow (status) | `workflowId` | `/project/v1/projects/{pid}/workflows` |
| Milestone (phase) | `milestoneId` | `/project/v1/projects/{pid}/milestones` |
| Tag | `tagId` | `/project/v1/projects/{pid}/tags` |
| Post (task) | `postId` | `/project/v1/projects/{pid}/posts/{postId}` |
| Wiki | `wikiId` | `/wiki/v1/wikis/{wikiId}` |
| Wiki Page | `pageId` | `/wiki/v1/wikis/{wikiId}/pages/{pageId}` |
| Calendar | `calendarId` | `/calendar/v1/calendars/{calendarId}` |
| Calendar Event | `eventId` | `/calendar/v1/calendars/{calendarId}/events/{eventId}` |
| Drive | `driveId` | `/drive/v1/drives/{driveId}` |
| Drive File | `fileId` | `/drive/v1/drives/{driveId}/files/{fileId}` |

## 마이그레이션 / 스키마 변경 전략

해당 사항 없음. Dooray 측 API 변경은 외부 변경이며, `Delight::Dooray.pm`에서 엔드포인트 시그니처를 추적·수정한다.
