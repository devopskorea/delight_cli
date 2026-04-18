# API 분석 (Dooray 외부 API 호출 매핑)

`delight_cli`는 자체 API 서버를 제공하지 않는다. 본 문서는 CLI가 호출하는 **Dooray REST API 엔드포인트**와 호출 위치를 정리한다.

API 베이스: `config.yml`의 `domain` (기본 `https://api.dooray.com`).
파일 업로드용 베이스: 위 도메인의 `api.` → `file-api.`로 치환.

## 1. Common / Members

| 메서드 | 경로 | Perl 메서드 | 호출 명령어 |
|---|---|---|---|
| GET | `/common/v1/members/me` | `whoami` | `delight whoami`, 태스크 생성/지정 시 자동 |
| GET | `/common/v1/members?name=<name>` | `search_members` | `task assign`, `calendar +insert --attendee`, `calendar invite` |
| GET | `/common/v1/members?externalEmailAddresses=<email>` | `search_members_by_email` | 위와 동일 (이메일 입력 시) |
| GET | `/common/v1/members/<id>` | `request` 직접 호출 | `project settings` (멤버 이름 조회) |

## 2. Project

| 메서드 | 경로 | Perl 메서드 | 호출 명령어 |
|---|---|---|---|
| GET | `/project/v1/projects` | `list_projects` | `delight project list`, `download tasks` |
| GET | `/project/v1/projects/<pid>/workflows` | `list_workflows` | `project settings`, `task status`, `task count --phase` |
| GET | `/project/v1/projects/<pid>/milestones` | `list_milestones` | `project settings`, `task phase`, `task count --phase` |
| GET | `/project/v1/projects/<pid>/tags` | `list_tags` | `project settings`, `task tag` |
| GET | `/project/v1/projects/<pid>/members` | `list_project_members` | `project settings` |

## 3. Posts (Tasks)

| 메서드 | 경로 | Perl 메서드 | 호출 명령어 |
|---|---|---|---|
| GET | `/project/v1/projects/<pid>/posts` | `list_posts` | (미사용 — `list_posts_paginated`로 대체) |
| GET | `/project/v1/projects/<pid>/posts?page=&size=` | `list_posts_paginated` | `task list`, `download tasks` |
| GET | `/project/v1/projects/<pid>/posts/<postId>` | `get_post_detail` | `task download/upload/delete/undelete`, `download tasks` |
| GET | `/project/v1/posts/<postId>` | `get_post` | `resolve_project_id` (task ID에서 프로젝트 추론) |
| POST | `/project/v1/projects/<pid>/posts` | `create_post` | `task create` |
| PUT | `/project/v1/projects/<pid>/posts/<postId>` | `update_post` | `task tag/duedate/phase/assign/delete/undelete/upload` |
| GET | `/project/v1/projects/<pid>/posts/<postId>/files` | `get_post_files` | `download tasks --with-attachments` |
| POST | `/project/v1/projects/<pid>/posts/<postId>/set-done` | `set_post_done` | `task status --done` |
| POST | `/project/v1/projects/<pid>/posts/<postId>/set-workflow` | `set_post_workflow` | `task status --status <name>` |
| GET | `/project/v1/projects/<pid>/posts/<postId>/files/<fid>?media=raw` | `download_file` | `download tasks --with-attachments` (직접 URL) |

## 4. Calendar

| 메서드 | 경로 | Perl 메서드 | 호출 명령어 |
|---|---|---|---|
| GET | `/calendar/v1/calendars` | `get_default_calendar_id` | 캘린더 명령들에서 `default_calendar_id`가 `primary`/없을 때 |
| POST | `/calendar/v1/calendars/<calId>/events` | `create_event` | `calendar +insert`, `calendar events create` |
| GET | `/calendar/v1/calendars/*/events?timeMin=&timeMax=` | `list_events` | `calendar +agenda`, `calendar events list` |
| GET | `/calendar/v1/calendars/<calId>/events/<eventId>` | `get_event` | `calendar events get/update/invite` |
| POST | `/calendar/v1/calendars/<calId>/events/<eventId>/delete` | `delete_event` | `calendar events delete` |
| PUT | `/calendar/v1/calendars/<calId>/events/<eventId>` | `update_event` | `calendar events update`, `calendar invite` |
| POST | `/calendar/v1/free-busy/query` | `query_freebusy` | `calendar freebusy query --params <json>` |

