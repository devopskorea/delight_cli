# 명령어 ↔ Dooray API ↔ 로컬 파일 관계

자체 DB가 없으므로 "DB 테이블"을 "Dooray 리소스 + 로컬 파일"로 치환한다.
각 CLI 명령이 어떤 Dooray API를 호출하고, 어떤 로컬 파일을 읽거나 쓰는지 표로 정리한다.

## 약어
- `DR-RES`: Dooray API 리소스
- `LOCAL-R/W`: 로컬 파일 읽기/쓰기
- `CACHE`: SDBM 캐시 키

---

## 1. 계정

| 명령 | 호출 API | DR-RES | LOCAL-R | LOCAL-W |
|---|---|---|---|---|
| `whoami` | GET `/common/v1/members/me` | Member(self) | config | — |

## 2. 프로젝트

| 명령 | 호출 API | DR-RES | LOCAL-R | LOCAL-W |
|---|---|---|---|---|
| `project list` | GET `/projects` | Project[] | config | — |
| `project settings [--project-id]` | workflows, milestones, tags, members, members/<id> | Project + 부속 | config | `$download_dir/project_<pid>/settings.md` |

## 3. 태스크 (Posts)

| 명령 | 주요 API 호출 순서 | LOCAL-R | LOCAL-W |
|---|---|---|---|
| `task create` | whoami → POST posts | config | — |
| `task list` | GET posts(paginated) | config | — |
| `task count [--phase]` | (option) milestones → GET posts(size=1) → workflows → GET posts(size=100, workflowIds) | config | — |
| `task tag` | (resolve pid) get_post → list_tags → PUT posts | config | — |
| `task duedate` | (resolve pid) → PUT posts | config | — |
| `task phase` | (resolve pid) → list_milestones → PUT posts | config | — |
| `task status --status` | (resolve pid) → list_workflows → POST set-workflow | config | — |
| `task status --done` | (resolve pid) → POST set-done | config | — |
| `task assign [--assignee]` | (resolve pid) → search_members(_by_email) | whoami | PUT posts | config | — |
| `task delete` | get_post_detail → PUT posts (subject에 `#TBD`) | config | `unlink project_<pid>/<postId>.{md,html}` |
| `task undelete` | get_post_detail → PUT posts (subject `#TBD` 제거) | config | (없으면) `project_<pid>/<postId>.md` 생성 |
| `task download` | get_post_detail | config | `project_<pid>/<postId>.{md|html}` |
| `task upload [--file]` | get_post_detail → PUT posts | `--file` 또는 `project_<pid>/<postId>.md` | (외부 파일 시) canonical 경로 복사 |

`resolve_project_id(task_id)`가 task_id로부터 프로젝트를 자동 추론(`get_post`).

## 4. 위키 페이지

| 명령 | 주요 API 호출 순서 | LOCAL-R | LOCAL-W |
|---|---|---|---|
| `page create` | (resolve wiki) → list_wikis(parent 자동) → POST pages | config | — |
| `page update` | (resolve wiki) → get_wiki_page_detail (subject 보존) → PUT pages | config | — |
| `page upload [--file]` | (resolve wiki) → get_wiki_page_detail → PUT pages | `--file` 또는 `wiki_<wid>/<pid>.md` | (외부 파일 시) canonical 복사 |
| `page download` | (resolve wiki) → get_wiki_page_detail | config | `wiki_<wid>/<pid>.{md|html}` |
| `page delete` | get_wiki_page_detail → PUT pages (`#TBD`) | config | `unlink wiki_<wid>/<pid>.{md,html}` |
| `page undelete` | get_wiki_page_detail → PUT pages (`#TBD` 제거) | config | (없으면) `wiki_<wid>/<pid>.md` 생성 |

`resolve_wiki_id(wiki_id, page_id, project_id)` 우선순위: 인자 → page에서 추론 → `default_wiki_id` → project에서 추론(*미구현 메서드 호출 위험*).

## 5. 캘린더