## 5. Drive

| 메서드 | 경로 | Perl 메서드 | 호출 명령어 |
|---|---|---|---|
| GET | `/drive/v1/drives` | `list_drives` | `download drive` |
| GET | `/drive/v1/drives?type=private` | `get_private_drive_id` | 드라이브 ID 미지정 시 폴백 |
| GET | `/drive/v1/drives?projectIds=<pid>` | `get_drive_id_by_project_id` | `drive` 계열 명령 |
| GET | `/drive/v1/drives?wikiIds=<wid>` | `get_drive_id_by_wiki_id` | `drive` 계열 명령 |
| GET | `/drive/v1/drives/<did>/files?type=folder&subTypes=root` | `get_root_folder_id` | 업로드 시 부모 폴더 자동 결정 |
| GET | `/drive/v1/drives/<did>/files?size=&page=&type=` | `list_files` | `drive files list`, `download drive` |
| GET | `/drive/v1/drives/<did>/files?parentId=&size=100` | `find_file_by_name` | `upload drive` (덮어쓸 파일 검색) |
| POST | (file-api) `/drive/v1/drives/<did>/files?parentId=` | `upload_file` | `drive +upload`, `drive files create`, `upload drive` |
| PUT | (file-api) `/drive/v1/drives/<did>/files/<fid>` | `update_file` | `upload drive` (기존 파일 갱신) |
| GET | `/drive/v1/drives/<did>/files/<fid>?media=raw` | `download_file` | `download drive` (직접 URL) |

## 6. Wiki

| 메서드 | 경로 | Perl 메서드 | 호출 명령어 |
|---|---|---|---|
| GET | `/wiki/v1/wikis` | `list_wikis` | `page create` (parent 결정), `download wiki` |
| POST | `/wiki/v1/wikis/<wid>/pages` | `create_wiki_page` | `page create` |
| PUT | `/wiki/v1/wikis/<wid>/pages/<pid>` | `update_wiki_page` | `page update/upload/delete/undelete` |
| GET | `/wiki/v1/wikis/<wid>/pages?page=&size=&parentPageId=` | `list_wiki_pages_paginated` | `download wiki` |
| GET | `/wiki/v1/wikis/<wid>/pages/<pid>` | `get_wiki_page_detail` | `page update/upload/download/delete/undelete`, `download wiki` |
| GET | `/wiki/v1/pages/<pid>` | `get_wiki_page` | `resolve_wiki_id` (page ID에서 위키 추론) |
| GET | `/wiki/v1/wikis/<wid>/pages/<pid>/files` | `get_wiki_page_files` | `download wiki --with-attachments` |
| GET | `/wiki/v1/wikis/<wid>/pages/<pid>/files/<fid>` | `download_file` | `download wiki --with-attachments` (직접 URL) |

## 7. 인증 헤더

```
Authorization: dooray-api <token>
Accept: application/json
Content-Type: application/json   (요청 body가 있을 때)
```

파일 업로드는 `multipart/form-data`로 전환된다(`Delight::Dooray::_file_upload_request`).

## 8. 알려진 결함

- `Delight::Dooray`에 **`get_wiki_id_by_project_id`와 `list_wiki_pages` 메서드가 정의되어 있지 않음**. 그러나 `bin/delight:50, 1221`과 `samples/check_by_project_id.pl:61, 64`에서 호출됨 → 해당 코드 경로 실행 시 `Can't locate object method` 에러 발생. 미구현/누락 함수.