| 명령 | 주요 API 호출 | 비고 |
|---|---|---|
| `calendar +agenda [--today|--week|--days N]` | list_events(±기간) | 출력만 |
| `calendar events list [-q]` | list_events(±7일) | 출력만 |
| `calendar events get --eventId` | get_event | 출력만 |
| `calendar events update --eventId ...` | get_event → update_event | 머지 후 PUT |
| `calendar events delete --eventId [--deleteType]` | delete_event | POST delete |
| `calendar events invite/+insert --attendee` | search_members(_by_email) → create/update_event | 첨부 멤버 추가 |
| `calendar +insert --summary --start ...` | (whoami) → create_event | end 미지정 시 +1h 자동 |
| `calendar freebusy query --params <json>` | POST free-busy/query | 결과 JSON 출력 |

## 6. 드라이브

| 명령 | 주요 API 호출 | 로컬 |
|---|---|---|
| `drive +upload <path>` | (resolve drive) → upload_file | `<path>` 읽기 |
| `drive files create --upload <path>` | (resolve drive) → upload_file | `<path>` 읽기 |
| `drive files list --size N` | (resolve drive) → list_files | 출력만 |

드라이브 ID 결정 우선순위: `--drive-id` → `--project-id` → `--wiki-id` → `default_drive_id` → `default_project_id` → `default_wiki_id` → 개인 드라이브.

## 7. 일괄 다운로드

| 명령 | API | 캐시 키 | 산출물 |
|---|---|---|---|
| `download tasks [--project-id] [--with-attachments]` | (선택) projects → posts(paginated) → post_detail [→ post_files → download_file] | `task_<postId>` | `project_<pid>/<postId>-<slug>.<md|html>`, `<postId>_attachments/*` |
| `download wiki [--wiki-id|--project-id|--page-id]` | (선택) wikis → wiki_pages(paginated, BFS) → wiki_page_detail [→ files → download_file] | `wiki_<pageId>` | `wiki_<wid>/<pageId>.<md|html>`, `WIKI_MAP_<wid>.md`, `<pageId>_attachments/*` |
| `download drive [--drive-id]` | (선택) drives → list_files(paginated) → download_file | `drive_<fileId>` | `drive/<sanitizedName>_<fileId>` |

모든 다운로드: `--reset-cache`로 캐시 초기화, `--delay <s>` 기본 적용 후 매 파일 처리 후 추가로 2~10s 랜덤 슬립.

## 8. 일괄 업로드

| 명령 | API | 캐시 키 | 입력 |
|---|---|---|---|
| `upload drive [--project-id|--wiki-id|--drive-id] [--parent-id]` | find_file_by_name → (있으면) update_file / (없으면) upload_file | `<filename>_<size>_<mtime>` | `$upload_dir/*` 평면 디렉토리 (재귀 안 함) |

## 9. 설정

| 명령 | 효과 |
|---|---|
| `config <key> <value>` | YAML 로드 → set → save |

## 10. 데이터 흐름 다이어그램 (download tasks 예)

```
delight download tasks --project-id P --with-attachments
   │
   ├─[GET]─► /project/v1/projects                       (전체 프로젝트, --project-id 없을 때)
   ├─[GET]─► /project/v1/projects/P/posts?page=N&size=100
   │           │
   │           └─ for each post:
   │              ├─ if cache.task_<id> exists → skip
   │              ├─[GET]─► /project/v1/projects/P/posts/<id>
   │              ├─ write project_P/<id>-<slug>.md
   │              ├─[GET]─► /project/v1/projects/P/posts/<id>/files (--with-attachments)
   │              │   └─[GET]─► /.../files/<fid>?media=raw → project_P/<id>_attachments/<name>
   │              ├─ sleep rand(2..10)
   │              └─ cache.task_<id> = 1
```

## 11. 명령 ↔ 로컬 파일 영향 범위 요약

| 영역 | 생성 | 수정 | 삭제 |
|---|---|---|---|
| `config.yml` | `config` | `config` | (없음) |
| `project_<pid>/settings.md` | `project settings` | `project settings` | (없음) |
| `project_<pid>/<postId>.md` | `task download/undelete`, `download tasks` | `task upload`, `download tasks --reset-cache` | `task delete` |
| `wiki_<wid>/<pageId>.md` | `page download/undelete`, `download wiki` | `page upload`, `download wiki --reset-cache` | `page delete` |
| `WIKI_MAP_<wid>.md` | `download wiki` | `download wiki` | (없음) |
| `drive/...` | `download drive` | `download drive --reset-cache` | (없음) |
| `.delight_*_cache.sdbm` | 모든 download/upload 명령 | 동일 | `--reset-cache`로 unlink |
